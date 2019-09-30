$PSUserPath = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules"

<#
.SYNOPSIS
Set PSCodePath from where local modules are developed and installed.

.DESCRIPTION
The PSCodePath does not need to exist at the time of configuring but a warning message will be displayed.

.PARAMETER Path
The filesystem path that is to be set as PSCodePath. PSCodePath needs to be set when installing modules 
with the specified module name. It is not used when installing modules from current directory.

.Example
Set-PSCodePath -Path C:\Dev\Workspace\PowerShell

This commands will set C:\Dev\Workspace\PowerShell as PSCodePath
#>
function Set-PSCodePath {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, Position=0)][String]$Path
    )
    
    if (!(Test-Path -Path $Path)) {
        Write-Warning "Path does not exist: $Path"
    }

    $ModuleConfigPath = $PSCommandPath -replace 'psm1', 'json'
    $ModuleConfigName = $ModuleConfigPath | Split-Path -Leaf
    if (Test-Path -Path $ModuleConfigPath) {
        $ModuleConfig = Get-Content -Path $ModuleConfigPath -Raw | ConvertFrom-Json
        Write-Verbose "Update module configuration: $ModuleConfigName"
    } else {
        $ModuleConfig = @{}
        Write-Verbose "Create module configuration: $ModuleConfigName"
    }
    $ModuleConfig.PSCodePath = $Path
    $ModuleConfig | ConvertTo-Json | Set-Content $ModuleConfigPath
}
Set-Alias -Name scp -Value Set-PSCodePath

<#
.SYNOPSIS
Gets the configured PSCodePath. 

.DESCRIPTION
An error will be returned if the PSCodePath has not set yet, or set but does not exist.
#>
function Get-PSCodePath {
    [CmdletBinding()]
    Param()

    $ModuleConfigPath = $PSCommandPath -replace 'psm1', 'json'
    if (!(Test-Path -Path $ModuleConfigPath)) {
        throw "Module not configured. Please use Set-PSCodePath to configure"
    }

    $ModuleConfig = Get-Content -Path $ModuleConfigPath -Raw | ConvertFrom-Json
    $PSCodePath = $ModuleConfig.PSCodePath
    if ([String]::IsNullOrWhiteSpace($PSCodePath)) {
        throw "PSCodePath not set. Please use Set-PSCodePath to configure"
    }
    if (!(Test-Path -Path $PSCodePath)) {
        throw "PSCodePath does not exist: $PSCodePath"
    }
    return $PSCodePath
}
Set-Alias -Name gcp -Value Get-PSCodePath

<#
.SYNOPSIS
Installs PowerShell modules from the defined PSCodePath to user specific module path.

.DESCRIPTION
This command simulates what Install-Module does. However it installs modules from either 
the defined PSCodePath, or from current directory if ModuleName is not provided.

It also installs modules to user specific module path rather than the C:\ProgramFiles, 
i.e. $env:USERPROFILE\Documents\WindowsPowerShell\Modules.

The module manifest file must have the same name (without extension) as its containing directory 
so as to be installed. And the manifest file name (i.e. containing directory name) is module name.

The module to be installed must not contain version directory between module name and content which 
standard PowerShell module follows. The module version is extraced from the manifest file during 
installation.

If the module being installed has the same name and version, the installation will fail unless 
-Force parameter is used, which the existing module will be replaced.

.PARAMETER ModuleName
Specifies the module to be installed from PSCodePath

.PARAMETER Force
Specifies whether to override the existing module/version

.Example
Install-LocalModule <APP1> -whatif -verbose

This command will display what to be installed with verbose output. It DOES NOT install anything.

.Example
Install-LocalModule <APP1>

This command will install <APP1> to user specific module path.
#>
function Install-LocalModule {
    [CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = "Medium")]
    Param(
        [String]$ModuleName,
        [Switch]$Force
    )
    
    # Resolve module name and path
    if ($ModuleName) {
        $ModulePath = Get-PSCodePath | Join-Path -ChildPath $ModuleName
    } else {
        $ModulePath = (Get-Location).Path
        $ModuleName = $ModulePath | Split-Path -Leaf
        Write-Verbose "Installing $ModuleName from current directory"
    }

    # Verify module existence and get version
    $PSD1File = $ModulePath | Join-Path -ChildPath "$ModuleName.psd1"
    if (Test-Path -Path $PSD1File) {
        $ModuleVersion = (Import-PowerShellDataFile -Path $PSD1File).ModuleVersion
        Write-Verbose "Found module manifest: $PSD1File"
    } else {
        throw "Cannot find module manifest: $PSD1File"
    }

    # Get canonical case of module name
    $ModuleName = ($ModulePath | Get-ChildItem | Where {$_.FullName -eq $PSD1File}).BaseName

    # Verify if module installed before
    $UserModulePath = $PSUserPath | Join-Path -ChildPath $ModuleName | Join-Path -ChildPath $ModuleVersion
    if (Test-Path -Path $UserModulePath) {
        if ($Force) {
            if ($PSCmdlet.ShouldProcess($UserModulePath, "Remove")) {
                Remove-Item -Path $UserModulePath -Recurse -Force
            }
            if ($PSCmdlet.ShouldProcess($UserModulePath, "Create")) {
                $null = New-Item -Path $UserModulePath -ItemType Directory
            }
        } else {
            throw "Module exists: $UserModulePath"
        }
    } else {
        if ($PSCmdlet.ShouldProcess($UserModulePath, "Create")) {
            $null = New-Item -Path $UserModulePath -ItemType Directory
        }
    }

    # Copy modules to PSUserPath
    $RawExcludes = @()
    $ResolvedExcludes = @()
    '.gitignore', '.psignore' | ForEach { Join-Path $ModulePath $_} | Where { Test-Path $_ } | ForEach {
        $ResolvedExcludes += $_
        $RawExcludes += @(Get-Content -Path $_ | Where {$_ -notlike '#*'})
    }
    
    $ResolvedExcludes += ($RawExcludes | ForEach { Join-Path $ModulePath $_} | Where {Test-Path $_} | Resolve-Path).Path
    $ResolvedExcludes += (Get-ChildItem $ModulePath -Directory -Recurse  | ForEach {
        $Parent = $_.FullName
        $RawExcludes | ForEach {Join-Path $Parent $_} | Where {Test-Path $_} | Resolve-Path
    }).Path
    Write-Verbose "Excluding: $($ResolvedExcludes -join '; ')"
    
    Get-ChildItem $ModulePath -Recurse | Where { $_.FullName -notin $ResolvedExcludes } | ForEach {
        if ($PSCmdlet.ShouldProcess($_.FullName, "Copy")) {
            Copy-Item $_.FullName (Join-Path $UserModulePath ($_.FullName.Substring($ModulePath.length)))
        }
    }
    
    Write-Verbose ("Completed installation of {0}_{1}" -f $ModuleName, $ModuleVersion)
}
Set-Alias -Name inlm -Value Install-LocalModule


<#
.SYNOPSIS
Downloads and saves PowerShell module to the defined PSCodePath.

.DESCRIPTION
The Save-LocalModule wraps Install-Module, and save the downloaded module to PSCodePath directly.
#>
function Save-LocalModule {
    [CmdletBinding()]
    Param(
    )
    throw "Not implemented"
}
Set-Alias -Name svlm -Value Save-LocalModule

<#
.SYNOPSIS
Dispalys all locally installed modues and their version.

.DESCRIPTION
This function scans the modules installed in PowerShell user specified module path, 
and displays their information.

#>
function Show-LocalModule {
    [CmdletBinding()]
    Param(
    )
    throw "Not implemented"
}
Set-Alias -Name shlm -Value Show-LocalModule

<#
.SYNOPSIS
Runs Pester tests for the specified module from the defined PSCOdePath.

.DESCRIPTION
The Test-LocalModule wraps the Invoke-Pester command and provides a convinient way to run Pester tests
during development.

See Invoke-Pester for parameters usage.
#>
function Test-LocalModule {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, Position=0)]
        [Alias('Path')] [String]$ModuleName,
        [Alias("Name")] [String[]]$TestName,
        [Alias('Tags')] [String[]]$Tag
    )
    
    # Re-Import Pester with minimum version
    Get-Module Pester | Remove-Module -Force
    Import-Module Pester -MinimumVersion 4.8.1 -ErrorAction Stop

    # Re-Import the module to be tested
    $ModulePath = Get-PSCodePath | Join-Path -ChildPath $ModuleName
    $Module = $ModulePath | Join-Path -ChildPath "$ModuleName.psd1"
    Get-Module $ModuleName | Remove-Module -Force
    Import-Module $Module -ErrorAction Stop
    Write-Verbose "Reloaded module: $Module"

    # Resolve arguments to Pester
    $Args = @{Script = $ModulePath; ErrorAction = 'Stop'}
    if ($null -ne $TestName) { $Args.TestName = $TestName }
    if ($null -ne $Tag)      { $Args.Tag      = $Tag }
    Write-Host "Invoking Pester with args: $($Args | Out-String)"

    Invoke-Pester @Args
}
Set-Alias -Name tlm -Value Test-LocalModule