# Reset hàng đợi in (Print Queue) - PowerShell Script
# Tác giả: ChatGPT

# Tạm dừng dịch vụ Print Spooler
Write-Output "Stopping Print Spooler service..."
Stop-Service -Name spooler -Force

# Xóa tất cả lệnh in đang chờ trong thư mục spool
Write-Output "Clearing print queue..."
$spoolFolder = "C:\Windows\System32\spool\PRINTERS\"
Remove-Item "$spoolFolder*" -Force -ErrorAction SilentlyContinue

# Khởi động lại dịch vụ Print Spooler
Write-Output "Starting Print Spooler service..."
Start-Service -Name spooler

Write-Output "✅ Print queue has been cleared successfully."
