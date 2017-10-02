<#
.Synopsis
Function to import module by name.


.Description
Script allow to import module by name. It validate if module already installed and return $true if module sucessfully loaded.


	Limitations
	----------

	Change Log
	----------
	v.1.0.0.0		- Initial Version

	Backlog
	--------

	Output
	--------
  As the result of function execution Hash Table returned. This can be ammended.
  It will have the following format:
    Name	            Value
    ----	            -----
    Result	            True / False
    Action	            Connected / Exising Context
    Error               $error[0]
    SubscriptionCode    PRO / DEV


Syntax: Function has the following parameters:

 .Parameter ModuleName
Used to specify a Module you want to load.


 .Example
 Import-MRVModule -ModuleName AzureRM
#>
Function Import-MRVModule
{
    Param(
        [String]
        $ModuleName = $(throw "Please Provide module name!")
    )

    $ModuleLoaded = $false
    $Reason = "Success"
    $Suggestion = ''

    Write-Verbose "Validating existing context to check if module has been already loaded."
    if (!(Get-Module -name $ModuleName -ErrorAction SilentlyContinue))
    {
        Write-Verbose "Module not loaded. Validating if it has been installed"
        if (Get-Module -ListAvailable |
                Where-Object { $_.name -eq $ModuleName })
        {
            Write-Verbose "Module [$ModuleName] has been found. Trying to import."
            try
            {
                Import-Module -Name $ModuleName -ErrorAction SilentlyContinue
            }
            catch
            {
                $reason = "Module [$ModuleName] has been found, but can't be loaded."
                $Suggestion = "Please check the error."
                $result = @{Result = $ModuleLoaded; Reson = $Reason; Error = $($Error[0]); Suggestion = $Suggestion}
                return $result
            }
            $ModuleLoaded = $true
            $result = @{Result = $ModuleLoaded; Reson = $Reason; Error = $($Error[0]); Suggestion = $Suggestion}
            return $result
        }
        else
        {
            Write-Verbose "Module [$ModuleName] has not been found. Checking for something similar..."
            $reason = "Module [$ModuleName] has been found."
            if ($FModules = Get-Module -ListAvailable |
                    Where-Object { $_.name -like "*$ModuleName*" })
            {
                $Suggestion = "Please check if you have meant one of the following modules:"
                foreach ($module in $FModules)
                {
                    $Suggestion += " " + $module.Name + " |"
                }
            }
            else
            {
                $Suggestion = "Please check if module has been installed"
            }
            $result = @{Result = $ModuleLoaded; Reson = $Reason; Error = $($Error[0]); Suggestion = $Suggestion}
            return $result
        }
    }
    else
    {
        $reason = "Module [$ModuleName] is alreasy loaded."
        Write-Verbose $reason
        $ModuleLoaded = $true
        $result = @{Result = $ModuleLoaded; Reson = $Reason; Error = $($Error[0]); Suggestion = $Suggestion}
        return $result
    }
}