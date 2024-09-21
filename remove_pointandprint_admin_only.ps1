#Add registry key to allow installtion or printer drivers without administrative prompt
Write-Host "`n`n`n`n----------MODIFYING REGISTRY TO ALLOW FOR NONADMIN PRINTER DRIVER INSTALLATION--------------`n`n`n`n"
Start-Sleep -Seconds 1

Write-Host "...Checking registry key`n`n`n"
Start-Sleep -Seconds 3

$registryKeyInstalled = Get-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows NT\Printers\PointAndPrint" -Name "RestrictDriverInstallationToAdministrators" -ErrorAction SilentlyContinue | Select-Object -Property RestrictDriverInstallationToAdministrators 

if($registryKeyInstalled -eq $null){
    Write-Host "Adding registry key for 'HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows NT\Printers\PointAndPrint KEY:RestrictDriverInstallationToAdministrators'`n`n"
    reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows NT\Printers\PointAndPrint" /v RestrictDriverInstallationToAdministrators /t REG_DWORD /d 0 /f
    Start-Sleep -Seconds 1
    Write-Host -ForegroundColor Green "Registry key succesfully added. Restarting PrintSpooler service...`n`n"
    Restart-Service Spooler -Force
    Start-Sleep -Seconds 2
    Write-Host -ForegroundColor Green "Restart successful`n`n"
    Start-Sleep -Seconds 1
}else{
    Write-Host "Registry key already exists for 'RestrictDriverInstallationToAdministrators'`n`n"
    Start-Sleep -Seconds 1
    }

    Write-Host "Ending script........"