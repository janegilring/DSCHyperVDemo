### Example configuration referencing the new composite resource
Configuration TineBase {

param (
[PSCredential]$cred
)

    
    Import-DscResource -ModuleName TineCompositeDSCResources

    Node $AllNodes.NodeName {

        TineBaseCompositeDSCResource HyperV {

       
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

TineBase -cred $cred -OutputPath H:\temp -ConfigurationData $ConfigData