param(
    [Parameter(Mandatory)][string]$SubscriptionName,
    [Parameter(Mandatory)][string]$StorageAccountName,
    [Parameter(Mandatory)][string]$ResGroup,
    [Parameter(Mandatory)][string]$Location,
    [Parameter(Mandatory)][string]$ContainerName,
    [Parameter(Mandatory)][string]$FilesToUpload
    )
# Add your Azure account to the local Powershell environment
Add-AzureRmAccount

# If we don't have a resource group, we have to create one
New-AzureRmResourceGroup -Name $ResGroup -Location $Location

# Create a new storage account
New-AzureRmStorageAccount -StorageAccountName $StorageAccountName -Location $Location -ResourceGroupName $ResGroup -SkuName Standard_LRS

# Set a current storage account
Set-AzureRmCurrentStorageAccount -ResourceGroupName $ResGroup -Name $StorageAccountName

# Create a new container
New-AzureStorageContainer -Name $ContainerName -Permission Off

# Upload files into a container
Get-ChildItem -File $FilesToUpload -Recurse | Set-AzureStorageBlobContent -Container $ContainerName 