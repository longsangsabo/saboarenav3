Write-Host "Performing hot reload..."
$process = Get-Process | Where-Object {$_.ProcessName -eq "flutter" -and $_.MainWindowTitle -like "*SABO*"}
if ($process) {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.SendKeys]::SendWait("r")
    Write-Host "Hot reload command sent!"
} else {
    Write-Host "Flutter process not found. Please run manually in terminal with 'r'"
}