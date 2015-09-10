Configuration CrayonHPCompositeDSCResource {
Param(
$HPWBEMProviderSourcePath
)


Import-DscResource -ModuleName CrayonDSCResources


WindowsFeature SNMPService {

Name = 'SNMP-Service'
Ensure = 'Present'

}

WindowsFeature SNMPRSAT {

Name = 'RSAT-SNMP'
Ensure = 'Present'
DependsOn = '[WindowsFeature]SNMPService'

}

SNMPEnableAuthenticationTrap TrapEnable {
            EnableAuthenticationTraps = '1'
            Ensure = 'Present'
            DependsOn = '[WindowsFeature]SNMPRSAT'
        }


SNMPCommunity HPSIM {
 
            Community = 'public'
            Right = 'ReadOnly'
            Ensure = 'Present'
            DependsOn = '[WindowsFeature]SNMPRSAT'

}

SNMPTrapCommunity HPSIM {
 
            Community = 'public'
            Ensure = 'Present'
            DependsOn = '[WindowsFeature]SNMPRSAT'

}

SNMPTrapDestination HPSIM {
 
            Community = 'public'
            Destination = '10.230.20.30'
            Ensure = 'Present'
            DependsOn = '[SNMPTrapCommunity]HPSIM'

}

Package HPWBEMProviders {
            
            Name = 'HP Insight Management WBEM Providers'
            Ensure = 'Present'
            ProductId = 'D948928E-B5A3-4932-82E2-2E0FA0C3E800'
            Path = $HPWBEMProviderSourcePath
            Arguments = '/silent'
            ReturnCode = '1'

}

}