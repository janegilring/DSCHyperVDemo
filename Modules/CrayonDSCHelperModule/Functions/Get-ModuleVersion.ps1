# Get-ModuleVersion copied from https://github.com/PowerShellOrg/DSC
function Get-ModuleVersion
{
    param (
        [parameter(mandatory)]
        [validatenotnullorempty()]
        [string]
        $path, 
        [switch]
        $asVersion
    )
    $ModuleName = split-path $path -Leaf
    $ModulePSD1 = join-path $path "$ModuleName.psd1"
    
    Write-Verbose ''
    Write-Verbose "Checking for $ModulePSD1"
    if (Test-Path $ModulePSD1)
    {
        $psd1 = get-content $ModulePSD1 -Raw        
        $Version = (Invoke-Expression -Command $psd1)['ModuleVersion']
        Write-Verbose "Found version $Version for $ModuleName."
        Write-Verbose ''
        if ($asVersion) {
            [Version]::parse($Version)
        }
        else {            
            return $Version
        }   
    }
    else
    {
        Write-Warning "Could not find a PSD1 for $modulename at $ModulePSD1."        
    }
}