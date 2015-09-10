#region Demo setup
Write-Warning 'This is a demo script which should be run line by line or sections at a time, stopping script execution'

break

<#

    Author:      Jan Egil Ring
    Description: This demo script is part of the presentation 
                 PowerShell Desired State Configuration – Real World Experiences
		 presented at PowerShell Summit Europe 2015
                 
#>

$EnvData =  Get-EnvironmentData
$UserData =  $EnvData.Users | Where-Object {$PSItem.Username -eq $env:USERNAME -and $PSItem.UserDNSDomain -eq $env:USERDNSDOMAIN}

$DSCHyperVConfigurationData = Join-Path -Path $UserData.LocalGitRepository -ChildPath ('Environments\ConfigData\' + ('HYP-' + $EnvData.EnvironmentName + '.psd1'))

$ConfigData = @{

        AllNodes = @()
        NonNodeData=@{}

}

$ConfigData.AllNodes += @{

    NodeName = "*"
    DNSServerAddresses = $EnvData.DNSServerAddresses

}

$ConfigData.NonNodeData += 
    @{
        HPWBEMProviderSource = $EnvData.HPWBEMProviderSource
        EMCPowerPathSource = $EnvData.EMCPowerPathSource
        HyperVPerfMonName = $EnvData.HyperVPerfMonName
        HyperVPerfMonTemplatePath = $EnvData.HyperVPerfMonTemplatePath
     }






$ConfigData | ConvertTo-Json | Out-File -FilePath $DSCHyperVConfigurationData