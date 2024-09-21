if not exist "C:\ProgramData\AutoPilotConfig" md "C:\ProgramData\AutoPilotConfig"
if not exist "C:\ProgramData\AutoPilotConfig\Icons" md "C:\ProgramData\AutoPilotConfig\Icons"
xcopy "Drew_Tech_Support_Shortcut.ps1" "C:\ProgramData\AutoPilotConfig" /Y
xcopy "drew_tech_support_icon.ico" "C:\ProgramData\AutoPilotConfig\Icons" /Y
Powershell.exe -Executionpolicy bypass -File "C:\ProgramData\AutoPilotConfig\Drew_Tech_Support_Shortcut.ps1"