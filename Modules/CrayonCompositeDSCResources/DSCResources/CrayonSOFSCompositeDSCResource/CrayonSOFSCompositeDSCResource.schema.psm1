Configuration CrayonSOFSCompositeDSCResource {
param (
[PSCredential]$DomainLDAPcred,
[string]$LogmanDataCollectorSetName,
[string]$LogmanXmlTemplatePath
)

Import-DscResource -ModuleName CrayonDSCResources

PowerPlan Crayon {

Name = 'High Performance'
Ensure = 'Present'


}


WindowsFeature CrayonFileServer {

Name = 'FS-FileServer'
Ensure = 'Present'

}

WindowsFeature CrayonFileServerDedup {

Name = 'FS-Data-Deduplication'
Ensure = 'Present'

}

WindowsFeature CrayonFSVSSAgent {

Name = 'FS-VSS-Agent'
Ensure = 'Present'

}

WindowsFeature CrayonMPIO {

Name = 'Multipath-IO'
Ensure = 'Present'

}

WindowsFeature CrayonRDC {

Name = 'RDC'
Ensure = 'Present'

}


Registry DisableTrimUnmap {

    Ensure = 'Present'
    Key = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem'
    ValueName = 'DisableDeleteNotification'
    ValueData = '1'
    ValueType = 'Dword'
    Force = $true

}

Logman CrayonSOFS {

DataCollectorSetName = $LogmanDataCollectorSetName
Ensure = 'Present'
XmlTemplatePath = $LogmanXmlTemplatePath

}

}