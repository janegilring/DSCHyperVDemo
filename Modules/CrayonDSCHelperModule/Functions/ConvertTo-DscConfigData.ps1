function ConvertTo-DscConfigData
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$true)]
    [object]
    $JsonData
  )
  
  
$ConfigData = @{

        AllNodes = @()

}

foreach ($propL1 in ($JsonData.psobject.properties.name | where {$_ -ne 'AllNodes'}))
   {
     $ConfigData[$propL1] = @{}
     foreach ($propL2 in $JsonData.$propL1.psobject.properties.name)
        {
          $ConfigData[$PropL1][$PropL2] = $JsonData.$propL1.$propL2
        }
    }


foreach ($propL1 in ($JsonData.psobject.properties.name | where {$_ -eq 'AllNodes'}))
   {
     $ht = @{}
     foreach ($propL2 in $JsonData.$propL1)
        {
            $propL2.psobject.properties | Foreach { $ht[$_.Name] = $_.Value }
        }
      $ConfigData.AllNodes += $ht
    }

return $ConfigData
  
}