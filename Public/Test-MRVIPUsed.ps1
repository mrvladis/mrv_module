<#
.Synopsis
Script to verify if IP address is already in use in Azure.
.Description
Script checks IP address is already in use within the existing Azure Context

Prerequisites - Azure and AzureRM Modules.

	Limitations
	----------


	Change Log
	----------
	v.1.0.0.0		- Initial Version

	Backlog
	--------

	Output
	--------
  As the result of function execution function returns $true if IP address already in use and $false if is it not used

Syntax: Function has the following parameters:

 .Parameter IPAddress
Credentials passed as PS object that can be used to sign-in to Azure

 .Example
 Test-MRVIPUsed -IPAddress 10.20.1.10

#>
Function Test-MRVIPUsed
{
    Param(
        [ValidateNotNullOrEmpty()]
        [string]
        $IPAddress = $(throw "Please Provide Ip Address")
    )
    if (Get-AzureRmNetworkInterface | ForEach-Object { $_.IpConfigurations} | Where-Object {$_.PrivateIpAddress -like ($IPAddress)})
    {
        return $true
    }
    else
    {
        return $false
    }
}
