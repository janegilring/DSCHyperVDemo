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
$DSCHelperModuleName = $EnvData.Prefix + 'DSCHelperModule'
$CompanyDSCModuleName = ($EnvData.Prefix + 'DSCResources')

Import-Module -Name Microsoft.SystemCenter.ServiceManagementAutomation

$cred = Import-Clixml "$env:temp\$($env:COMPUTERNAME).cred.xml"

$WebServiceEndpoint = $EnvData.SMAWebServiceEndpoint

$PSDefaultParameterValues.Add("*SMA*:WebServiceEndpoint",$WebServiceEndpoint)
$PSDefaultParameterValues.Add("*SMA*:credential",$cred)

$credexport = Get-Credential
$credexport | Export-Clixml -Path "$env:temp\$($env:COMPUTERNAME).cred.xml"

# Sync runbooks
psedit (Join-Path -Path $UserData.LocalGitRepository -ChildPath 'Utils\Sync-Runbooks.ps1')


$id = Start-SmaRunbook -Name "Deploy-HyperVDSCConfiguration" -Parameters @{InstanceCode="HYP100A"} #JSON-input
$id = Start-SmaRunbook -Name "Deploy-HyperVDSCConfiguration" -Parameters @{RBID="RB35986"} #SCSM-input
$id = Start-SmaRunbook -Name "Configure-HyperVDSCLocalConfigurationManager" -Parameters @{InstanceCode="HYP100A"} #JSON-input
$id = Start-SmaRunbook -Name "Configure-HyperVDSCLocalConfigurationManager" -Parameters @{RBID="RB35986"} #SCSM-input

Get-SmaJob -Id $id
Get-SmaJobOutput -Stream Any -Id $id

$latestjob = Get-SmaJob -RunbookName Invoke-WrapperDeployINstanceVMs | select -First 1
Get-SmaJobOutput -Stream Any -Id $latestjob.JobId.Guid | sort streamtime | select -last 5 | select streamtime,streamtext | ogv

($EnvData.Prefix + '')
Set-SmaVariable -Name ($EnvData.Prefix + 'PowerShellDSCPullServerUrl') -Value $EnvData.PowerShellDSCPullServerUrl

Set-SmaVariable -Name ($EnvData.Prefix + 'PowerShellDSCPullServer') -Value $EnvData.PowerShellDSCPullServerFQDN

Set-SmaVariable -Name ($EnvData.Prefix + 'PowerShellDSCStagingFolder') -Value (Join-Path -Path $EnvData.PowerShellDFSRoot -ChildPath DSC\Staging)

$DSCConfigurationPath = Join-Path -Path $EnvData.PowerShellDFSRoot -ChildPath ('DSC\Configurations\' + ($EnvData.Prefix + 'DSCConfigurations'))
Set-SmaVariable -Name ($EnvData.Prefix + 'PowerShellDSCConfigurationModules') -Value $DSCConfigurationPath

Set-SmaVariable -Name ($EnvData.Prefix + 'PowerShellDSCHelperModule ') -Value (Join-Path -Path $EnvData.PowerShellDFSRoot -ChildPath DSC\Modules\$DSCHelperModuleName)

Set-SmaVariable -Name ($EnvData.Prefix + 'PowerShellDSCPublicKeys') -Value (Join-Path -Path $EnvData.PowerShellDFSRoot -ChildPath DSC\PublicKeys)

Set-SmaVariable -Name ($EnvData.Prefix + 'PowerShellDSCJSONInput') -Value (Join-Path -Path $EnvData.PowerShellDFSRoot -ChildPath SMA\Input)


$DSCHyperVConfigurationData = Join-Path -Path $EnvData.PowerShellDFSRoot -ChildPath ('DSC\Environments\ConfigData\' + ('HYP-' + $EnvData.EnvironmentName + '.psd1'))


Set-SmaVariable -Name ($EnvData.Prefix + 'PowerShellDSCHyperVConfigurationData') -Value $DSCHyperVConfigurationData

Set-SmaVariable -Name ($EnvData.Prefix + 'PowerShellDSCLDAPCredential')

Set-SmaVariable -Name ($EnvData.Prefix + 'PowerShellDSCNodeCredential')