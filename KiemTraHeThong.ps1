# KiemTraHeThong.ps1 - Ban nang cao, khong dau, chi in ra man hinh

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
Function Get-CPUTemp {
    try {
        $temp = Get-WmiObject MSAcpi_ThermalZoneTemperature -Namespace "root/wmi"
        if ($temp -ne $null) {
            ($temp.CurrentTemperature - 2732) / 10
        } else {
            $null
        }
    } catch {
        $null
    }
}

$temp1 = Get-CPUTemp
if ($temp1 -ne $null) {
    Write-Host "Nhiet do CPU truoc test: $temp1°C" -ForegroundColor Yellow
} else {
    Write-Host "Khong the lay nhiet do CPU truoc test (co the khong ho tro WMI)" -ForegroundColor Yellow
}

# ===== STRESS TEST CPU NHE (30 GIAY) =====
Write-Host "`n===== STRESS TEST CPU NHE (30 GIAY, 1 LUONG) =====" -ForegroundColor Yellow

$cpuMax = 0
$endTime = (Get-Date).AddSeconds(30)

while ((Get-Date) -lt $endTime) {
    $x = Get-Random -Minimum 100 -Maximum 99999
    $result = [Math]::Pow($x, 1.5)

    $cpuNow = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
    if ($cpuNow -gt $cpuMax) { $cpuMax = $cpuNow }
}

Write-Host "CPU max: $([Math]::Round($cpuMax,2))%" -ForegroundColor Cyan

$temp2 = Get-CPUTemp
if ($temp2 -ne $null) {
    Write-Host "Nhiet do CPU sau test nhe: $temp2°C" -ForegroundColor Yellow
}
Write-Host "Da hoan tat stress test nhe.`n" -ForegroundColor Green

# ===== STRESS TEST CPU NANG (60 GIAY - MA TRAN & HAM MU) =====
Write-Host "`n===== STRESS TEST CPU NANG (60 GIAY - MA TRAN & HAM MU) =====" -ForegroundColor Red

$logicalCores = (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors
$coreToUse = [math]::Max(1, [math]::Floor($logicalCores * 0.8))
$duration = 60
$cpuMaxHeavy = 0

# Script test CPU nang
$script = {
    $end = (Get-Date).AddSeconds($using:duration)
    while ((Get-Date) -lt $end) {
        $matrixSize = 40
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
                $val = [Math]::Exp([Math]::Log10([Math]::Abs($sum) + 1))
                $row += $val
            }
            $result += ,$row
        }
    }
}

# Chay cac job song song
$jobs = @()
for ($i = 1; $i -le $coreToUse; $i++) {
    $jobs += Start-Job -ScriptBlock $script
}

# Theo doi CPU trong luc chay
$endTest = (Get-Date).AddSeconds($duration)
while ((Get-Date) -lt $endTest) {
    $cpuNow = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
    if ($cpuNow -gt $cpuMaxHeavy) { $cpuMaxHeavy = $cpuNow }
    Start-Sleep -Milliseconds 500
}

# Doi jobs hoan thanh, roi moi xoa
$jobs | Wait-Job
$jobs | Remove-Job

Write-Host "CPU max: $([Math]::Round($cpuMaxHeavy,2))%" -ForegroundColor Cyan

$temp3 = Get-CPUTemp
if ($temp3 -ne $null) {
    Write-Host "Nhiet do CPU sau test nang: $temp3°C" -ForegroundColor Yellow
}
Write-Host "Da hoan tat stress test nang.`n" -ForegroundColor Green
