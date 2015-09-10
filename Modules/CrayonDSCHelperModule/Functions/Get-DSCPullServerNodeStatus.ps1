function Get-DSCPullServerNodeStatus
{
  Param (     
       [string] $PullServerUri = "http://localhost:7070/PSDSCComplianceServer.svc/Status",                         
       [string] $ContentType = "application/json"          
     )
  Write-Host "Querying node information from pull server URI  = $PullServerUri" -ForegroundColor Green
  Write-Host "Querying node status in content type  = $ContentType " -ForegroundColor Green
 

 $response = Invoke-WebRequest -Uri $PullServerUri -Method Get -ContentType $ContentType -UseDefaultCredentials -Headers @{Accept = $ContentType}
 
 if($response.StatusCode -ne 200)
 {
     Write-Host "node information was not retrieved." -ForegroundColor Red
 }
 
 $jsonResponse = ConvertFrom-Json $response.Content
 
 $StatusCode = @"

0 = Configuration was applied successfully

1 = Download Manager initialization failure

2 = Get configuration command failure

3 = Unexpected get configuration response from pull server

4 = Configuration checksum file read failure

5 = Configuration checksum validation failure

6 = Invalid configuration file

7 = Available modules check failure

8 = Invalid configuration Id In meta-configuration

9 = Invalid DownloadManager CustomData in meta-configuration

10 = Get module command failure

11 = Get Module Invalid Output

12 = Module checksum file not found

13 = Invalid module file

14 = Module checksum validation failure

15 = Module extraction failed

16 = Module validation failed

17 = Downloaded module is invalid

18 = Configuration file not found

19 = Multiple configuration files found

20 = Configuration checksum file not found

21 = Module not found

22 = Invalid module version format

23 = Invalid configuration Id format

24 = Get Action command failed

25 = Invalid checksum algorithm

26 = Get Lcm Update command failed

27 = Unexpected Get Lcm Update response from pull server

28 = Invalid Refresh Mode in meta-configuration

29 = Invalid Debug Mode in meta-configuration

"@

$hashStatusCode = ConvertFrom-StringData $StatusCode

$output = $jsonResponse.value

$output | Add-Member -MemberType ScriptProperty -Name HostName -Value {([System.Net.Dns]::GetHostEntry($this.targetname)).HostName}

$output | Add-Member -MemberType ScriptProperty -Name LastCompliance -Value {[datetime]$this.LastComplianceTime}

$output | Add-Member -MemberType ScriptProperty -Name LastHeartbeat -Value {[datetime]$this.LastHeartbeatTime}

$output | Add-Member -MemberType ScriptProperty -Name StatusMessage -Value {[string]$hashStatusCode[[string]$this.StatusCode]}

return $output

}