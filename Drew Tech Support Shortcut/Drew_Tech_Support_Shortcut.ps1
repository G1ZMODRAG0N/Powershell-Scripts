#Create Drew Tech Support shorcut on user desktop
$exitCode = 0
$ErrorActionPreference = "SilentlyContinue"

if (-not (Test-Path "C:\Users\Public\Desktop\Drew Tech Support.url"))
{
$null = $WshShell = New-Object -comObject WScript.Shell
$path = "C:\Users\Public\Desktop\Drew Tech Support.url"
$targetpath = "https://drewcharter.incidentiq.com/"
$iconlocation = "C:\ProgramData\AutoPilotConfig\Icons\drew_tech_support_icon.ico"
$iconfile = "IconFile=" + $iconlocation
$Shortcut = $WshShell.CreateShortcut($path)
$Shortcut.TargetPath = $targetpath
$Shortcut.Save()

Add-Content $path "HotKey=0"
Add-Content $path "$iconfile"
Add-Content $path "IconIndex=0"

}
#
exit $exitCode