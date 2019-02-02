Configuration Main
{

Param ( 
  [string] $nodeName,
  [string] $script2Uri )

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
   xRemoteFile copyScript
   {
     Uri = "$script2Uri"
     DestinationPath = "C:\Scripts\script2.ps1"
     DependsOn = "[File]newFolder"
   }
  }
}