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

## Start / Stop Automation
Start / Stop Automation uses Tag with name "Schedule" to operate.
Tag define the schedule for the VM to be up and running over the week. Time is defined for each day and divided by ‘/’ (MON/TUE/WED/THU/SAT/SUN). 
Time frame should have “Start Time” and “Stop Time” divided by “->”. 
Each day can have as many timeframes as needed. 
Time frames are separated with semicolon “;”.
If the there is no need for VM to run on this day tag can be set to ‘-’. It need to have a value.
For example “8:00->19:00” (Start at 8 am stop at 7 pm), “->20:00” (“Start” 00:01 this day. It will keep running. Stop at 8 pm), “7:10->” (Start at 7:10 am and no Stop this day. Will run till 23:59), “08:00->14:00;19:00->22:00” 
Start Stop time should be with the interval 30 minutes.  
Possible values: 
“Start Time->Stop Time”
“Start Time1->Stop Time1;Start Time2->Stop Time2”
“-”
"7:00->21:00/7:00->21:00/7:00->21:00/7:00->21:00/7:00->21:00/-/-"
"9:00->12:00;15:00->19:00/7:00->21:00/7:00->21:00/7:00->21:00/7:00->21:00/-/-"
