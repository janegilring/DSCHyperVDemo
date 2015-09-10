workflow Deploy-HyperVDSCConfiguration {

    param (
    [Parameter(Mandatory=$false)]
    [string]$InstanceCode,
    [string]$RBID
    )


#region Define variables
$TargetNodeCred = Get-AutomationPSCredential -Name CrayonPowerShellDSCNodeCredential
$DSCLDAPCredential = Get-AutomationPSCredential -Name CrayonPowerShellDSCLDAPCredential
$DSCConfigurationModules = Get-AutomationVariable -Name CrayonPowerShellDSCConfigurationModules
$DSCHyperVConfigurationData = Get-AutomationVariable -Name CrayonPowerShellDSCHyperVConfigurationData
$DSCHelperModule = Get-AutomationVariable -Name CrayonPowerShellDSCHelperModule
$DSCPullServer = Get-AutomationVariable -Name CrayonPowerShellDSCPullServer
$DSCPullServerConfigFolder = "\\$DSCPullServer\c$\Program Files\WindowsPowerShell\DscService\Configuration"


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


$DSCPublicKeys = Get-AutomationVariable -Name CrayonPowerShellDSCPublicKeys

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


#region Generating DSC ConfigData

Write-Verbose -Message 'Generating DSC ConfigData...'

if (-not (Test-Path -Path $using:DSCHyperVConfigurationData))
{
    throw "Could not find file $($using:DSCHyperVConfigurationData)"
}

$JsonData = Get-Content -Path $using:DSCHyperVConfigurationData -Raw | ConvertFrom-Json

$ConfigData = ConvertTo-DscConfigData -JsonData $JsonData



foreach ($VMHost in $using:instanceVariables.Hosts) {

$ht = @{}

if (Test-PsRemoting -computername $VMHost.Hostname -credential $using:TargetNodeCred) {

$thumbprint = Get-EncryptionCertificate -computerName $VMHost.Hostname -publicKeyFolder $using:DSCPublicKeys -credential $using:TargetNodeCred

  $VMHost.psobject.properties | Foreach { $ht[$_.Name] = $_.Value }

  $ht.CertificateFile = (Join-Path -Path $using:DSCPublicKeys -ChildPath ($VMHost.Hostname + '.cer'))
  $ht.Thumbprint = $thumbprint
  
  # If input from SCSM, add SCSM object ID as nodename
  if ($using:ParametersFromSCSM){

  $ht.Nodename = $($ht.'#ID'.ToString())

  }

  
  $ConfigData.AllNodes +=   $ht

} else {

Write-Output -InputObject "Unable to connect to $($VMHost.Hostname) using PowerShell Remoting, encryption certificate cannot be obtained"

continue

}
  





}

#endregion

#region Generate DSC configuration

Write-Verbose -Message 'Generating DSC configuration documents...'

# Verify that LCM configuration is imported

if (-not (Get-Command -Name CrayonHyperVHost -CommandType Configuration)){

throw "DSC Configuration CrayonHyperVHost not available, verify that it`s defined in a module inside $($using:DSCConfigurationModules)"

}


if ($ConfigData.AllNodes.Count -gt 1) {

CrayonHyperVHost -ConfigurationData $ConfigData -DSCLDAPCredential $using:DSCLDAPCredential -OutputPath $using:DSCPullServerConfigFolder | Out-Null

#region Generate DSC checksum

$VMHosts = $ConfigData.AllNodes.Where({$PSItem.NodeName -ne '*'})

foreach ($VMHost in $VMHosts) {

$ConfigurationPath = Join-Path -Path $using:DSCPullServerConfigFolder -ChildPath ($($VMHost.Nodename) + '.mof')

Write-Verbose -Message "Generating DSC Checksum for MOF-file $($ConfigurationPath)"

New-DSCCheckSum -ConfigurationPath $ConfigurationPath -OutPath $using:DSCPullServerConfigFolder -Force

Write-Output -InputObject "Processed DSC node $($VMHost.Hostname)"

}

#endregion


} else {

Write-Output -InputObject 'No nodes added to $ConfigData, skipping DSC configuration generation'

}

#endregion


} -PSComputerName DEMOWAP01.demo.crayon.com -PSCredential $TargetNodeCred -PSAuthentication CredSSP

}