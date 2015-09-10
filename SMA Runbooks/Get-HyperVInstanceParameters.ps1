workflow Get-HyperVInstanceParameters
{
    param (
    [Parameter(Mandatory=$true)]
    [string]$InstanceCode
    )

    $Share = Get-AutomationVariable -Name "Var-CrayonDemoSiteHyperVParametersShare"
    $jsonpath = Join-Path -path $share -childpath "$InstanceCode.json"
    if (!(test-path $jsonpath))
    {
        throw "Could not find file"
    }

    $returnobj = get-content $jsonpath -Raw | ConvertFrom-Json
    $returnobj
}
