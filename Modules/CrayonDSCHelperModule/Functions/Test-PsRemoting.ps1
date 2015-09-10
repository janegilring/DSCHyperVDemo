# Test-PsRemoting copied from http://www.leeholmes.com/blog/2009/11/20/testing-for-powershell-remoting-test-psremoting/
function Test-PsRemoting
{ 
    param( 
        [Parameter(Mandatory = $true)] 
        $computername,
        [Parameter(Mandatory = $true)] 
        $credential
    ) 
     
    try 
    { 
        $errorActionPreference = "Stop" 
        $result = Invoke-Command -ComputerName $computername { 1 } -Credential $credential
    } 
    catch 
    { 
        Write-Verbose $_ 
        return $false 
    } 
     
    ## I’ve never seen this happen, but if you want to be 
    ## thorough…. 
    if($result -ne 1) 
    { 
        Write-Verbose "Remoting to $computerName returned an unexpected result." 
        return $false 
    } 
     
    $true     
}