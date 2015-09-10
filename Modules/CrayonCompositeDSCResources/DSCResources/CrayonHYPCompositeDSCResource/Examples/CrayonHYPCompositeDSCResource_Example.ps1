### Example configuration referencing the new composite resource
Configuration TineHyperV {

param (
[PSCredential]$cred
)

    
    Import-DscResource -ModuleName TineCompositeDSCResources

    Node $AllNodes.NodeName {

        TineHYPCompositeDSCResource HyperV {
            LocalAdministrators = 'TINE\Tine_Hyper-V_Admins'
            DomainLDAPcred = $cred
        }

    }
}



$ConfigData = @{
    AllNodes = @(
        @{
            NodeName                    = '*'
            PSDscAllowPlainTextPassword = $True
        }
        @{
            NodeName     = 'dsc-01'
            DomainName   = 'example.com'
        }

    )
}

TineHyperV -cred $cred -OutputPath H:\temp -ConfigurationData $ConfigData