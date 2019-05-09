Configuration Main
{

    Param ( [string] $nodeName )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xNetworking

    Node $nodeName
    {
        xFirewall EnableV4PingIn
        {
            Name    = "FPS-ICMP4-ERQ-In"
            Enabled = "True"
        }
        xFirewall EnableV4PingOut
        {
            Name    = "FPS-ICMP4-ERQ-Out"
            Enabled = "True"
        }
    }
}