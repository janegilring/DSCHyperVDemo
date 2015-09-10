### Example configuration referencing the new composite resource
Configuration aaaaaa {
    
    Import-DscResource -ModuleName TineCompositeDSCResources

    Node localhost {

        TineSOFSCompositeDSCResource bbbbbb {
            property = value
        }

    }
}