Set-ExecutionPolicy bypass -force

# Use the actual name of the network interface instead of "Ethernet"
$interfaceAlias = "Ethernet"

try {
    # Use "-ErrorAction Stop" to terminate the script if an error occurs
    $interfaces = Get-DnsClientServerAddress -InterfaceAlias $interfaceAlias -ErrorAction Stop
    $CurrentDNS = $interfaces.ServerAddresses
    $InterfaceIndex = $interfaces.InterfaceIndex

    switch ($CurrentDNS) {
        "8.8.8.8" {
            Write-Host "Setting DNS to DCES01"
            Set-DnsClientServerAddress -InterfaceIndex $InterfaceIndex -ServerAddresses "10.129.100.11" -Confirm:$false
        }
        Default {
            Write-Host "Setting DNS to GoogleDNS"
            Set-DnsClientServerAddress -InterfaceIndex $InterfaceIndex -ServerAddresses "8.8.8.8" -Confirm:$false
        }
    }
    Write-Host "DNS has been set"
    [System.Windows.MessageBox]::Show('Press ok to continue')
}
catch {
    Write-Host "Unable to get or set DNS: $($Error[0].Exception.Message)"
}
