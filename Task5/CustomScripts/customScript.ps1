param(
    [string] $folder,
    [string] $file
)
$exp = "C:\Scripts\script2.ps1 -folderPath $folder -fileName $file"
Invoke-Expression $exp
if(Test-Path $folder\$file){
    Get-Date | Add-Content $folder\$file}
else{continue}