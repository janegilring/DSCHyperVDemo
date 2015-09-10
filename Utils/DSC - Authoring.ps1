#region Demo setup
Write-Warning 'This is a demo script which should be run line by line or sections at a time, stopping script execution'

break

<#

    Author:      Jan Egil Ring
    Description: This demo script is part of the presentation 
                 PowerShell Desired State Configuration – Real World Experiences
		 presented at PowerShell Summit Europe 2015
                 
#>

Import-Module -Name *DSCHelperModule -Force

$EnvData =  Get-EnvironmentData
$UserData =  $EnvData.Users | Where-Object {$PSItem.Username -eq $env:USERNAME -and $PSItem.UserDNSDomain -eq $env:USERDNSDOMAIN}

$DSCConfigurationPath = Join-Path -Path $UserData.LocalGitRepository -ChildPath ($EnvData.Prefix + 'DSCConfigurations')
$DSCHelperModuleName = $EnvData.Prefix + 'DSCHelperModule'
$DSCCompositeModuleName = ($EnvData.Prefix + 'CompositeDSCResources')
$CompanyDSCModuleName = ($EnvData.Prefix + 'DSCResources')


#region DSC Configurations

# Load Show-DscResource AddOn for PowerShell ISE (must be previously installed using Install-DscResourceAddOn in the module folder) Source: https://github.com/inchara/ShowDscResource
Install-DscResourceAddOn
$psISE.CurrentPowerShellTab.VerticalAddOnTools.Where({$PSItem.Name -eq 'Show-DscResource'}).ForEach({ $PSItem.IsVisible = $true })

# Load module files containing DSC configurations
Get-ChildItem -Path $DSCConfigurationPath -Filter *.psm1 -Recurse | foreach {psedit $_.FullName}

#endregion


#region Composite DSC Resources

New-DSCCompositeResource -ModuleName $DSCCompositeModuleName -ResourceName ($EnvData.Prefix + 'BaseCompositeDSCResource')
New-DSCCompositeResource -ModuleName $DSCCompositeModuleName -ResourceName ($EnvData.Prefix + 'HYPCompositeDSCResource')
New-DSCCompositeResource -ModuleName $DSCCompositeModuleName -ResourceName ($EnvData.Prefix + 'HPCompositeDSCResource')
New-DSCCompositeResource -ModuleName $DSCCompositeModuleName -ResourceName ($EnvData.Prefix + 'SOFSCompositeDSCResource')

#endregion


#region DSC Resources

# PowerShell DSC Resource Design and Testing Checklist
# http://blogs.msdn.com/b/powershell/archive/2014/11/18/powershell-dsc-resource-design-and-testing-checklist.aspx

Find-Module -Name xDSCResourceDesigner | Install-Module -Force

Import-Module xDSCResourceDesigner

Get-Command -Module xDSCResourceDesigner

New-Item -Path "$env:ProgramFiles\WindowsPowerShell\Modules" -Name $CompanyDSCModuleName -ItemType Directory

New-ModuleManifest -Path "$env:ProgramFiles\WindowsPowerShell\Modules\$CompanyDSCModuleName\$CompanyDSCModuleName.psd1" -Guid (([guid]::NewGuid()).Guid) -Author 'Jan Egil Ring' -CompanyName $EnvData.CompanyName -ModuleVersion 1.0 -Description 'DSC Resource Module for $($EnvData.CompanyName)' -PowerShellVersion 4.0 -FunctionsToExport '*.TargetResource'

# Define DSC parameters 
$DataCollectorSetName = New-xDscResourceProperty -Type String -Name DataCollectorSetName -Attribute Key
$Ensure = New-xDscResourceProperty -Name Ensure -Type String -Attribute Write -ValidateSet 'Present', 'Absent'
$XmlTemplatePath = New-xDscResourceProperty -Name XmlTemplatePath -Type String -Attribute Required

# Create the DSC resource 
New-xDscResource -Name Logman -Property $DataCollectorSet,$Ensure,$XmlTemplatePath -Path "$env:ProgramFiles\WindowsPowerShell\Modules\TineDSCResources" -ClassVersion 1.0 -FriendlyName Logman -Force

tree /a /f "$env:ProgramFiles\WindowsPowerShell\Modules\$CompanyDSCModuleName"

$XmlTemplatePath = New-xDscResourceProperty -Name XmlTemplatePath -Type String -Attribute Required
Update-xDscResource -Property $DataCollectorSetName,$Ensure,$XmlTemplatePath  -Path "$env:ProgramFiles\WindowsPowerShell\Modules\$CompanyDSCModuleName\DSCResources\Logman" -Force


# V5

New-Item -Path "$env:ProgramFiles\WindowsPowerShell\Modules" -Name PSCommunityDSCClassBasedResources -ItemType Directory

New-ModuleManifest -Path "$env:ProgramFiles\WindowsPowerShell\Modules\PSCommunityDSCClassBasedResources\PSCommunityDSCClassBasedResources.psd1" -Guid (New-Guid).Guid -Author 'Jan Egil Ring' -CompanyName PSCommunity -ModuleVersion 1.0 -Description 'Example class based DSC Resource module for PSCommunity' -PowerShellVersion 5.0 -DscResourcesToExport * -RootModule PSCommunityDSCClassBasedResources.psm1

New-Item -Path "$env:ProgramFiles\WindowsPowerShell\Modules\PSCommunityDSCClassBasedResources" -Name PSCommunityDSCClassBasedResources.psm1 -ItemType File

Get-DscResource -Module *DSCResource


Publish-Module -Name Logman -NuGetApiKey xxxxx

#endregion