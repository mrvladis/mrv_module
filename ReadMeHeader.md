## 1. Executive Summary
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


