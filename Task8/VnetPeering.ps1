$firstVNetName = 'VNet-01'
$secondVNetName = 'VNet-02'
$firstResourceGroup = 'task8-01-rg'
$secondResourceGroup = 'task8-02-rg'


$vnet01 = Get-AzureRmVirtualNetwork -Name $firstVNetName -ResourceGroupName $firstResourceGroup
$vnet02 = Get-AzureRmVirtualNetwork -Name $secondVNetName -ResourceGroupName $secondResourceGroup

Add-AzureRmVirtualNetworkPeering -Name "vnet01-vnet02" -VirtualNetwork $vnet01 -RemoteVirtualNetworkId $vnet02.Id
Add-AzureRmVirtualNetworkPeering -Name "vnet02-vnet01" -VirtualNetwork $vnet02 -RemoteVirtualNetworkId $vnet01.Id