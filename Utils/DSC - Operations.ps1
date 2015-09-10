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

Import-Module -Name ~\Git\xDscDiagnostics\xDscDiagnostics.psm1

#region DSC LCM

$computername = 'DEMOHYPER01'

Get-DscLocalConfigurationManager -CimSession $computername
Get-DscLocalConfigurationManager -CimSession $computername | Select-Object -ExpandProperty DownloadManagerCustomData
Get-DscConfiguration -CimSession $computername
Test-DscConfiguration -CimSession $computername -Verbose

Update-xDscEventLogStatus -Channel Analytic -Status Enabled -ComputerName $computername
Update-xDscEventLogStatus -Channel Debug -Status Enabled  -ComputerName $computername

Get-NetAdapter -CimSession $computername -Name 'vEthernet (Management)' | Disable-NetAdapter -Confirm:$false
Update-DscConfiguration -ComputerName $computername -Wait -Verbose


Invoke-Command -ComputerName $computername -ScriptBlock {Get-NetFirewallRule *event* | Enable-NetFirewallRule}

Get-xDscOperation -Newest 10 -ComputerName $computername

Trace-xDscOperation -ComputerName $computername -JobId c845b5d3-3f2b-11e5-80d0-001e4ffed296

Trace-xDscOperation -ComputerName $computername -SequenceID 1 | Out-GridView

Restart-Computer -ComputerName $computername -Wait -For PowerShell -Force

#endregion

#region DSC Pull Server

Get-DSCPullServerNodeStatus -PullServerUri $EnvData.PowerShellDSCPullServerComplianceUri | Sort-Object LastHeartbeat | Select-Object Hostname, TargetName, ConfigurationId, NodeCompliant, LastCompliance, StatusCode, StatusMessage, LastHeartbeat | Out-GridView

#endregion