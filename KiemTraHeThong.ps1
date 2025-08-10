# KiemTraHeThong_Full.ps1
# Ban full: Thong tin he thong + Stress test CPU + Kiem tra Camera (Hello/Thuong) + Van tay

# ===== THONG TIN HE DIEU HANH =====
Write-Host "===== THONG TIN HE DIEU HANH =====" -ForegroundColor Cyan
Get-ComputerInfo | Select-Object CsName, OsName, WindowsVersion, OsArchitecture, BiosVersion, CsManufacturer, CsModel | Format-List

# ===== THONG TIN CPU =====
Write-Host "`n===== THONG TIN CPU =====" -ForegroundColor Cyan
Get-WmiObject Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed | Format-List

# ===== THONG TIN RAM =====
Write-Host "`n===== THONG TIN RAM =====" -ForegroundColor Cyan
Get-WmiObject Win32_PhysicalMemory | ForEach-Object {
    "Dung luong: {0} GB - Toc do: {1} MHz - Hang: {2}" -f ([math]::Round($_.Capacity/1GB,1)), $_.Speed, $_.Manufacturer
}

# ===== THONG TIN O DIA =====
Write-Host "`n===== THONG TIN O DIA =====" -ForegroundColor Cyan
Get-PhysicalDisk | Select-Object FriendlyName, MediaType, Size, SerialNumber | Format-Table -AutoSize

# ===== HAM LAY NHIET DO CPU =====
Function Get-CPUTemp {
    try {
        $temp = Get-WmiObject MSAcpi_ThermalZoneTemperature -Namespace "root/wmi"
        if ($temp -ne $null) {
            ($temp.CurrentTemperature - 2732) / 10
        } else { $null }
    } catch { $null }
}

$temp1 = Get-CPUTemp
if ($temp1 -ne $null) {
    Write-Host "Nhiet do CPU truoc test: $temp1°C" -ForegroundColor Yellow
} else {
    Write-Host "Khong the lay nhiet do CPU truoc test" -ForegroundColor Yellow
}

# ===== KIEM TRA THIET BI MANG =====
Write-Host "`n===== KIEM TRA THIET BI MANG =====" -ForegroundColor Cyan
Get-NetAdapter | Select-Object Name, InterfaceDescription, Status, LinkSpeed, MacAddress | Format-Table -AutoSize

$wifiAdapter = Get-NetAdapter -Name *Wi-Fi* -ErrorAction SilentlyContinue
if ($wifiAdapter) {
    Write-Host "`n-- Thong tin chi tiet Card Wi-Fi: --" -ForegroundColor Green
    $wifiAdapter | Select-Object Name, InterfaceDescription, Status, LinkSpeed, MacAddress, DriverVersion, NdisVersion | Format-List
} else {
    Write-Host "`n-- Khong phat hien Card Wi-Fi hoat dong --" -ForegroundColor Red
}

# ===== KIEM TRA BLUETOOTH + CARD DO HOA ROI =====
Write-Host "`n===== KIEM TRA THIET BI BLUETOOTH VA CARD DO HOA ROI =====" -ForegroundColor Cyan
$bluetoothDevices = Get-WmiObject Win32_PnPEntity | Where-Object {$_.Caption -like "*Bluetooth*" -or $_.Name -like "*Bluetooth*"}
if ($bluetoothDevices) {
    Write-Host "`n-- Thiet bi Bluetooth duoc phat hien: --" -ForegroundColor Green
    $bluetoothDevices | Select-Object Name, DeviceID, Manufacturer, Status | Format-List
} else {
    Write-Host "`n-- Khong phat hien thiet bi Bluetooth --" -ForegroundColor Red
}

$gpuDevices = Get-WmiObject Win32_PnPEntity | Where-Object {
    ($_.Caption -like "*graphics*" -or $_.Caption -like "*display*") -and ($_.PNPDeviceID -notlike "*VID_8086*")
}
if ($gpuDevices) {
    Write-Host "`n-- Card do hoa roi duoc phat hien: --" -ForegroundColor Green
    $gpuDevices | Select-Object Name, DeviceID, Manufacturer, Status | Format-List
} else {
    Write-Host "`n-- Khong phat hien card do hoa roi --" -ForegroundColor Red
}

# Kiem tra danh sach camera va tim camera nhan dien khuon mat
# Su dung WMI de lay thong tin thiet bi video
Write-Host "=== KIEM TRA CAMERA ==="

# Lay danh sach camera tu lop Win32_PnPEntity co ten chua "camera" hoac "video"
$cameras = Get-WmiObject Win32_PnPEntity | Where-Object { $_.Name -match "camera|video" }

if ($cameras) {
    foreach ($cam in $cameras) {
        Write-Host "Tim thay camera: $($cam.Name)"
        
        # Kiem tra ten co chua tu khoa lien quan den nhan dien khuon mat
        if ($cam.Name -match "infrared|IR|RealSense|Hello|face|depth") {
            Write-Host " => Camera nay co kha nang la camera nhan dien khuon mat" -ForegroundColor Green
        } else {
            Write-Host " => Camera nay co kha nang chi la camera thuong" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "Khong tim thay camera nao" -ForegroundColor Red
}

# Kiem tra danh sach thiet bi van tay
Write-Host "`n=== KIEM TRA VAN TAY ==="

# Lay danh sach thiet bi co tu khoa fingerprint
$fingerprintDevices = Get-WmiObject Win32_PnPEntity | Where-Object { $_.Name -match "fingerprint|synaptics|validity|Goodix" }

if ($fingerprintDevices) {
    foreach ($fp in $fingerprintDevices) {
        Write-Host "Tim thay thiet bi van tay: $($fp.Name)" -ForegroundColor Green
    }
} else {
    Write-Host "Khong tim thay thiet bi van tay" -ForegroundColor Red
}


# ===== STRESS TEST CPU NHE (30s) =====
Write-Host "`n===== STRESS TEST CPU NHE (30 GIAY) =====" -ForegroundColor Yellow
$cpuSamplesLight = @()
$endTimeLight = (Get-Date).AddSeconds(30)
while ((Get-Date) -lt $endTimeLight) {
    $x = Get-Random -Minimum 1000 -Maximum 999999
    $null = [Math]::Pow($x, 1.5) / [Math]::Log([Math]::Abs($x) + 1)
    try {
        $cpuNow = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
        $cpuSamplesLight += $cpuNow
    } catch {}
    Start-Sleep -Milliseconds 500
}
if ($cpuSamplesLight.Count -gt 0) {
    $cpuAverageLight = ($cpuSamplesLight | Measure-Object -Average).Average
    Write-Host "CPU trung binh (Test nhe): $([Math]::Round($cpuAverageLight,2))%" -ForegroundColor Cyan
}

# ===== STRESS TEST CPU NANG (60 GIAY, DA LUONG) =====
Write-Host "`n===== STRESS TEST CPU NANG (60 GIAY) =====" -ForegroundColor Red
$logicalCores = (Get-CimInstance Win32_Processor).NumberOfLogicalProcessors
$coreToUse = [math]::Max(1, [math]::Floor($logicalCores * 0.9))
$durationHeavy = 60
$matrixSizeHeavy = 50
$cpuSamplesHeavy = @()
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
        $result = @()
        for ($i = 0; $i -lt $matrixSize; $i++) {
            $row = @()
            for ($j = 0; $j -lt $matrixSize; $j++) {
                $sum = 0
                for ($k = 0; $k -lt $matrixSize; $k++) {
                    $sum += $matrixA[$i][$k] * $matrixB[$k][$j]
                }
                $val = ([Math]::Exp([Math]::Log10([Math]::Abs($sum) + 1)) * [Math]::Sin([Math]::Sqrt([Math]::Abs($sum)))) / 2
                $row += $val
            }
            $result += ,$row
        }
    }
}
$jobs = @()
for ($i = 1; $i -le $coreToUse; $i++) {
    $jobs += Start-Job -ScriptBlock $heavyScriptBlock -ArgumentList $durationHeavy, $matrixSizeHeavy
}
$endHeavyTest = (Get-Date).AddSeconds($durationHeavy)
while ((Get-Date) -lt $endHeavyTest) {
    try {
        $cpuNow = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
        $cpuSamplesHeavy += $cpuNow
    } catch {}
    Start-Sleep -Milliseconds 500
}
$jobs | Wait-Job | Out-Null
$jobs | Remove-Job -Force
if ($cpuSamplesHeavy.Count -gt 0) {
    $cpuAverageHeavy = ($cpuSamplesHeavy | Measure-Object -Average).Average
    Write-Host "CPU trung binh (Test nang): $([Math]::Round($cpuAverageHeavy,2))%" -ForegroundColor Cyan
}
$temp3 = Get-CPUTemp
if ($temp3 -ne $null) {
    Write-Host "Nhiet do CPU sau test nang: $temp3°C" -ForegroundColor Yellow
}

Write-Host "===== KIEM TRA HE THONG DA HOAN TAT =====" -ForegroundColor Green -BackgroundColor Black
