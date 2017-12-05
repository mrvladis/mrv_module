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
Function Remove-MRVAzureResource
{
    [CmdletBinding()]
    Param
    (
        [Parameter(ParameterSetName = 'ResourceByName', Mandatory = $true)]
        [String]
        $ResourceName,

        [Parameter(ParameterSetName = 'ResourceByName', Mandatory = $true)]
        [String]
        $ResourceGroupName,

        [Parameter(ParameterSetName = 'ResourceByName', Mandatory = $true)]
        [ValidateSet('virtualMachines',
            'Disks',
            'NetworkInterfaces'
        )]
        $ResourceType,

        [Parameter(ParameterSetName = 'ResourceByObject', Mandatory = $true)]
        [pscustomobject]
        $Resource,

        [Parameter(ParameterSetName = 'ResourceByName', Mandatory = $false)]
        [Parameter(ParameterSetName = 'ResourceByObject', Mandatory = $false)]
        [Int]
        $TimeOut = 300,

        [Parameter(ParameterSetName = 'ResourceByName', Mandatory = $false)]
        [Parameter(ParameterSetName = 'ResourceByObject', Mandatory = $false)]
        [switch]
        $Simulate,

        [Parameter(ParameterSetName = 'ResourceByName', Mandatory = $false)]
        [Parameter(ParameterSetName = 'ResourceByObject', Mandatory = $false)]
        [String]
        $KillTagName = 'KillDate'

    )
    $time_start = get-date
    $IsToBeDeleted = $False
    switch ($PsCmdlet.ParameterSetName)
    {
        'ResourceByName'
        {
            switch ($ResourceType)
            {
                'virtualMachines'
                {
                    $ResourceTypeFull = 'Microsoft.Compute/virtualMachines'
                }
                'Disks'
                {
                    $ResourceTypeFull = 'Microsoft.Compute/disks'
                }
                'NetworkInterfaces'
                {
                    $ResourceTypeFull = 'Microsoft.Network/networkInterfaces'
                }
            }
            try
            {
                $Resource = Get-AzureRmResource -ResourceName $ResourceName -ResourceGroupName $ResourceGroupName -ResourceType $ResourceTypeFull
            }
            catch
            {
                Write-Error "Can't find resource with Name [$ResourceName] Resource Group Name [$ResourceGroupName] of Resource Type [$ResourceTypeFull]"
                return $false
            }
            if ($Resource -eq $null)
            {
                Write-Error "Can't find resource with Name [$ResourceName] Resource Group Name [$ResourceGroupName] of Resource Type [$ResourceTypeFull]"
                return $false
            }
        }
        'ResourceByObject'
        {
            $ResourceTypeFull = $Resource.ResourceType
            $Resource = Get-AzureRmResource -ResourceId $Resource.ResourceId
        }
    }
    Write-Verbose "Validating resource of [$ResourceTypeFull] type for deletion"
    switch ($ResourceTypeFull)
    {
        'Microsoft.Compute/virtualMachines'
        {
            Write-Error "To remove VM - Please use Remove-MRVAzureVM instead."
            return $false
        }
        'Microsoft.Compute/disks'
        {
            Write-Verbose "Preparing to delete resource [$($resource.Name)]"
            if ($resource.Properties.diskState -like 'Unattached')
            {
                Write-Verbose "Resource is not in use. Scheduling for deletion..."
                $IsToBeDeleted = $true
            }

        }
        'Microsoft.Network/networkInterfaces'
        {
            Write-Verbose "Preparing to delete resource [$($resource.Name)]"
            $Iface = $Resource | Get-AzureRmNetworkInterface
            If ($Iface.VirtualMachine -eq $null)
            {
                Write-Verbose "Resource is not in use. Scheduling for deletion..."
                $IsToBeDeleted = $true

            }
        }
    }

    If ($IsToBeDeleted)
    {
        try
        {
            if ($Simulate)
            {
                Write-Verbose "Runing in Simulation. Skipping Deletion"
            }
            else
            {
                Write-Verbose "Trying to Delete"
                Remove-AzureRmResource -ResourceId $resource.ResourceId -Force | Out-Null
            }

        }
        catch
        {
            Write-error "Removal of the $ResourceTypeFull [$($resource.ResourceName)] has failed."
            return $false
        }
        return $true
    }
    else
    {
        Write-Error "$ResourceTypeFull [$($resource.ResourceName)] is in use."
        return $false
    }
}