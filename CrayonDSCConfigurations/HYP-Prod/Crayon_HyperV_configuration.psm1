configuration CrayonHyperVHost {

param (
[PSCredential]$DSCLDAPCredential 
)

Import-DscResource -ModuleName CrayonCompositeDSCResources,CrayonDSCResources

node $AllNodes.NodeName {


#region Base OS Config

CrayonBaseCompositeDSCResource HyperV {

            WindowsUpdateMode = 'DownloadOnly'

     }

#endregion

#region Hyper-V config

CrayonHYPCompositeDSCResource HyperV {

            LocalAdministrators = $node.LocalAdministrators
            LocalHyperVAdministrators = $node.LocalHyperVAdministrators
            DomainLDAPcred = $DSCLDAPCredential
            VirtualDiskPath = $node.HyperVVirtualDiskPath
            VirtualMachinePath = $node.HyperVVirtualMachinePath
            LogmanDataCollectorSetName = $ConfigurationData.NonNodeData.HyperVPerfMonName
            LogmanXmlTemplatePath = $ConfigurationData.NonNodeData.HyperVPerfMonTemplatePath

}

Group CrayonLocalAdmins {

GroupName = 'Administrators'
MembersToInclude = $node.LocalAdministrators
Ensure = 'Present'
Credential = $DSCLDAPCredential

}

Group CrayonHyperVAdmins {

GroupName = 'Hyper-V Administrators'
MembersToInclude = $node.LocalHyperVAdministrators
Ensure = 'Present'
Credential = $DSCLDAPCredential

}

#endregion

#region Failover Clustering config

if ($node.IsClusterNode -eq 'True') {

WindowsFeature CrayonFailoverClustering  {

Name = 'Failover-Clustering'
Ensure = 'Present'
DependsOn = '[WindowsFeature]CrayonHyperV'

}

WindowsFeature CrayonFailoverClusteringRSAT  {

Name = 'RSAT-Clustering'
Ensure = 'Present'
DependsOn = '[WindowsFeature]CrayonHyperV'

}


}

#endregion

#region HP config

if ($node.HardwareModel -Like "HP*") {

CrayonHPCompositeDSCResource HyperV {

        HPWBEMProviderSourcePath = $ConfigurationData.NonNodeData.HPWBEMProviderSource

  }

}

#endregion

} #end node

}