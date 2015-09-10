### Example configuration referencing the new composite resource
Configuration aaaaaa {
    
    Import-DscResource -ModuleName TineCompositeDSCResources

    Node localhost {

        TineHPCompositeDSCResource HyperV {
            HPWBEMProviderSourcePath = $ConfigurationData.NonNodeData.HPWBEMProviderSource
        }

    }
}