﻿## 1. Executive Summary
* In order to simplify the Scripting in the Azure environment and cover standard operations that are used during the scripts implementation the following document will contain the information related to the module.

## 2. Dependencies
* Azure PowerShell NetCore modules (find-module *azure*netcore*  | Install-Module -Scope CurrentUser)
* Azure CLI 2.0

## 3. Installation 
* To install module need to be copied in one of the PowerShell modules locations:
*  Windows:
  C:\Program Files\WindowsPowerShell\Modules  
*  MacOS:  
  /Users/%Username%/.local/share/powershell/Modules/

*  Updates
  If updating the module while having the active PowerShell Session don't forget to reload the module: 
  Remove-Module mrv_module
  Import-Module mrv_module  

## 4. Exploring the Cmdlets
* To get a list of Functions installed run: 

  Get-Command -Module mrv_module | Sort Name

    GetHelp -Detailed FunctionName 




| Cmdlet       | Summary           |
|------------- |-------------------|
| New-MRVAzureVM|Function to create standartized VM from ANY Azure Market image|
| Get-MRVLocationCode|Function result with code for provided Azure Region|
| Import-MRVModule|Function to import module by name.|
| Select-MRVSubscription|Subscription selection function with additional values returned based on selection. Please update the list of subscriptions / regions and any returned values, so the meet the requirements of your environemnt.|
| Start-MRVWait|Function to wait specified amount of time, providing a description of the wait activity.|
| Start-MRVWaitVM|Function to verify required connectivity to the VM.|
| Test-MRVCredentials|Function to verify credentials against domain that server used to execute is member of.|
| Test-MRVIPUsed|Script to verify if IP address is already in use in Azure.|
| Test-MRVTCPPort|Script that can be used to validate connectivoty to specific port.|
| Test-MRVVMExist|Script that can be used to validate VM existance.|

