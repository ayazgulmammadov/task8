param(
    [Parameter(Mandatory)][string]$ctxFilePath,
    [Parameter(Mandatory)][string]$username,
    [Parameter(Mandatory)][securestring]$password,
    [Parameter(Mandatory)][string]$resgroupName,
    [Parameter(Mandatory)][string]$location,
    [Parameter(Mandatory)][string]$storageName,
    [Parameter(Mandatory)][string]$sql1Name,
    [Parameter(Mandatory)][string]$sql2Name,
    [Parameter(Mandatory)][string]$db01,
    [Parameter(Mandatory)][string]$db02,
    [Parameter(Mandatory)][string]$db03,
    [Parameter(Mandatory)][string]$sql2dbName,
    [Parameter(Mandatory)][string]$startIP,
    [Parameter(Mandatory)][string]$endIP
    )
#add azure rm account
Import-AzureRmContext -Path $ctxFilePath

#credentials for sql server
$psw = $password | ConvertTo-SecureString -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential -ArgumentList $username, $psw

#create a new azure resource group
New-AzureRmResourceGroup -Name $resgroupName -Location $location

#create new storage account and container for sql backup files
New-AzureRmStorageAccount `
    -ResourceGroupName $resgroupName `
    -Name $storageName `
    -SkuName Standard_LRS `
    -Location $location `
    -Kind Storage

Set-AzureRmCurrentStorageAccount -ResourceGroupName $resgroupName -Name $storageName
$container = New-AzureStorageContainer -Name "sqlbackup" -Permission Container
$bacpacURI = $container.CloudBlobContainer.Uri.AbsoluteUri + "/dbbackup.bacpac"
$storageKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $resgroupName -Name $storagename).Value[0]

#create new azure sql server and firewall rule
New-AzureRmSqlServer `
    -ResourceGroupName $resgroupName `
    -ServerName $sql1Name `
    -Location $location `
    -SqlAdministratorCredentials $cred

New-AzureRmSqlServerFirewallRule `
    -FirewallRuleName 'AllowedIPs' `
    -ServerName $sql1Name `
    -ResourceGroupName $resgroupName `
    -StartIpAddress $startIP `
    -EndIpAddress $endIP

#create 3 databases on the sql server
$databases = @($db01,$db02,$db03)
foreach($database in $databases){
    New-AzureRmSqlDatabase `
        -ResourceGroupName $resgroupName `
        -ServerName $sql1Name `
        -DatabaseName $database `
        -RequestedServiceObjectiveName 'S0'}

#export sql db backup to azure storage container
New-AzureRmSqlDatabaseExport `
    -ResourceGroupName $resgroupName `
    -ServerName $sql1Name `
    -DatabaseName $db01 `
    -StorageKeyType StorageAccessKey `
    -StorageKey $storageKey `
    -StorageUri $bacpacURI `
    -AdministratorLogin $cred.UserName `
    -AdministratorLoginPassword $cred.Password 

#create another sql server and database with the same credentials in the same resourse group
New-AzureRmSqlServer `
    -ResourceGroupName $resgroupName `
    -ServerName $sql2Name `
    -Location $location `
    -SqlAdministratorCredentials $cred

New-AzureRmSqlDatabase `
    -ResourceGroupName $resgroupName `
    -DatabaseName $sql2dbName `
    -ServerName $sql2Name `
    -RequestedServiceObjectiveName 'S0' 

#create firewall rule for second sql server
New-AzureRmSqlServerFirewallRule `
    -FirewallRuleName 'AllowedIPs' `
    -ServerName $sql2Name `
    -ResourceGroupName $resgroupName `
    -StartIpAddress $startIP `
    -EndIpAddress $endIP
    
#Import sql backup to antoher Azure SQL server
New-AzureRmSqlDatabaseImport `
    -ResourceGroupName $resgroupName `
    -ServerName $sql2Name `
    -DatabaseName $sql2dbName `
    -ServiceObjectiveName 'S0' `
    -StorageKeyType StorageAccessKey `
    -StorageKey $storageKey `
    -StorageUri $bacpacURI `
    -AdministratorLogin $cred.UserName `
    -AdministratorLoginPassword $cred.Password `
    -Edition Standard `
    -DatabaseMaxSizeBytes 5000000 