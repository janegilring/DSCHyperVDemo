Configuration CrayonHYPCompositeDSCResource {
param (
[PSCredential]$DomainLDAPcred,
[string]$LocalAdministrators,
[string]$LocalHyperVAdministrators,
[string]$VirtualMachinePath,
[string]$VirtualDiskPath,
[string]$LogmanDataCollectorSetName,
[string]$LogmanXmlTemplatePath
)

Import-DscResource -ModuleName CrayonDSCResources

PowerPlan CrayonHyperV {

Name = 'High Performance'
Ensure = 'Present'


}


WindowsFeature CrayonHyperV {

Name = 'Hyper-V'
Ensure = 'Present'

}


WindowsFeature CrayonHyperVRSAT {

Name = 'RSAT-Hyper-V-Tools'
Ensure = 'Present'
DependsOn = '[WindowsFeature]CrayonHyperV'

}

WindowsFeature CrayonHyperVRSATPowerShell {

Name = 'Hyper-V-PowerShell'
Ensure = 'Present'
DependsOn = '[WindowsFeature]CrayonHyperV'

}

<#
Group CrayonLocalAdmins {

GroupName = 'Administrators'
MembersToInclude = $LocalAdministrators
Ensure = 'Present'
Credential = $DomainLDAPcred

}

Group CrayonHyperVAdmins {

GroupName = 'Hyper-V Administrators'
MembersToInclude = $LocalHyperVAdministrators
Ensure = 'Present'
Credential = $DomainLDAPcred

}
#>

Uac CrayonHyperV {

Setting = 'NeverNotifyAndDisableAll'

}

if (-not ($VirtualMachinePath)) {

    $VirtualMachinePath = 'C:\Hyper-V'  

} 

if (-not ($VirtualDiskPath)) {

    $VirtualDiskPath = 'C:\Hyper-V'  

}

VMHost CrayonHyperVHost {

    VMHost = 'localhost'
    Ensure = 'Present'
    EnhancedSessionMode = $true
    VirtualMachineMigration = $true
    MaximumVirtualMachineMigrations = 4
    MaximumStorageMigrations = 2
    VirtualMachinePath = $VirtualMachinePath 
    VirtualDiskPath = $VirtualDiskPath
    DependsOn = '[WindowsFeature]CrayonHyperVRSATPowerShell'

}

Logman CrayonHyperV {

DataCollectorSetName = $LogmanDataCollectorSetName
Ensure = 'Present'
XmlTemplatePath = $LogmanXmlTemplatePath

}

}