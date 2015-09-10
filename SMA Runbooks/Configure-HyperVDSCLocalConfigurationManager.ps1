workflow Configure-HyperVDSCLocalConfigurationManager {

    param (
    [Parameter(Mandatory=$false)]
    [string]$InstanceCode,
    [string]$RBID
    )

#region Define variables
$TargetNodeCred = Get-AutomationPSCredential -Name CrayonPowerShellDSCNodeCredential
$DSCPullServerURL = Get-AutomationVariable -Name CrayonPowerShellDSCPullServerUrl
$DSCStagingFolder = Get-AutomationVariable -Name CrayonPowerShellDSCStagingFolder
$DSCConfigurationModules = Get-AutomationVariable -Name CrayonPowerShellDSCConfigurationModules
$DSCHelperModule = Get-AutomationVariable -Name CrayonPowerShellDSCHelperModule
$DSCPublicKeys = Get-AutomationVariable -Name CrayonPowerShellDSCPublicKeys

if ($RBID)
  {


    Write-Verbose -Message '$RBID specified, getting instance parameters from System Center Service Manager'
  
    $SCSMVariables = Get-SCSMRBInput -RBID $RBID
    $InstanceCode = $SCSMVariables.UserInputAnswerValue
    Write-Verbose -Message "Instancecode from SCSM is $InstanceCode"
  
    $instanceVariables = Get-SCSMHyperVInstanceParameters -InstanceCode $InstanceCode -ErrorAction Stop
    $ParametersFromSCSM = $true

  } else {

    Write-Verbose -Message '$RBID not specified, getting instance parameters from JSON-file'
  $instanceVariables = Get-HyperVInstanceParameters -InstanceCode $InstanceCode -erroraction Stop
  $ParametersFromSCSM = $false

  }

#endregion

inlinescript {

#region Import custom DSC Configurations

# Bypass execution policy in order to import DSC configuration module from UNC path
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# Import module where DSC helper functions is defined
Get-ChildItem -Path (Join-Path -Path $using:DSCHelperModule -ChildPath '*.psm1') -Recurse | ForEach-Object -Process {Import-Module -Name $_.FullName}

# Import module where DSC configurations is defined
Get-ChildItem -Path (Join-Path -Path $using:DSCConfigurationModules -ChildPath '*.psm1') -Recurse | ForEach-Object -Process {Import-Module -Name $_.FullName}

#endregion

#region Configure LCM

foreach ($VMHost in $using:instanceVariables.Hosts) {

if (Test-PsRemoting -computername $VMHost.Hostname -credential $using:TargetNodeCred) {

$thumbprint = Get-EncryptionCertificate -computerName $VMHost.Hostname -publicKeyFolder $using:DSCPublicKeys -credential $using:TargetNodeCred

} else {

Write-Output -InputObject "Unable to connect to $($VMHost.Hostname) using PowerShell Remoting, encryption certificate cannot be obtained"
continue

}

# Verify that LCM configuration is imported

if (-not (Get-Command -Name DSCLCMPullSettings -CommandType Configuration)){

throw "DSC Configuration DSCLCMPullSettings not available, verify that it`s defined in a module inside $($using:DSCConfigurationModules)"

}

# Generate the new LCM configuration
DSCLCMPullSettings -NodeName $VMHost.Hostname -ConfigurationID $VMHost.Nodename -CertificateID $thumbprint -PullServerURL $using:DSCPullServerURL  -OutputPath $using:DSCStagingFolder | Out-Null

# Apply the new LCM configuration
Set-DscLocalConfigurationManager -ComputerName $VMHost.Hostname -Path $using:DSCStagingFolder -Credential $using:TargetNodeCred

#Trigger node to pull configuration from pull server

try {


Write-Verbose -Message 'Invoking Update-DscConfiguration on $($VMHost.Hostname)'

if (Test-PsRemoting -computername $VMHost.Hostname -credential $using:TargetNodeCred) {

# Due to a bug in Update-DscConfiguration, using alternate credentials doesn`t work
#Update-DscConfiguration -ComputerName $VMHost.Hostname -Credential $using:TargetNodeCred -Wait -ErrorAction Stop

# Using PowerShell Remoting as workaround
Invoke-Command -ComputerName $VMHost.Hostname -Credential $using:TargetNodeCred -ScriptBlock {

Update-DscConfiguration -Wait

} -ErrorAction Stop

} else {

Write-Output -InputObject "Unable to connect to $($VMHost.Hostname) using PS Remoting, DSC configuration update cannot be triggered"

}



}

catch {


Write-Verbose -Message 'Update-DscConfiguration failed, possibly due to node not available'

Write-Verbose $Error[0].Exception

Write-Output -InputObject 'Update-DscConfiguration failed, possibly due to node not available'

}

Write-Output -InputObject "Processed DSC node $($VMHost.Hostname)"

}

#endregion





    }


}