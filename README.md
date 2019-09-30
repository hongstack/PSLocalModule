# PSLocalModule
**PSLocalModule** is a PowerShell module that provides commands for testing, installing and listing local modules.

## Overview
Local PowerShell modules are modules installed to the user specific module path, i.e. `$env:USERPROFILE\Documents\WindowsPowerShell\Modules` rather than in `C:\ProgramFiles` where write access is not allowed in some corporate environments. 

**PSLocalModule** supports installing local modules from either the pre-configured `PSCodePath` (via `Set-PSCodePath`), or current directory if `ModuleName` is not provided.

## Installation
### Direct Download
Download [PSLocalModule v1.0.1](https://github.com/hongstack/PSLocalModule/releases/download/1.0.1/PSLocalModule_1.0.1.zip), extracts the content under one of the following locations:
* `C:\Program Files\WindowsPowerShell\Modules` *Applies to all users, but may not be an option for some corporate environments*.
* `$env:USERPROFILE\Documents\WindowsPowerShell\Modules` *Applies to current user*.

### Manual Build
Clone [PSLocalModule](https://github.com/hongstack/PSLocalModule.git), then go into the *PSLocalModule* directory, executing:
```PowerShell
Import-Module -Path .\PSLocalModule.psd1
Import-LocalModule -Verbose
```

## Usage
### Initial Setup
After installation, it is recommended to set the PSCodePath where local PowerShell modules exist using the following command:
````PowerShell
Set-PSCodePath -Path <Path_To_PowerShell_Local_Modules>
````
Run `Get-PSCodePath` gets the already-set PSCodePath.

### Install Local Module
Local module can be installed from PSCodePath or from current directory:
````PowerShell
Install-LocalModule <Module_Name> # Install from PSCodePath
Install-LocalModule # Install from current directory
````
It is strongly recommended to use `-whatif` and `-verbose` parameters before running real installation.

### .PSIGNORE
Local module can have `.psignore` file which specifies what directories/files can be ignored during building. Additionally any directories/files specified in `.gitignore` will also be ignored. The `.psignore` and `.gitignore` themselves are ignored by default.

The `.psignore` file supports ignoring files and directories, and wildcards (*, ?). It also treats any line starting with `#` as comment.
### More Info
Use PowerShell's `Get-Command -Module PSLocalModule` to explore available commands; and `Get-Help <Cmdlet>` to find out the usage for each command.

## TODO
* Add command `Show-LocalModule`
* Add command `Uninstall-LocalModule`
* Add structure tests (`PSLocalModule.Tests.ps1`)
* Export variable `PSUserPath`
* Allow `PSUserPath` to be configured
* Make `Set-PSCodePath` accept pipeline variable
* Improve exception handling, which should show which command is having issue, instead of the throw statement