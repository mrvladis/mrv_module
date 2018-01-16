<#


.SYNOPSIS
This Powershell Script update PS Path variable within the Azure Function, so it do not reffer to builtin Azure Modules, but to the modules delivered with Function code.

.DESCRIPTION
This Powershell Script update PS Path variable within the Azure Function, so it do not reffer to builtin Azure Modules, but to the modules delivered with Function code.

.EXAMPLE


.NOTES


.LINK



#>

Function Start-MRVAzureFuncPSModValidation
{
    param(
        [Parameter(Mandatory = $false)]
        [String]
        $localModulesFolder,
        [Parameter(Mandatory = $false)]
        [String]
        $builtinModulesFolderPattern
    )
    $result = @{Result = $false; Reason = 'Failed to update PowerShell Module Path'}
    If (($localModulesFolder) -eq $null -or ($localModulesFolder -eq ""))
    {
        Write-Output "No custom module path provided."
        $localModulesFolder = "${env:HOME}\site\wwwroot\Modules\"
        if (! $(Test-Path $localModulesFolder))
        {
            Write-Error "Can't find [$localModulesFolder] path.]"
            return $result
        }
    }
    If (($builtinModulesFolderPattern -eq $null) -or ($builtinModulesFolderPattern -eq ""))
    {
        Write-Output "No Built-in module path provided."
        $builtinModulesFolderPattern = 'D:\Program Files (x86)\Microsoft SDKs\Azure\PowerShell\*'
    }
    Write-Output "Validating PSModulePath..."

    $modulePathEntries = @($env:PSModulePath -split ';')
    if ($modulePathEntries -notcontains '$localModulesFolder')
    {
        Write-Output "Updating PSModulePath to include [$localModulesFolder]"
        $env:PSModulePath += ";${localModulesFolder}"
        $result = @{Result = $true; Reason = "Updated PSModulePath to include [$localModulesFolder]"}
    }
    else
    {
        Write-Output "PSModulePath already includes [$localModulesFolder]. No modifications needed"
        $result = @{Result = $true; Reason = " PSModulePath already Up to Date"}
    }
    If (($modulePathEntries | % {$_ -like $builtinModulesFolderPattern}) -contains $true)
    {
        Write-Output "Removing Standard Azure RM modules from PSENVPath"
        $env:PSModulePath = ($env:PSModulePath.Split(';') | Where-Object { $_ -notlike $builtinModulesFolderPattern }) -join ';'
    }
    return $result
}