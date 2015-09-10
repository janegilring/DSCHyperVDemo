#region Demo setup
Write-Warning 'This is a demo script which should be run line by line or sections at a time, stopping script execution'

break

<#

    Author:      Jan Egil Ring
    Description: This demo script is part of the presentation 
                 PowerShell Desired State Configuration – Real World Experiences
		 presented at PowerShell Summit Europe 2015
                 
#>

#Requires -Version 3.0
 
<#
.Synopsis
    Rename Resource prefix
.DESCRIPTION
    As MSFT Resource release as xHOGEMOGE, this function will rename x to c (in default).
    You can change prefix as you want.
    Target will be, ModuleFolder, Resource Folder, files with extension .psm1, .psd1, .mof
.EXAMPLE
    Rename-DSCModuleResourcePrefix -Path c:\Path\To\Resource\Directory -ResourceName ResourcenameToRename  -NewPrefix c -Verbose
    # You can specify Path and ResourceName to strictly identify.
.EXAMPLE
    Rename-DSCModuleResourcePrefix -ResourceName xPSDesiredStateConfiguration -NewPrefix c -Verbose
    # You can omit Path if ResourceName is correct and is in current Directory
.EXAMPLE
    Rename-DSCModuleResourcePrefix -Path .\xPSDesiredStateConfiguration -NewPrefix c -Verbose
    # You can omit ResourceName if Path is correct.
.EXAMPLE
    Rename-DSCModuleResourcePrefix -NewPrefix c -Verbose
    # This cause error, as Path or Resource should set.
#>
function Rename-DSCModuleResourcePrefix
{
    [OutputType([System.IO.FileInfo[]])]
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = 0, Position = 0, ValueFromPipeline = 1, ValueFromPipelineByPropertyName = 1)]
        [string[]]$ResourceName = @(),
 
        [parameter(Mandatory = 0, Position = 1, ValueFromPipelineByPropertyName = 1)]
        [string]$Path = "",
 
        [parameter(Mandatory = 1, Position = 2, ValueFromPipelineByPropertyName = 1)]
        [ValidateLength(1, [int]::MaxValue)]
        [string]$NewPrefix = 'c',
 
        [parameter(Mandatory = 0, Position = 3, ValueFromPipelineByPropertyName = 1)]
        [string]$ModuleNamePattern = "MSFT_",
 
        [parameter(Mandatory = 0, Position = 4, ValueFromPipelineByPropertyName = 1)]
        [string]$PrefixDelimiter = "",
 
        [parameter(Mandatory = 0, Position = 5, ValueFromPipelineByPropertyName = 1)]
        [bool]$SkipFriendlyName = $false,
 
        [parameter(Mandatory = 0, Position = 6, ValueFromPipelineByPropertyName = 1)]
        [string[]]$TargetFileExtensions = @(".psm1", ".psd1", ".mof"),
 
        [parameter(Mandatory = 0, Position = 7, ValueFromPipelineByPropertyName = 1)]
        [bool]$EnableBackup = $true,
 
        [parameter(Mandatory = 0, Position = 8, ValueFromPipelineByPropertyName = 1)]
        [string]$BackupPath = "$env:LOCALAPPDATA\Temp",
 
        [parameter(Mandatory = 0, Position = 9, ValueFromPipelineByPropertyName = 1)]
        [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]
        [string]$encoding = "utf8"
    )
 
    process
    {
        foreach ($resource in $ResourceName)
        {
            Write-Verbose ("ResourceName : {0}" -f $resource)
 
        #region Prerequisites
 
            $baseLength = GetPrefixLength -Resourcename $ResourceName -PrefixDelimiter $PrefixDelimiter
 
            $currentPrefix = GetCurrentPrefix -ResourceName $resource -Length $baseLength
            $newResourceName = GetNewResourceName -ResourceName $resource -newPrefix $NewPrefix -Length $baseLength
 
            $originalMSFT = "$ModuleNamePattern{0}" -f $currentPrefix
            $newMSFT = "$ModuleNamePattern{0}" -f $NewPrefix
 
            $originalMOF = 'FriendlyName("{0}' -f $currentPrefix
            $newMOF = 'FriendlyName("{0}' -f $NewPrefix
 
        #endregion
 
        #region Validation
 
            # Try get path from ReosourceName
            if ($Path -eq "")
            {
                Write-Verbose "Path detected empty, set resource Name as Path."
                if (-not(Test-Path -Path ".\$resource")){ throw New-Object System.IO.FileNotFoundException ("Path Resource Name '{0}' not found exception!!" -f $resource, $resource) }
                $Path = Split-Path (Resolve-Path -Path ".\$resource").Path -Parent
                $resetPath = $true 
            }
 
            # validation
            if (-not(Test-Path -Path $Path)){ throw New-Object System.IO.FileNotFoundException ("Path $Path not found exception!!", $Path) }
            if (-not((Get-Item -Path $Path).PSIsContainer)){ throw New-Object System.InvalidOperationException ("Operation is not valid due to Path detected as File. Make sure set Directory for -Path.", $Path) }
 
            $resourcePath = Join-Path -Path $Path -ChildPath $resource
            if (Test-Path (Join-Path $Path -ChildPath $newResourceName)){ throw New-Object System.InvalidOperationException ("Operation is not valid due to attempt new resource name '{0}' already exist." -f $newResourceName) }
            if (-not(IsPathContainsResouceName -Path $Path -ResourceName $resource)){ throw New-Object System.InvalidOperationException ("Operation is not valid due to Resource name not in Path.") }
 
        #endregion
 
        #region backup before execute
            
            if ($EnableBackup){ BackupResource -Path $resourcePath -BackupPath $BackupPath }
 
        #endregion
 
        #region File
 
            Get-ChildItem -Path $resourcePath -Recurse -File `
            | where Extension -in $TargetFileExtensions `
            | %{
                $fullpath = $_.FullName
            
            #region Content
 
                # resource
                Get-Content -Path $fullpath -Raw -Encoding $encoding `
                | %{
                    if ($_ -like "*$resource*")
                    {
                        Write-Verbose ("file content: '{0}' changed from {1} to {2}" -f $fullpath, $resource, $newResourceName)
                        $_.replace($resource, $newResourceName) | Out-File -FilePath $fullpath -Encoding $encoding -Force
                    }
                }
 
                # msft
                Get-Content -Path $fullpath -Raw -Encoding $encoding `
                | %{
                    if ($_ -like "*$originalMSFT*")
                    {
                        Write-Verbose ("file content: '{0}' changed from {1} to {2}" -f $fullpath, $originalMSFT, $newMSFT)
                        $_.replace("$originalMSFT", "$newMSFT") | Out-File -FilePath $fullpath -Encoding $encoding -Force
                    }
                }
 
                # mof
                Get-Content -Path $fullpath -Raw -Encoding $encoding `
                | %{
                    if (-not $SkipFriendlyName)
                    {
                        if ($_ -like "*$originalMOF*")
                        {
                            Write-Verbose ("file content: '{0}' changed from {1} to {2}" -f $fullpath, $originalMOF, $newMOF)
                            $_.Replace("$originalMOF", "$newMOF") | Out-File -FilePath $fullpath -Encoding $encoding -Force
                        }
                    }
                }
 
            #endregion
 
            #region FileName
 
                # resource
                if ($_.Name -like "$resource*")
                {
                    $newResourceFileName = $_.Name -replace $resource, $newResourceName
                    Rename-Item -Path $_.FullName -NewName $newResourceFileName
                    Write-Verbose ("file name changed from {0} to {1}" -f $fullpath, $newResourceFileName)
                }
 
                # msft
                if ($_.Name -like "$originalMSFT*")
                {
                    $newMSFTFileName = $_.Name -replace $originalMSFT, $newMSFT
                    Rename-Item -Path $_.FullName -NewName $newMSFTFileName
                    Write-Verbose ("file name changed from {0} to {1}" -f $fullpath, $newMSFTFileName)
                }
 
            #endregion
            } 
 
        #endregion
 
        #region Folder
 
            # Child Folder
            Get-ChildItem -Path $resourcePath -Recurse -Directory `
            | where Name -like "$originalMSFT*" `
            | %{
                # msft
                $newDirectoryName = $_.Name -replace $originalMSFT, $newMSFT
                Rename-Item -Path $_.FullName -NewName $newDirectoryName
            }
 
            # Parent Folder
            Rename-Item -Path $resourcePath -NewName $newResourceName
 
            # Show Result
            $newResourcePath = Join-Path -Path $Path -ChildPath $newResourceName
            Get-Item -Path $newResourcePath
 
        #endregion
 
            # Reset Path when input Path was empty
            if($resetPath){$Path = ""}
        }
    }
 
    begin
    {
        $resourceElements = ($ResourceName | Measure-Object).Count
 
        # validate Input
        if ($Path -ne "" -and $resourceElements -ne 0 -and (-not(Test-Path -Path $Path))){ throw New-Object System.IO.FileNotFoundException ("Path $Path not found exception!!", $Path) }
        if ($Path -eq "" -and $resourceElements -eq 0){ throw New-Object System.InvalidOperationException ("Operation is not valid due to both Path and ResourceName detected empty string. Please specify at least one.") }
        # ResolvePath
        if ($Path -ne "")
        {
            Write-Verbose "Resolve Path to Absolute Path"
            $Path = (Resolve-Path -Path $Path).Path
        }
        # validate Path
        if (($resourceElements -eq 0) -and (-not(Test-Path -Path $Path))) { throw New-Object System.IO.FileNotFoundException ("Path $Path not found exception!!", $Path) }
        # Set ResourceName with Path
        if (($resourceElements -eq 0) -and (Test-Path -Path $Path)){ $ResourceName = (Get-ChildItem -Path $Path -Directory).Name }
 
        function GetPrefixLength ([string]$Resourcename, [string]$PrefixDelimiter)
        {
            if ($PrefixDelimiter -eq "")
            {
                1
            }   
            else
            {
                ($ResourceName -split $PrefixDelimiter | select -First 1).Length
            }
        }
 
        function IsPathContainsResouceName ([string]$Path, [string]$ResourceName)
        {
            $resources = (Get-ChildItem -Path $Path -Directory).Name
            if ($resources -eq $null){ throw New-Object System.InvalidOperationException ("Operation is not valid due to Path not contains any Directory. Make sure Path contains Resource Folder.") }
            if ($ResourceName -notin $resources){ return $false }
            return $true
        }
 
        function GetCurrentPrefix ([string]$ResourceName, [int]$Length)
        {
            $baseChar = [Linq.Enumerable]::ToArray($ResourceName)
            $currentPrefix = $baseChar | select -First $baseLength
            return $currentPrefix
        }
 
        function GetNewResourceName ([string]$ResourceName, [string]$NewPrefix, [int]$Length)
        {
            $baseChar = [Linq.Enumerable]::ToArray($ResourceName)
            $leastItem = ($baseChar | select -Skip $baseLength) -join ""
            $newResourceName = $NewPrefix, $leastItem -join ""
            return $newResourceName
        }
 
        function BackupResource ([string]$Path, [string]$BackupPath)
        {
            $backupFolderName = (Get-Date).ToString("yyyyMMdd_HHmmss")
            $backup = Join-Path -Path $BackupPath -ChildPath $backupFolderName
            
            Write-Verbose ("Creating backup folder '{0}'" -f $backup)
            if (-not(Test-Path $backup)){ New-Item -Path $backup -ItemType Directory -Force > $null }
 
            Write-Warning ("Creating Resource backup '{0}' to '{1}' before change effect." -f $Path, $backup)
            Copy-Item -Path $path -Destination $backup -Force -Recurse | Format-Table | Out-String -Stream | Write-Verbose
        }
    }
}

# You can specify Path and ResourceName to strictly identify.
Rename-DSCModuleResourcePrefix -Path c:\Path\To\Resource\Directory -ResourceName ResourcenameToRename  -NewPrefix c -Verbose

# You can omit Path if ResourceName is correct and is in current Directory
Rename-DSCModuleResourcePrefix -ResourceName xPSDesiredStateConfiguration -NewPrefix c -Verbose

# You can omit ResourceName if Path is correct.
Rename-DSCModuleResourcePrefix -Path .\xPSDesiredStateConfiguration -NewPrefix c -Verbose

# Rename prefix from Contoso to Crayon
Rename-DSCModuleResourcePrefix -Path ~\hyper-v-configurations\Modules\CustomerADSCResources\DSCResources -ModuleNamePattern CustomerA -NewPrefix Crayon -PrefixDelimiter _ -Verbose

# https://gist.github.com/guitarrapc/07fce11302506eed346a