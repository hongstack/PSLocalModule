# PSLocalModule
**PSLocalModule** is a PowerShell module that provides commands for testing, installing and listing local modules.

## Overview
PowerShell local modules are modules installed to the user specific module path, i.e. `$env:USERPROFILE\Documents\WindowsPowerShell\Modules` rather than in `C:\ProgramFiles` where write access is not allowed in some corporate environments. 

**PSLocalModule** supports installing local modules from either the pre-configured `PSCodePath` (via `Set-PSCodePath`), or current directory if `ModuleName` is not provided.

## Installation
Clone or download [PSLocalModule](https://github.com/hongstack/PSLocalModule/archive/master.zip), decompress it if downloaded, then go to the *PSLocalModule* directory, executing:
```PowerShell
Import-Module -Path .\PSLocalModule.psd1
Import-LocalModule -Verbose
```

## Usage
Use PowerShell's `Get-Command -Module PSLocalModule` to explore available commands; and `Get-Help <Cmdlet>` to find out the usage for each command.

## TODO
* Add command `Show-LocalModule`
* Add command `Uninstall-LocalModule`
* Add structure tests (`PSLocalModule.Tests.ps1`)
* Export variable `PSUserPath`
* Allow `PSUserPath` to be configured
* Allow Pester minimum version to be configured
* Make `Set-PSCodePath` accept pipeline variable
* Improve exception handling, which should show which command is having issue, instead of the throw statement
* Add private data section to module manifest
* Use requires to enforce dependency on Pester (https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_requires?view=powershell-5.1)