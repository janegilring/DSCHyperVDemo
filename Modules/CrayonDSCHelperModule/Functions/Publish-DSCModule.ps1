function Publish-DSCModule
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$true)]
    [string]
    $ModulePath,
    
    [Parameter(Mandatory=$false)]
    [string]
    $PullServerModuleFolder
  )
  

$ModuleFile = New-DscZipFile -ZipFile $ModulePath -Path $ModulePath -Force

Copy-Item -Path $ModuleFile.FullName -Destination $PullServerModuleFolder -Force
New-DSCCheckSum -ConfigurationPath $ModuleFile.FullName -OutPath $PullServerModuleFolder -Force
  
  
}