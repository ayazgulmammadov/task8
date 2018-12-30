param(
    #[Parameter(Mandatory)][string]$ctxFilePath,
    [Parameter(Mandatory)][string]$username,
    [Parameter(Mandatory)][securestring]$password,
    [Parameter(Mandatory)][string]$resgroupName,
    [Parameter(Mandatory)][string]$location,
    [Parameter(Mandatory)][string]$storageName,
    [Parameter(Mandatory)][ValidateCount(2,2)][string[]]$sqlserverNames,
    [Parameter(Mandatory)][ValidateCount(4,4)][string[]]$databaseNames,
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

#create 2 azure sql servers and firewall rules for each of them
foreach($sqlserver in $sqlserverNames){
    New-AzureRmSqlServer `
        -ResourceGroupName $resgroupName `
        -ServerName $sqlserver `
        -Location $location `
        -SqlAdministratorCredentials $cred
}
foreach($sqlserver in $sqlserverNames){
    New-AzureRmSqlServerFirewallRule `
        -FirewallRuleName 'AllowedIPs' `
        -ServerName $sqlserver `
        -ResourceGroupName $resgroupName `
        -StartIpAddress $startIP `
        -EndIpAddress $endIP
}

#create 3 databases on the 1st sql server
for($i=0; $i -le 2; $i ++){
    New-AzureRmSqlDatabase `
        -ResourceGroupName $resgroupName `
        -ServerName $sqlserverNames[0] `
        -DatabaseName $databaseNames[$i] `
        -RequestedServiceObjectiveName 'S0'} 

#create 1 database on the 2nd sql server
New-AzureRmSqlDatabase `
    -ResourceGroupName $resgroupName `
    -ServerName $sqlserverNames[1] `
    -DatabaseName $databaseNames[3] `
    -RequestedServiceObjectiveName 'S0'

#export sql db backup to azure storage container
New-AzureRmSqlDatabaseExport `
    -ResourceGroupName $resgroupName `
    -ServerName $sqlserverNames[0] `
    -DatabaseName $databaseNames[0] `
    -StorageKeyType StorageAccessKey `
    -StorageKey $storageKey `
    -StorageUri $bacpacURI `
    -AdministratorLogin $cred.UserName `
    -AdministratorLoginPassword $cred.Password 
   
#import sql backup to the 2nd sql server
New-AzureRmSqlDatabaseImport `
    -ResourceGroupName $resgroupName `
    -ServerName $sqlserverNames[1] `
    -DatabaseName $databaseNames[3] `
    -ServiceObjectiveName 'S0' `
    -StorageKeyType StorageAccessKey `
    -StorageKey $storageKey `
    -StorageUri $bacpacURI `
    -AdministratorLogin $cred.UserName `
    -AdministratorLoginPassword $cred.Password `
    -Edition Standard `
    -DatabaseMaxSizeBytes 5000000 