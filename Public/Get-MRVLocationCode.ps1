<#
.Synopsis
Function result with code for provided Azure Region
.Description
Script that can be used assosiate a code used within object names to represent Azure location (region).
	Limitations
	----------
Set of locations (regions) need to be updated manually both in validation set in parameters aswell as within the function to provide required code value.

	Change Log
	----------
	v.1.0.0.0		- Initial Version

	Backlog
	--------

	Output
	--------
  	As the result of function execution location code returned. If location has not being added - it will return "NA" code.
	Hash Table returned. This can be ammended.
  	It will have the following format:
    Name	            Value
    ----	            -----
	Result	            True / False
	LocationCode		NE / WE / UKS
    Error               $error

Syntax: Function has the following parameters:
.Parameter location
Azure region that is pre-defined within the function.

.Example
 	Get-MRVLocationCode northeurope

#>
Function Get-MRVLocationCode
{
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet('eastasia',
            'southeastasia',
            'centralus',
            'eastus',
            'eastus2',
            'westus',
            'northcentralus',
            'southcentralus',
            'northeurope',
            'westeurope',
            'japanwest',
            'japaneast',
            'brazilsouth',
            'australiaeast',
            'australiasoutheast',
            'southindia',
            'centralindia',
            'westindia',
            'canadacentral',
            'canadaeast',
            'uksouth',
            'ukwest',
            'westcentralus',
            'westus2',
            'koreacentral',
            'koreasouth'
        )]
        [String]
        $Location = "northeurope"
    )
    $LocationCode = "NA"
    $Success = $false
    switch ($location)
    {
        "northeurope"
        {
            $LocationCode = "NE"
            $Success = $true
        }
        "westeurope"
        {
            $LocationCode = "WE"
            $Success = $true
        }
        "uksouth"
        {
            $LocationCode = "UKS"
            $Success = $true
        }
        "ukwest"
        {
            $LocationCode = "UKW"
            $Success = $true
        }
    }
    $result = @{Result = $Success; Error = $Error; LocationCode = $LocationCode}
    return $result
}