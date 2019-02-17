Configuration Main
{
    Param ( 
        [string] $nodeName,
        [string] $certUri
    )
     
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xPSDesiredStateConfiguration
    Import-DscResource -ModuleName xNetworking
    Import-DscResource -ModuleName xWebAdministration

    Node $nodeName
    {
        WindowsFeature IIS {
            Ensure = "Present"
            Name   = "Web-Server"
        }
        File certFolder {
            Ensure          = "Present"
            DestinationPath = "C:\Cert"
            Type            = "Directory"
        }
        xRemoteFile copyCert {
            Uri             = "$certUri"
            DestinationPath = "C:\Cert\azureiis.pfx"
            DependsOn       = "[File]certFolder"
        }
        xWebsite DefaultSite {
            Ensure       = "Present"
            Name         = "Default Web Site"
            State        = "Stopped"
            PhysicalPath = "C:\inetpub\wwwroot"
            DependsOn    = "[WindowsFeature]IIS"
        }
        xWebsite newWebSite {
            Ensure       = "Present"
            Name         = "NewWebSite"
            State        = "Started"
            PhysicalPath = "C:\inetpub\wwwroot"
            BindingInfo  = @(
                MSFT_xWebBindingInformation {
                    Protocol = "HTTPS"
                    Port     = 8444
                    CertificateThumbprint = "9592668eb21d646184b1dc889c7f1acaf3c0a857"
                    CertificateStoreName = "WebHosting"
                }
                MSFT_xWebBindingInformation {
                    Protocol = "HTTPS"
                    Port     = 8443
                    CertificateThumbprint = "9592668eb21d646184b1dc889c7f1acaf3c0a857"
                    CertificateStoreName = "WebHosting"
                }
            )
            DependsOn    = @("[WindowsFeature]IIS","[Script]installCert")
        }
        xFirewall firewallRule{
            Name = "WebFirewallRule"
            DisplayName = "Firewall Rule to access Web Ports"
            Description = "Firewall Rule to access Web Ports"
            Ensure = "Present"
            Enabled = "True"
            Profile = ("Public","Private")
            Direction = "Inbound"
            LocalPort = ("8443", "8444")
            Protocol = "TCP"
            DependsOn = "[xWebsite]newWebSite"
        }
        Script installCert {
            TestScript = {
                if((Get-ChildItem Cert:\LocalMachine\WebHosting).Thumbprint -contains "9592668eb21d646184b1dc889c7f1acaf3c0a857"){return $true}
                else{return $false}
                }
            SetScript = {
                $psw = 'A123456789a!' | ConvertTo-SecureString -AsPlainText -Force
                $certPath = 'C:\Cert\azureiis.pfx'
                Import-PfxCertificate -FilePath $certPath -Password $psw -CertStoreLocation Cert:\LocalMachine\WebHosting -Exportable
                }
            GetScript = {
                $certs = Get-ChildItem -Path Cert:\LocalMachine\WebHosting -Recurse
                return @{result = $certs.Thumbprint}
                }
                DependsOn = "[xRemoteFile]copyCert"
        }
    }
}
  
