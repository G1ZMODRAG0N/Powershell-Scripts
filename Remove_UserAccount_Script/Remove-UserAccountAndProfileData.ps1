#Elevate Privileges
param([switch]$Elevated)

function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if ((Test-Admin) -eq $false) {
    if ($elevated) {
        # tried to elevate, did not work, aborting
    }
    else {
        Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
    }
    exit
}

Write-Host "Running with full privileges"

#Install the Microsoft Graph API PowerShell module
Write-Host "Checking for installed modules..."
$modules = @("Microsoft.Graph.Intune", "Microsoft.Graph.Identity.DirectoryManagement")
$installed = Get-InstalledModule | Select-Object Name

$modules | ForEach-Object {
    if ($_ -in $installed.Name) {
        Write-host $_ "Already installed. Importing Module..."
        Import-Module $_
    }
    else {
        Write-host "...Installing" $_
        Install-Module $_ -Force -AllowClobber
    } }

# Authenticate to Microsoft Graph API and Intune PowerShell
Write-Host "Authenticating to Microsoft Graph..."
Start-Sleep 1
try { 
    Connect-MgGraph -ErrorAction stop
}
catch {
    Write-Host "ERROR:"$error[0]
    Write-Host "`r`nFailed to connect to Microsoft Graph services...Closing script." 
    exit
}
Write-Host "Successfully connected Microsoft Graph services."
Start-Sleep 2

$removeIndividual = {
    Write-Host "`r`n`r`n`r`n-------REMOVE INDIVIDUAL ACCOUNTS-------"
    #Show all user folders available to be removed
    Write-Host "`r`n`r`nUsers:`r`n"
    (Get-ChildItem -Path c:\users | Select-Object Name).Name | Foreach-Object { Write-Host $_ } 
    # Prompt the user to enter the username of the account to be removed
    $username = Read-Host "`r`nEnter the first.last of the user account you want to remove. Press 3 to cancel."
    if($username -eq 3){return}
    #add a check to  make sure the read is not blank. it will delete all
    if ($username -eq "") {
        Write-Host "Error with $username"
        &$removeIndividual
    }
    $profilePath = "C:\Users\$username"
    $path = $profilePath + "\AppData\Local\Packages"
    $sessionID = ((quser | Where-Object { $_ -match $username }) -split ' +')[2]

    #Check if user is on device by path
    Write-Host "Checking if user account $username exists on this device..."
    Start-Sleep 2
    if (!(Test-Path $profilePath)) {
        Write-Host "Unable to find that user on this device."
        return
    }
    #Check if user is logged in and log them out
    Write-Host "Checking for active account sessions for this user..."
    Start-Sleep 1
    if ($sessionID -match "^[\d\.]+$") {
        Write-Host "An account session for" $username "is currently active. SessionID:" $sessionID"`r`nEnding active session..."
        logoff $sessionID 
        Start-Sleep 1
    }
    else {
        Write-Host "An account session for" $username "is not currently active. No sessions ended."
    }

    #Remove Azure AD User/Work or School account folder
    if (Test-Path $path) {
        Get-ItemProperty -Path $path | ForEach-Object {
            Remove-Item -Path "$_\Microsoft.AAD.BrokerPlugin*" -Recurse -Force | Out-Null
        }
    }
    else { Write-Host "AAD account $username does not exist on this device. Skipping..." }

    # Check if the user exists on the device
    $account = Get-WmiObject -ErrorAction SilentlyContinue -Class Win32_UserAccount | Where-Object { $_.Name -eq $username }
    if (!$account) {
        Write-Host "User account for $username was not found on the local device. Skipping...."
    }
    else {

        # Remove the user account from the Intune-managed device
        $device = Get-MgDevice | Where-Object { $_.deviceName -eq $env:COMPUTERNAME }
        $userId = (Get-MSGraphUser -Filter "userPrincipalName eq '$username'").id
        if (($device -ne $null) -and ($userId -ne $null)) {
            Remove-MSGraphManagedDeviceUser -DeviceId $device.id -UserId $userId
            Write-Host "User account $username has been removed from the Intune-managed device."
        }
        else {
            Write-Host "User account $username was not found on the Intune-managed device. Skipping..."
        }

        # Remove the user account from the local device
        $account.Delete()
        Write-Host "User account $username has been removed from the local device."
    }

    #Remove the user profile folder
    try {   
        & cmd.exe /c rd /S /Q $profilePath
    }
    catch {
        Write-Host "ERROR:"$error[0]
        Write-Host "Failed to remove profile folder $profilePath...Returning to Main Menu"
        return
    }
    Write-Host "User profile folder $profilePath has been successfully removed."

    $confirmation = Read-Host "Remove another user account? [Y/N]"
    while ($confirmation.ToUpper() -ne "N") {
        if ($confirmation.ToUpper() -eq 'Y') { &$removeIndividual }
        if ($confirmation.ToUpper() -eq 'N') { return }
        $confirmation = Read-Host "Remove another user account? [Y/N]"
    }
}

$removeall = {
    Write-Host "`r`n`r`n`r`n-------REMOVE ALL ACCOUNTS-------`r`n`r`n"
    $allUsers = Get-ChildItem -Path c:\users | Select-Object Name | Where-Object Name -ne "DREWadmin" | Where-Object Name -ne "Elliot.Hinton" | Where-Object Name -ne "Public"  | Where-Object Name -ne "Antoine.Brown"  | Where-Object Name -ne "Tamica.Penny" | Where-Object Name -ne "Default"
    $excludedUsers = "DREWadmin", "Elliot.Hinton", "Public", "Antoine.Brown", "Tamica.Penny", "Default", "devicemgmt@drewcharterschool.org"
    $currentUsers = $allUsers
    Write-Host $currentUsers

    if($currentUsers -eq $null){
    Write-Host "There are no users to remove outside of the excluded users:" $excludedUsers "`r`n`Returning to main menu..."
    return
    }
    
    $currentUsers | ForEach-Object {
        # Prompt the user to enter the username of the account to be removed
        $username = $_.Name
        $path = "C:\Users\" + $username + "\AppData\Local\Packages"

        #Remove Azure AD User/Work or School account folder
        if (Test-Path $path) {
            Get-ItemProperty -Path $path | ForEach-Object {
                Remove-Item -Path "$_\Microsoft.AAD.BrokerPlugin*" -Recurse -Force | Out-Null
            }
        }
        else { Write-Host "AAD account $username does not exist on this device. Skipping..." }

        # Check if the user exists on the device
        $account = Get-WmiObject -Class Win32_UserAccount | Where-Object { $_.Name -eq $username }
        if (!$account) {
            Write-Host "User account for $username was not found on the local device. Skipping...."
        }
        else {

            # Remove the user account from the Intune-managed device
            $device = Get-MgDevice | Where-Object { $_.deviceName -eq $env:COMPUTERNAME }
            $userId = (Get-MSGraphUser -Filter "userPrincipalName eq '$username'").id
            if ($device -and $userId) {
                Remove-MSGraphManagedDeviceUser -DeviceId $device.id -UserId $userId
                Write-Host "User account $username has been removed from the Intune-managed device."
            }
            else {
                Write-Host "User account $username was not found on the Intune-managed device. Skipping..."
            }

            # Remove the user account from the local device
            $account.Delete()
            Write-Host "User account $username has been removed from the local device."
        }
        # Remove the user profile folder
        $profilePath = "C:\Users\$username"
        if (Test-Path $profilePath) {
            try {
                &cmd.exe /c rd /s /q $profilePath
            }
            catch {
                Write-Host $Error
                Return
            }
            Write-Host "User profile folder $profilePath has been removed."
        }
        else {
            Write-Host "User profile folder $profilePath was not found. Skipping..."
        }
    }
    Write-Host "Removed all users"
}

#Menu prompt. Numerical options
Write-Host "`r`n`r`n`r`n-------USER ACCOUNT REMOVAL TOOL-------`r`nMAIN MENU"
$options = Read-Host "`r`nSelect an option:`r`n`r`n1. Remove a user account from this device.`r`n`r`n2. Remove all user accounts from this device.`r`n`r`n3. Exit.`r`n`r`n"
while ($options -ne "") {
    if ($options -eq '1') {
        &$removeIndividual
    }
    if ($options -eq '2') {
        &$removeall
    }
    if ($options.ToUpper() -eq '3') {
        # .. Range operator means to create a range (aka 1-3 or a-z) 
        # | Pipeline operator to go through each object one at a time (in this case use the code block {} for each number)
        # % Arithmetic operator that calculates the remainder (in this case which number hasnt been piped)
        #$dots = ".","..","..."
        #0..2 | % {
        #    Write-Host $dots[$_]
        #    Start-Sleep -Milliseconds 1000
        #}
        exit
    }
    Write-Host "`r`n`r`n`r`n-------USER ACCOUNT REMOVAL TOOL-------`r`nMAIN MENU"
    $options = Read-Host "`r`nSelect an option:`r`n`r`n1. Remove a user account from this device.`r`n`r`n2. Remove all user accounts from this device.`r`n`r`n3. Exit`r`n`r`n"
}