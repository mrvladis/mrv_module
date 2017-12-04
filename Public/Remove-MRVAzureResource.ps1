<#
.Synopsis
Function to delete Resource
.Description
Function to delete Resource
	Limitations
	----------

	Change Log
	----------
	v.1.0.0.0		- Initial Version

	Backlog
	--------

	Output
    Name	            		Value
    ----	            		-----
	Result	            		True / False
    Error               $error

Syntax: Function has the following parameters:
.Parameter ResourceName
Name of the Virtual Machine that need to be deleted.
.Parameter ResourceGroupName
Name of Resource Group forthe Virtual Machine that need to be deleted.


.Example


#>
Function Remove-MRVAzureVM
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $ResourceName,
        [Parameter(Mandatory = $true)]
        [String]
        $ResourceGroupName,
        [Parameter (Mandatory = $true)]
        [ValidateSet('virtualMachines',
            'Disks',
            'NetworkInterfaces'
        )]
        $Resource,
        [Parameter(Mandatory = $false)]
        [Int]
        $TimeOut = 300,
        [Parameter (Mandatory = $false)]
        [switch]
        $Simulate,
        [Parameter(Mandatory = $false)]
        [String]
        $KillTagName = 'KillDate'

    )
    switch ($ResourceType)
    {
        'virtualMachines'
        {
            $ResourceType = 'Microsoft.Compute/virtualMachines'
        }
        'Disks'
        {
            $ResourceType = 'Microsoft.Compute/disks'
        }
        'NetworkInterfaces'
        {
            $ResourceType = 'Microsoft.Network/networkInterfaces'
        }
    }
    $time_start = get-date

}