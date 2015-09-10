Function Process-RunbookFolder
{
    Param (
        $Path,
        [switch]$recurse,
        $WebServiceEndpoint,
        $Credential,
        [switch]$force
        )
    $allwfs =@()
    $allwfs += get-childitem -Path $Path -Recurse:$recurse | where {$_.Extension -eq '.ps1'}
    $Global:referencelist = New-Object System.Collections.ArrayList
    [System.Collections.ArrayList]$Global:ToProcessList = $allwfs
    $Global:DoneProcessList = New-Object System.Collections.ArrayList
    foreach ($wf in $ToProcessList)
    {
        #Validate-RunbookFile -path $wf.FullName -erroraction Stop
        Get-RunbookReference -path $wf.Fullname
    }
    foreach ($wf in $ToProcessList)
    {
        #Validate-RunbookFile -path $wf.FullName -erroraction Stop
        Process-RunbookFile -path $wf.FUllname -basepath $Path -recurse:$recurse -WebServiceEndpoint $WebServiceEndpoint -Credential $credential -force:$force
    }
    #get-variable processlist -Scope global | Remove-Variable
}

Function Get-RunbookReference
{
    Param ($path)
    $ThisWf = get-content $path -Raw
    $ThisWfSB = [scriptblock]::Create($ThisWf)
    #$ThisWfAST = $ThisWfSB.Ast
    $TokenizedWF = [System.Management.Automation.PSParser]::Tokenize($ThisWfSB,[ref]$null)
    $referencedCommands = $TokenizedWF | where {$_.Type -eq 'Command'} | select -ExpandProperty 'Content'
    $myobj = '' |Select Fullname, ReferencedRunbooks
    $myobj.Fullname  =$path
    $myobj.ReferencedRunbooks = $referencedCommands
    $Global:referencelist += $myobj; $myobj = $null

}

Function Process-RunbookFile
{
    Param (
        $path, 
        $basepath, 
        [switch]$recurse,
        $WebServiceEndpoint,
        $Credential,
        [switch]$force
    )
    
    $path = get-item $path
    if ($DoneProcessList -contains ($path.FullName))
    {
        Write-Verbose "SKIPPING: Already processed runbook $($path.BaseName)"
        return
    }
    Write-Verbose "PARSING: Runbook $($path.BaseName)"
    #Parse to find wfs this one depends on, and process
    $ThisWf = get-content $path -Raw
    $ThisWfSB = [scriptblock]::Create($ThisWf)
    #$ThisWfAST = $ThisWfSB.Ast
    $TokenizedWF = [System.Management.Automation.PSParser]::Tokenize($ThisWfSB,[ref]$null)
    $referencedCommands = $TokenizedWF | where {$_.TYpe -eq 'Command'}
    foreach ($referencedCommand in $referencedCommands)
    {
        $runbookpath = get-childitem -Path $basepath -Recurse:$recurse |where {$_.BaseName -eq $referencedCommand.Content}
        if ($runbookpath)
        {
            Write-Verbose "REFERENCE: $($path.BaseName)--> $($referencedCommand.content)"
            Process-RunbookFile -path $runbookpath.FullName -WebServiceEndpoint $WebServiceEndpoint -Credential $Credential -force:$force
        }  
    }

    #WHen all referenced runbooks are imported, import this one
    #Write-Verbose "PUBLISH: Publishing runbook $($path.BaseName)"

    #Check if runbook matches target
    $IsUpdated = Compare-Runbook $path -WebServiceEndpoint $WebServiceEndpoint -Credential $credential
    if (!($IsUpdated) -or ($force))
    {
        Write-Verbose "Runbook $($path.BaseName) is updated and will be republished"
        Write-Verbose 'It is referenced by these runbooks:'
        $Global:referencelist | where {$_.ReferencedRunbooks -match ($path.BaseName)} | Select -ExpandProperty Fullname | foreach {
            $refrb = $_
            write-verbose $refrb
            $global:ToProcessList | where {$_.Fullname -eq $refrb} | Add-Member -MemberType NoteProperty -Name Force -Value $true -Force
        }
        
    }

    $thisRbProcLIst = $global:ToProcessList | where {$_.Fullname -eq $path.FullName}
    if ($thisRbProcLIst.Force -eq $true)
    {
        $forceUpdateRb = $true

    }

    if ($forceUpdateRb)
    {
        Write-Verbose "Runbook $path will be forcibly updated because it references an updated runbook"
    }

    if (($forceUpdateRb) -or (!($IsUpdated)))
    {
        #This function is only called for runbooks which need updating, or runbooks which reference runbooks which need updating
        Write-Verbose "PUBLISH: $($path.FullName)"
        Publish-Runbook $path -WebServiceEndpoint $webserviceendpoint -Credential $credential
    }
    $Global:DoneProcessList += $path.FullName

}


Function Compare-Runbook
{
    Param (
        [System.IO.FileSystemInfo]$path,
        $WebServiceEndpoint,
        $Credential
    )

    $FileContent = get-content -Path ($path.FullName) -Raw

    $SmaRb = Get-SmaRunbook -WebServiceEndpoint $WebServiceEndpoint -Credential $Credential -Name ($path.BaseName) -ErrorAction 0
    if (!($SmaRb))
    {
        return $false
    }

    $SMaRbContent = Get-SmaRunbookDefinition -Id $SmaRb.RunbookId -WebServiceEndpoint $WebServiceEndpoint -Credential $Credential -Type Published

    if ($FileContent -ne $SMaRbContent.Content)
    {
        return $false
    }

    return $true
}

Function Compare-Runbook
{
    Param (
        [System.IO.FileSystemInfo]$path,
        $WebServiceEndpoint,
        $Credential
    )

    $FileContent = get-content -Path ($path.FullName) -Raw

    $SmaRb = Get-SmaRunbook -WebServiceEndpoint $WebServiceEndpoint -Credential $Credential -Name ($path.BaseName) -ErrorAction 0
    if (!($SmaRb))
    {
        return $false
    }

    $SMaRbContent = Get-SmaRunbookDefinition -Id $SmaRb.RunbookId -WebServiceEndpoint $WebServiceEndpoint -Credential $Credential -Type Published

    if ($FileContent -ne $SMaRbContent.Content)
    {
        return $false
    }

    return $true
}

Function Publish-Runbook
{
    Param (
        [System.IO.FileSystemInfo]$path,
        $WebServiceEndpoint,
        $Credential
    )

    $SmaRb = Get-SmaRunbook -WebServiceEndpoint $WebServiceEndpoint -Credential $Credential -Name ($path.BaseName) -ErrorAction 0
    if (!($SmaRb))
    {
        $smarb = Import-SmaRunbook -Path $path.FullName -WebServiceEndpoint $WebServiceEndpoint -Credential $Credential
    }
    Else
    {
        Edit-SmaRunbook -Path $path.FullName -WebServiceEndpoint $WebServiceEndpoint -Credential $Credential -Name ($path.BaseName) -Overwrite
    }

    $publishedId = Publish-SmaRunbook -Id $SmaRb.RunbookID -WebServiceEndpoint $WebServiceEndpoint -Credential $Credential
    
}

#This is the function you need to run to kick everything off:
$repositoryfolder = (get-item $MyInvocation.InvocationName).DirectoryName -replace 'Utils',''
$cred = Import-Clixml "$env:temp\$($env:COMPUTERNAME).cred.xml"
$VerbosePreference = 'Continue'

$EnvData =  Get-EnvironmentData

Process-RunbookFolder -Path (join-path $repositoryfolder 'SMA Runbooks') -WebServiceEndpoint $EnvData.SMAWebServiceEndpoint