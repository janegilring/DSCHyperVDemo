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

$StagingFolder = (Join-Path -Path $EnvData.PowerShellDFSRoot -ChildPath DSC\Staging)

# Configure Pull Server LCM
$PullServer = $EnvData.PowerShellDSCPullServerFQDN
Get-DscLocalConfigurationManager -CimSession $PullServer

# Define configuration
Configuration PullServerLCM {
    param(
        [Parameter(Mandatory)]
        $ComputerName
    )
    Node $computerName {
        LocalConfigurationManager {
            ConfigurationID = $null
            ConfigurationMode="ApplyandAutoCorrect"
            ConfigurationModeFrequencyMins = 30
            RebootNodeIfNeeded = $True
            RefreshFrequencyMins = 15
            RefreshMode = "PUSH"
            AllowModuleOverwrite = $True
            DownloadManagerCustomData = $null
            DownloadManagerName = $null
        }
    }
}

# Generate configuration
PullServerLCM -ComputerName $PullServer -OutputPath $StagingFolder

# Apply configuration
Set-DscLocalConfigurationManager -ComputerName $PullServer -Path $StagingFolder -Verbose

# Inspect updated DSC LCM configuration
Get-DscLocalConfigurationManager -CimSession $PullServer

# Inspect current DSC Pull Server configuration
Get-WindowsFeature -ComputerName $PullServer -Name DSC-Service
dir \\$PullServer\c$\inetpub\wwwroot
dir "\\$PullServer\c$\Program Files\WindowsPowerShell" -Recurse

# Configure Pull Server
Copy-Item -Path '~\Git\xDscResources\xDscResources\xPSDesiredStateConfiguration' -Destination "\\$PullServer\c$\Program Files\WindowsPowerShell\Modules" -Recurse -Force
Copy-Item -Path '~\Git\xDscResources\xDscResources\xPSDesiredStateConfiguration' -Destination 'C:\Program Files\WindowsPowerShell\Modules' -Recurse -Force


# Note: A Certificate may be generated using MakeCert.exe: http://msdn.microsoft.com/en-us/library/windows/desktop/aa386968 
 
configuration Assert_DemoDscWebService 
{ 
    param  
    ( 
        [string[]]$NodeName = 'localhost', 
 
        [ValidateNotNullOrEmpty()] 
        [string] $certificateThumbPrint 
    ) 
 
    Import-DSCResource -ModuleName xPSDesiredStateConfiguration
 
    Node $NodeName 
    { 
        WindowsFeature DSCServiceFeature 
        { 
            Ensure = "Present" 
            Name   = "DSC-Service"             
        } 
 
        xDscWebService PSDSCPullServer 
        { 
            Ensure                  = "Present" 
            EndpointName            = "PSDSCPullServer" 
            Port                    = 8080 
            PhysicalPath            = "$env:SystemDrive\inetpub\wwwroot\PSDSCPullServer" 
            CertificateThumbPrint   = $certificateThumbPrint          
            ModulePath              = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Modules" 
            ConfigurationPath       = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Configuration"             
            State                   = "Started" 
            DependsOn               = "[WindowsFeature]DSCServiceFeature"                         
        } 
 
        xDscWebService PSDSCComplianceServer 
        { 
            Ensure                  = "Present" 
            EndpointName            = "PSDSCComplianceServer" 
            Port                    = 9080 
            PhysicalPath            = "$env:SystemDrive\inetpub\wwwroot\PSDSCComplianceServer" 
            CertificateThumbPrint   = "AllowUnencryptedTraffic" 
            State                   = "Started" 
            IsComplianceServer      = $true 
            DependsOn               = @("[WindowsFeature]DSCServiceFeature","[xDSCWebService]PSDSCPullServer") 
        } 
    } 
}

# Generate configuration
Assert_DemoDscWebService -NodeName $PullServer -certificateThumbPrint $EnvData.PowerShellDSCPullServerCertificateThumbprint -OutputPath $StagingFolder

# Apply configuration
Start-DscConfiguration -ComputerName $PullServer -Path $StagingFolder -Verbose -Wait

# Inspect updated DSC configuration
Get-DscConfiguration -CimSession $PullServer

# Inspect current DSC Pull Server configuration
Get-WindowsFeature -ComputerName $PullServer -Name DSC-Service
dir \\$PullServer\c$\inetpub\wwwroot
dir "\\$PullServer\c$\Program Files\WindowsPowerShell"