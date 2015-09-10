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
$DSCCompositeModuleName = ($EnvData.Prefix + 'CompositeDSCResources')
$CompanyDSCModuleName = ($EnvData.Prefix + 'DSCResources')


#region Copy DSC Resources from local Git repo to central UNC path

$Source = Join-Path -Path $UserData.LocalGitRepository -ChildPath Modules
$Destination = Join-Path -Path $EnvData.PowerShellDFSRoot -ChildPath DSC

Update-Folder -Source $Source -Destination $Destination -Verbose

#endregion

#region Copy DSC Configurations from local Git repo to central UNC path

$Source = Join-Path -Path $UserData.LocalGitRepository -ChildPath ($EnvData.Prefix + 'DSCConfigurations')
$Destination = Join-Path -Path $EnvData.PowerShellDFSRoot -ChildPath DSC\Configurations

Update-Folder -Source $Source -Destination $Destination


#endregion

#region Copy environment-data from local Git repo to central UNC path

$Source = Join-Path -Path $UserData.LocalGitRepository -ChildPath 'Environments'
$Destination = Join-Path -Path $EnvData.PowerShellDFSRoot -ChildPath DSC

Update-Folder -Source $Source -Destination $Destination


#endregion


#region Copy DSC Resource modules from local Git repo to central management server and SMA Runbook Worker
$nodes = @()
$nodes += $EnvData.SMAWorkerServers
$nodes += $EnvData.DSCManagementServers

foreach ($node in $nodes) {

$Source = Join-Path -Path $UserData.LocalGitRepository -ChildPath Modules\$DSCCompositeModuleName
$destination = "\\$node\c$\Program Files\WindowsPowerShell\Modules"


Update-Folder -Source $Source -Destination $Destination

}


foreach ($node in $nodes) {

$Source = Join-Path -Path $UserData.LocalGitRepository -ChildPath Modules\$CompanyDSCModuleName
$destination = "\\$node\c$\Program Files\WindowsPowerShell\Modules"

Update-Folder -Source $Source -Destination $Destination

}


foreach ($node in $nodes) {

$Source = Join-Path -Path $UserData.LocalGitRepository -ChildPath Modules\$DSCHelperModuleName
$destination = "\\$node\c$\Program Files\WindowsPowerShell\Modules"

Update-Folder -Source $Source -Destination $Destination

}


#endregion Update DSC Resource modules on central management server and SMA Runbook Worker

#region Publish DSC Resource module to Pull Server

$PullServer = $EnvData.PowerShellDSCPullServerFQDN
$PullServerModuleFolder = "\\$PullServer\c$\Program Files\WindowsPowerShell\DscService\Modules"
$ModulePath = (Resolve-Path -Path (Join-Path -Path $UserData.LocalGitRepository -ChildPath Modules\$CompanyDSCModuleName)).Path

Publish-DSCModule -ModulePath $ModulePath -PullServerModuleFolder $PullServerModuleFolder

#endregion Publish DSC Resource module