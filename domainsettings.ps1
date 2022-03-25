
### Assigns the server a static IP address
# https://www.pdq.com/blog/using-powershell-to-set-static-and-dhcp-ip-addresses-part-1/

$IP = "192.168.2.2"
$MaskBits = 24 # This means subnet mask = 255.255.255.0
$Gateway = "192.168.2.1"
$Dns = "8.8.8.8"
$IPType = "IPv4"
# Retrieve the network adapter that you want to configure
$adapter = Get-NetAdapter | ? {$_.Status -eq "up"}
# Remove any existing IP, gateway from our ipv4 adapter
If (($adapter | Get-NetIPConfiguration).IPv4Address.IPAddress) {
 $adapter | Remove-NetIPAddress -AddressFamily $IPType -Confirm:$false
}
If (($adapter | Get-NetIPConfiguration).Ipv4DefaultGateway) {
 $adapter | Remove-NetRoute -AddressFamily $IPType -Confirm:$false
}
 # Configure the IP address and default gateway
$adapter | New-NetIPAddress `
 -AddressFamily $IPType `
 -IPAddress $IP `
 -PrefixLength $MaskBits `
 -DefaultGateway $Gateway

### Assigns the server a DNS

# Configure the DNS client server IP addresses
$adapter | Set-DnsClientServerAddress -ServerAddresses $DNS

### Renames the server
# https://www.dell.com/support/kbdoc/en-us/000122521/changing-the-windows-computer-name-in-server-2012#:~:text=Windows%20Server%20Core.-,1.,to%20change%20the%20computer%20name.

$CurrentComputerName = $env:COMPUTERNAME + '\Administrator'
$CurrentDomainName = $env:USERDOMAIN + '\Administrator'
$NewComputerName = DC2019

Rename-Computer -NewName $NewComputerName -LocalCredential $CurrentComputerName -PassThru
#Rename-Computer -NewName $NewComputerName -DomainCredential $CurrentComputerName -PassThru

### Installs AD-Domain-Services
# https://docs.microsoft.com/en-us/windows-server/identity/ad-ds/deploy/install-active-directory-domain-services--level-100-

Install-windowsfeature -name AD-Domain-Services -IncludeManagementTools

### Installs an AD Forest
# https://docs.microsoft.com/en-us/powershell/module/addsdeployment/install-addsforest?view=windowsserver2022-ps

$FQDomain = $env:USERDNSDOMAIN

Install-ADDSForest -DomainName $FQDomain

### Creates Organizational Units
# https://docs.microsoft.com/en-us/powershell/module/activedirectory/new-adorganizationalunit?view=windowsserver2022-ps

$OUName = 'UserAccounts'
$Domain = $env:USERDOMAIN

New-ADOrganizationalUnit -Name $OUName -Path "DC=$Domain,DC=COM"

### Creates Users
# https://docs.microsoft.com/en-us/powershell/module/activedirectory/new-aduser?view=windowsserver2022-ps

$User = 'TestUser'
$Title = 'CEO'
$Email = 'testuser@' + $env:USERDOMAIN + '.com'

New-ADUser -Name $User -OtherAttributes @{'title'=$Title;'mail'=$Email}
