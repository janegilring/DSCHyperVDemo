function Update-Folder
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$true)]
    [string]
    $Source,
    
    [Parameter(Mandatory=$true)]
    [string]
    $Destination
  )


try {  

if (!(Test-Path $Destination))
{
        throw "Could not find $Destination"

} else {

$ChildPath = Split-Path -Path $Source -Leaf -ErrorAction Stop

$DestinationChildPath = Join-Path -Path $Destination -ChildPath $ChildPath

if (Test-Path $DestinationChildPath) {

Remove-Item -Path (Join-Path -Path $Destination -ChildPath $ChildPath) -Recurse -Force -ErrorAction Stop

}

}

if (!(Test-Path $Source))
{
        throw "Could not find $Source"
}

Write-Verbose -Message "Copying from $Source to $Destination"
Copy-Item -Path $Source -Destination $Destination -Force -Recurse -ErrorAction Stop

}

catch {

Write-Output -InputObject "An error occured, exception:"
$_.Exception

} 
 
  
}