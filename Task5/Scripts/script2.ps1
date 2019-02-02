param(
    [string] $folderPath,
    [string] $fileName
)
New-Item -Path $folderPath -Name $fileName -ItemType File