#region Demo setup
Write-Warning 'This is a demo script which should be run line by line or sections at a time, stopping script execution'

break

<#

    Author:      Jan Egil Ring
    Description: This demo script is part of the presentation 
                 PowerShell Desired State Configuration – Real World Experiences
		 presented at PowerShell Summit Europe 2015
                 
#>

dir '~\Git\CrayonDemo-DSC-Hyper-V\Modules\CrayonCompositeDSCResources\DSCResources\CustomerA*' -Recurse | foreach {

$new = $_.Name -replace 'CustomerA','Crayon'
$new

Rename-Item -Path $_.FullName -NewName $new

}



dir '~\Git\CrayonDemo-DSC-Hyper-V\Modules\CrayonCompositeDSCResources' -Filter CustomerA* -Recurse | foreach {

$new = $_.Name -replace 'CustomerA','Crayon'
$new

Rename-Item -Path $_.FullName -NewName $new

}