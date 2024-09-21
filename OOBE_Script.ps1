$HWIDPATH = "C:\HWID"
$pathExists = Test-Path -Path $HWIDPATH

if($pathExists -ne $true){
New-Item -Type Directory -Path $HWIDPATH
}
#start ms-availablenetworks:
#Read-Host -Prompt "Connect to wifi and press Enter to continue"

netsh wlan add profile filename ".\Wi-Fi-DrewII.xml" interface="WiFi" user=all

#netsh wlan connect ssid="DrewII" name=DrewII interface="Wi-Fi" key="0v3r2a1r" 

Set-Location -Path "C:\HWID"
$env:Path += ";C:\Program Files\WindowsPowerShell\Scripts"
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned -Force

Install-Script -Name Get-WindowsAutopilotInfo -Force
Get-WindowsAutopilotInfo -OutputFile AutopilotHWID.csv

Install-Script -name Get-WindowsAutopilotInfo -Force
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned -Force
Get-WindowsAutopilotInfo -Online

Read-Host -Prompt "Press Enter to restart"
Restart-Computer -Force