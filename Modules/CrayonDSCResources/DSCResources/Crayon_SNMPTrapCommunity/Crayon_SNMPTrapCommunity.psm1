function Get-TargetResource 
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param 
    (
		[parameter(Mandatory = $true)]
		[System.String]
		$Community,
		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure
	)

    $CommunityList = (Get-ChildItem -Path HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\TrapConfiguration).PSChildName
   

    #Building the Hashtable
    
    
    $ReturnValue = @{
        Community=$CommunityList -Join ','
        Ensure = $Ensure
    }
    $ReturnValue
}


function Set-TargetResource 
{
	[CmdletBinding()]
	param 
    (
		[parameter(Mandatory = $true)]
		[System.String]
		$Community,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure
	)

    switch ($Ensure) {
        "Present" { 
            Write-Verbose "Addind community to the allowed list"
            New-Item -Path HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters -Name TrapConfiguration -ErrorAction SilentlyContinue | Out-Null
            New-Item -Path HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\TrapConfiguration -Name $Community | Out-Null
            Restart-Service -Name SNMP
        }
        "Absent" {
            Write-Verbose "Removing community from the allowed list"
            Remove-Item -Path HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\TrapConfiguration -Name $Community -Recurse
            Restart-Service -Name SNMP
        }
    
    }
}


function Test-TargetResource 
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param 
    (
		[parameter(Mandatory = $true)]
		[System.String]
		$Community,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure
	)

    
    
    $CommunityList = (Get-ChildItem -Path HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\TrapConfiguration -erroraction silentlycontinue).PSChildName
    
    Switch ($Ensure) {
        "Present" { 
            if ($Community -in $CommunityList) {
                $return = $true
            }
            else { $return = $false }
        }
        "Absent" {
            if ($Community -in $CommunityList) {
                $return = $false
            }
            else { $return = $true }
        }
    }
    $Return
}


Export-ModuleMember -Function *-TargetResource