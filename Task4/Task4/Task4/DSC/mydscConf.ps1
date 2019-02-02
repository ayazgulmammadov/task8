Configuration Main
{

Param ( 
  [string] $nodeName,
  [string] $fileUri,
  [string] $fileName )

Import-DscResource -ModuleName PSDesiredStateConfiguration
Import-DscResource -ModuleName xPSDesiredStateConfiguration

Node $nodeName
  {
   File newFolder
   {
     Ensure = "Present"
     DestinationPath = "C:\Scripts"
     Type = "Directory"
   }
   xRemoteFile copyFile
   {
     Uri = "$fileUri"
     DestinationPath = "C:\Scripts\$fileName"
     DependsOn = "[File]newFolder"
   }
  }
}