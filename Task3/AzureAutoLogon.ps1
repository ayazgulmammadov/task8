<#
After logging into Azure, save the credentials in a file that you can use in the future in the PowerShell script for the logon process.
#>
param(
    [Parameter(Mandatory)][string]$Path
)
Login-AzureRmAccount | Save-AzureRmContext -Path $Path