#
#
#

$PnPSignedDriver = "Win32_PnPSignedDriver"
$driverPathExists = Get-Item -Path "C:\drewDrivers" -ErrorAction SilentlyContinue

#
if($null -eq $driverPathExists){
Write-Host "File path C:\drewDrivers does not exist. Closing..."
Start-Sleep -Seconds 2
#
exit 1
}

#
$currentDriver = Get-WmiObject $PnPSignedDriver | Select-Object -Property DeviceName,DriverVersion | Where-Object -Property DeviceName -match "Wi-Fi 6"
Write-Host "Checking device WLAN driver version..."
Start-Sleep -Seconds 2

#
if($currentDriver.DriverVersion -ne "22.250.1.2"){
    if($currentDriver.DriverVersion -eq ""){
        Write-Host "No WLAN driver detected. Installing WiFi-22.250.1-Driver64-Win10..."
    }else{
        Write-Host "Incorrect driver version" $currentDriver.Version "Updating to 22.250.1.2..."
    }
    #
    #Get-ChildItem "C:\drewDrivers\" -Recurse | 
    #ForEach-Object { PNPUtil.exe /add-driver $_.FullName /install }
    #add wait
    Start-Process C:\drewDrivers\L13G3_WLAN\WiFi-22.250.1-Driver64-Win10-Win11.exe /silent -ErrorAction SilentlyContinue
    Wait-Process -Name "WiFi-22.250.1-Driver64-Win10-Win11" -Timeout 300
    Write-Host "Driver installed..."
}else{
    Write-Host "The correct driver version 22.250.1.2 is already installed. Ending script..."
    exit 0
}

Write-Host "Restarting WLAN adapter..."

#
try{
$DeviceID = Get-PnPDevice -FriendlyName "Intel(R) Wi-Fi 6 AX201 160MHz" -ErrorAction Stop | Select-Object InstanceID 
}catch{
Write-Host "Unable to detect WLAN adapter. Please restart device."
exit 0
}
#
Disable-PnpDevice -InstanceID $DeviceID.InstanceId -Confirm:$false
for($i=0; $i -lt 30; $i++){

if((Get-PnpDevice | Where-Object -Property InstanceID -eq $DeviceID.InstanceId).Status -ne "OK"){
$i = 30
}
Start-Sleep -Seconds 1
}

#
Enable-PnpDevice -InstanceId $DeviceID.InstanceId -Confirm:$false
for($i=0; $i -lt 30; $i++){

if((Get-PnpDevice | Where-Object -Property InstanceID -eq $DeviceID.InstanceId).Status -eq "OK"){
$i = 30
}
Start-Sleep -Seconds 1
}

Write-Host "Connecting to SSID..."
netsh wlan connect name=Drew ssid=Drew
Start-Sleep -Seconds 2

exit 0
