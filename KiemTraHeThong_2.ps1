# KiemTraHeThong.ps1 - Ban nang cao, khong dau, chi in ra man hinh
# Cap nhat: Bo sung kiem tra Card Wifi, tinh toan va in ra CPU Max sau moi test.

# Thong tin he thong
Write-Host "===== THONG TIN HE DIEU HANH =====" -ForegroundColor Cyan
Get-ComputerInfo | Select-Object CsName, OsName, WindowsVersion, OsArchitecture, BiosVersion, CsManufacturer, CsModel | Format-List

# CPU
Write-Host "`n===== THONG TIN CPU =====" -ForegroundColor Cyan
Get-WmiObject Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed | Format-List

# RAM
Write-Host "`n===== THONG TIN RAM =====" -ForegroundColor Cyan
Get-WmiObject Win32_PhysicalMemory | ForEach-Object {
    "Dung luong: {0} GB - Toc do: {1} MHz - Hang: {2}" -f ([math]::Round($_.Capacity/1GB,1)), $_.Speed, $_.Manufacturer
}

# O dia
Write-Host "`n===== THONG TIN O DIA =====" -ForegroundColor Cyan
Get-PhysicalDisk | Select-Object FriendlyName, MediaType, Size, SerialNumber | Format-Table -AutoSize

# ===== HAM LAY NHIET DO CPU (neu duoc ho tro) =====
# Luu y: Chuc nang nay cung phu thuoc vao WMI va driver sensor, co the khong hoat dong tren moi he thong.
Function Get-CPUTemp {
    try {
        $temp = Get-WmiObject MSAcpi_ThermalZoneTemperature -Namespace "root/wmi"
        if ($temp -ne $null) {
            # Chuyen doi tu Kelvin x 10 sang Celsius
            ($temp.CurrentTemperature - 2732) / 10
        } else {
            $null
        }
    } catch {
        # Neu co loi khi truy cap WMI, tra ve null
        $null
    }
}

$temp1 = Get-CPUTemp
if ($temp1 -ne $null) {
    Write-Host "Nhiet do CPU truoc test: $temp1°C" -ForegroundColor Yellow
} else {
    Write-Host "Khong the lay nhiet do CPU truoc test (co the khong ho tro WMI hoac sensor driver)" -ForegroundColor Yellow
}

# ===== KIEM TRA THIET BI MANG (WIFI, ETHERNET) ====="
Write-Host "`n===== KIEM TRA THIET BI MANG =====" -ForegroundColor Cyan
Get-NetAdapter | Select-Object Name, InterfaceDescription, Status, LinkSpeed, MacAddress | Format-Table -AutoSize

# Kiểm tra Card Wifi cụ thể
$wifiAdapter = Get-NetAdapter -Name *Wi-Fi* -ErrorAction SilentlyContinue # Hoặc *Wireless*
if ($wifiAdapter) {
    Write-Host "`n-- Thong tin chi tiet Card Wi-Fi: --" -ForegroundColor Green
    $wifiAdapter | Select-Object Name, InterfaceDescription, Status, LinkSpeed, MacAddress, DriverVersion, NdisVersion | Format-List
} else {
    Write-Host "`n-- Khong phat hien Card Wi-Fi hoat dong --" -ForegroundColor Red
}


# ===== KIEM TRA BLUETOOTH VA CARD ROI (Cuc bo) =====
Write-Host "`n===== KIEM TRA THIET BI BLUETOOTH VA CARD DO HOA ROI =====" -ForegroundColor Cyan
Write-Host "Luu y: Cac thiet bi nay co the hien thi la 'Unknown Device' hoac 'Microsoft Basic Display Adapter'"
Write-Host "neu driver chua duoc cai dat day du." -ForegroundColor DarkYellow

$bluetoothDevices = Get-WmiObject Win32_PnPEntity | Where-Object {$_.Caption -like "*Bluetooth*" -or $_.Name -like "*Bluetooth*"}
if ($bluetoothDevices) {
    Write-Host "`n-- Thiet bi Bluetooth duoc phat hien: --" -ForegroundColor Green
    $bluetoothDevices | Select-Object Name, DeviceID, Manufacturer, Status | Format-List
} else {
    Write-Host "`n-- Khong phat hien thiet bi Bluetooth --" -ForegroundColor Red
}

$gpuDevices = Get-WmiObject Win32_PnPEntity | Where-Object {$_.Caption -like "*graphics*" -or $_.Caption -like "*display*" -and $_.PNPDeviceID -notlike "*VID_8086*"} # Loai tru Intel Integrated Graphics (VID_8086)
if ($gpuDevices) {
    Write-Host "`n-- Card do hoa roi duoc phat hien: --" -ForegroundColor Green
    $gpuDevices | Select-Object Name, DeviceID, Manufacturer, Status | Format-List
} else {
    Write-Host "`n-- Khong phat hien card do hoa roi --" -ForegroundColor Red
    Write-Host "Luu y: Intel Integrated Graphics (card onboard) van co the hien thi." -ForegroundColor DarkYellow
}


# ===== STRESS TEST CPU NHE (30 GIAY - SINGLE CORE) =====
Write-Host "`n===== STRESS TEST CPU NHE (30 GIAY, 1 LUONG) =====" -ForegroundColor Yellow
Write-Host "VUI LONG MO TASK MANAGER (Ctrl+Shift+Esc) VA CHUYEN SANG TAB HIEN THI HIEU SUAT (Performance)" -ForegroundColor White -BackgroundColor DarkRed
Write-Host "DE THEO DOI MUC DO SU DUNG CPU TRONG QUA TRINH TEST." -ForegroundColor White -BackgroundColor DarkRed

$cpuMaxLight = 0 # Bien luu tru gia tri CPU Max cho test nhe
$endTimeLight = (Get-Date).AddSeconds(30)
$lightTestProgress = 0

Write-Progress -Activity "Dang chay Stress Test CPU Nhe" -Status "Dang khoi tao..." -PercentComplete 0

while ((Get-Date) -lt $endTimeLight) {
    # Thuc hien cac phep tinh don gian
    $x = Get-Random -Minimum 1000 -Maximum 999999
    $result = [Math]::Pow($x, 1.5) / [Math]::Log([Math]::Abs($x) + 1) # Lam cho phep tinh nang hon chut
    
    # Lay gia tri CPU hien tai va cap nhat max
    try {
        $cpuNow = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
        if ($cpuNow -gt $cpuMaxLight) { $cpuMaxLight = $cpuNow }
    } catch {
        # Bo qua loi Get-Counter neu co, nhung van tiep tuc test
    }

    # Cap nhat tien do
    $elapsedSeconds = ((Get-Date) - $endTimeLight.AddSeconds(-30)).TotalSeconds
    $lightTestProgress = ($elapsedSeconds / 30) * 100
    Write-Progress -Activity "Dang chay Stress Test CPU Nhe" -Status "Thoi gian con lai: $([int](30 - $elapsedSeconds))s" -PercentComplete $lightTestProgress
}
Write-Progress -Activity "Stress Test CPU Nhe" -Status "Hoan tat!" -PercentComplete 100 -Completed

Write-Host "CPU Max (Test nhe): $([Math]::Round($cpuMaxLight,2))%" -ForegroundColor Cyan
Write-Host "Da hoan tat stress test nhe.`n" -ForegroundColor Green

# ===== STRESS TEST CPU NANG (60 GIAY - DA LUONG) =====
Write-Host "`n===== STRESS TEST CPU NANG (60 GIAY - MA TRAN & HAM MU) =====" -ForegroundColor Red
Write-Host "VUI LONG MO TASK MANAGER (Ctrl+Shift+Esc) VA CHUYEN SANG TAB HIEN THI HIEU SUAT (Performance)" -ForegroundColor White -BackgroundColor DarkRed
Write-Host "DE THEO DOI MUC DO SU DUNG CPU TRONG QUA TRINH TEST." -ForegroundColor White -BackgroundColor DarkRed

$logicalCores = (Get-CimInstance Win32_Processor).NumberOfLogicalProcessors
$coreToUse = [math]::Max(1, [math]::Floor($logicalCores * 0.9)) # Tang len 90% cac luong co san
$durationHeavy = 60 # Doi bien de tranh nham lan
$matrixSizeHeavy = 50 # Tang kich thuoc ma tran de tang tai
$cpuMaxHeavy = 0 # Bien luu tru gia tri CPU Max cho test nang

# Script test CPU nang cho moi Job
$heavyScriptBlock = {
    param($jobDuration, $matrixSize)
    $end = (Get-Date).AddSeconds($jobDuration)
    while ((Get-Date) -lt $end) {
        $matrixA = @()
        $matrixB = @()

        for ($i = 0; $i -lt $matrixSize; $i++) {
            $rowA = @(for ($j = 0; $j -lt $matrixSize; $j++) { Get-Random -Minimum 1 -Maximum 100 })
            $rowB = @(for ($j = 0; $j -lt $matrixSize; $j++) { Get-Random -Minimum 1 -Maximum 100 })
            $matrixA += ,$rowA
            $matrixB += ,$rowB
        }

        # Phep nhan ma tran va cac phep tinh toan hoc phuc tap hon
        $result = @()
        for ($i = 0; $i -lt $matrixSize; $i++) {
            $row = @()
            for ($j = 0; $j -lt $matrixSize; $j++) {
                $sum = 0
                for ($k = 0; $k -lt $matrixSize; $k++) {
                    $sum += $matrixA[$i][$k] * $matrixB[$k][$j]
                }
                # Them cac phep tinh nang hon de tang tai CPU
                $val = ([Math]::Exp([Math]::Log10([Math]::Abs($sum) + 1)) * [Math]::Sin([Math]::Sqrt([Math]::Abs($sum)))) / 2
                $row += $val
            }
            $result += ,$row
        }
    }
}

# Chay cac job song song
$jobs = @()
Write-Host "Dang khoi tao $coreToUse job de test CPU nang..." -ForegroundColor Yellow
for ($i = 1; $i -le $coreToUse; $i++) {
    $jobs += Start-Job -ScriptBlock $heavyScriptBlock -ArgumentList $durationHeavy, $matrixSizeHeavy
}

# Theo doi CPU trong luc chay va lay gia tri Max
$endHeavyTest = (Get-Date).AddSeconds($durationHeavy)
$heavyTestProgress = 0

Write-Progress -Activity "Dang chay Stress Test CPU Nang (Da Luong)" -Status "Dang khoi tao..." -PercentComplete 0

while ((Get-Date) -lt $endHeavyTest) {
    try {
        $cpuNow = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
        if ($cpuNow -gt $cpuMaxHeavy) { $cpuMaxHeavy = $cpuNow }
    } catch {
        # Bo qua loi Get-Counter neu co
    }

    $elapsedSecondsHeavy = ((Get-Date) - $endHeavyTest.AddSeconds(-$durationHeavy)).TotalSeconds
    $heavyTestProgress = ($elapsedSecondsHeavy / $durationHeavy) * 100
    Write-Progress -Activity "Dang chay Stress Test CPU Nang (Da Luong)" -Status "Thoi gian con lai: $([int]($durationHeavy - $elapsedSecondsHeavy))s" -PercentComplete $heavyTestProgress
    Start-Sleep -Milliseconds 500
}
Write-Progress -Activity "Stress Test CPU Nang (Da Luong)" -Status "Hoan tat!" -PercentComplete 100 -Completed

# Doi jobs hoan thanh va dọn dẹp
Write-Host "Dang doi cac Job test CPU nang hoan thanh va dang don dep..." -ForegroundColor Yellow
$jobs | Wait-Job | Out-Null # Doi tat ca cac job hoan thanh
$jobs | Remove-Job -Force # Xoa tat ca cac job, ke ca neu co loi

Write-Host "CPU Max (Test nang): $([Math]::Round($cpuMaxHeavy,2))%" -ForegroundColor Cyan

$temp3 = Get-CPUTemp
if ($temp3 -ne $null) {
    Write-Host "Nhiet do CPU sau test nang: $temp3°C" -ForegroundColor Yellow
}
Write-Host "Da hoan tat stress test nang.`n" -ForegroundColor Green

Write-Host "===== KIEM TRA HE THONG DA HOAN TAT =====" -ForegroundColor Green -BackgroundColor Black