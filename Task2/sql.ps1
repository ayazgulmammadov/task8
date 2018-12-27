param(
    [Parameter(Mandatory)][string]$ctxFilePath,
    [Parameter(Mandatory)][string]$username,
    [Parameter(Mandatory)][securestring]$password,
    [Parameter(Mandatory)][string]$rgName,
    [Parameter(Mandatory)][string]$sql1Name,
    [Parameter(Mandatory)][string]$sql2Name,
    [Parameter(Mandatory)][string]$db01,
    [Parameter(Mandatory)][string]$db02,
    [Parameter(Mandatory)][string]$db03,
    [Parameter(Mandatory)][string]$bacpacURL,
    [Parameter(Mandatory)][string]$storageKey,
    [Parameter(Mandatory)][string]$startIP,
    [Parameter(Mandatory)][string]$endIP,
    [Parameter(Mandatory)][string]$requestedSOName,
    [Parameter(Mandatory)][string]$importTOdbName
    )
#Add Azure RM Account
Import-AzureRmContext -Path $ctxFilePath

#credentials for sql server
$password | ConvertTo-SecureString -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential -ArgumentList $username, $password

#create new azure sql server and firewall rule
New-AzureRmSqlServer -ResourceGroupName $rgName -ServerName $sql1Name -Location $location -SqlAdministratorCredentials $cred
New-AzureRmSqlServerFirewallRule -FirewallRuleName 'AllowedIPs' -ServerName $sql2Name -ResourceGroupName $rgName  -StartIpAddress $startIP -EndIpAddress $endIP

#create 3 databases on the sql server
New-AzureRmSqlDatabase -ResourceGroupName $rgName -ServerName $sql1Name -DatabaseName $db01 -RequestedServiceObjectiveName $requestedSOName
New-AzureRmSqlDatabase -ResourceGroupName $rgName -ServerName $sql1Name -DatabaseName $db02 -RequestedServiceObjectiveName $requestedSOName
New-AzureRmSqlDatabase -ResourceGroupName $rgName -ServerName $sql1Name -DatabaseName $db03 -RequestedServiceObjectiveName $requestedSOName

#export sql db backup to azure storage container
New-AzureRmSqlDatabaseExport -ResourceGroupName $rgName -ServerName $sql1Name -DatabaseName $db01 -StorageKeyType StorageAccessKey -StorageKey $storageKey -StorageUri $bacpacURL -AdministratorLogin $cred.UserName -AdministratorLoginPassword $cred.Password 

#Import sql backup to antoher Azure SQL server
New-AzureRmSqlDatabaseImport -ResourceGroupName $rg2Name -ServerName $sql2Name -DatabaseName $importTOdbName -ServiceObjectiveName $requestedSOName -StorageKeyType StorageAccessKey -StorageKey $storageKey -StorageUri $bacpacURL -AdministratorLogin $cred.UserName -AdministratorLoginPassword $cred.Password 
