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
            $LocationCode = "NEU"
            $Success = $true
        }
        "westeurope"
        {
            $LocationCode = "WEU"
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
        "eastasia"
        {
            $LocationCode = "ASE"
            $Success = $true
        }
        "southeastasia"
        {
            $LocationCode = "ASS"
            $Success = $true
        }
        "centralus"
        {
            $LocationCode = "USC"
            $Success = $true
        }
        "eastus"
        {
            $LocationCode = "USE"
            $Success = $true
        }
        "eastus2"
        {
            $LocationCode = "USE2"
            $Success = $true
        }
        "westus"
        {
            $LocationCode = "USW"
            $Success = $true
        }
        "northcentralus"
        {
            $LocationCode = "USNC"
            $Success = $true
        }
        "southcentralus"
        {
            $LocationCode = "USSC"
            $Success = $true
        }
        "japanwest"
        {
            $LocationCode = "JAW"
            $Success = $true
        }
        "japaneast"
        {
            $LocationCode = "JAW"
            $Success = $true
        }
        "brazilsouth"
        {
            $LocationCode = "BRS"
            $Success = $true
        }
        "australiaeast"
        {
            $LocationCode = "AUE"
            $Success = $true
        }
        "southindia"
        {
            $LocationCode = "INS"
            $Success = $true
        }
        "centralindia"
        {
            $LocationCode = "INC"
            $Success = $true
        }
        "westindia"
        {
            $LocationCode = "INW"
            $Success = $true
        }
        "canadacentral"
        {
            $LocationCode = "CAC"
            $Success = $true
        }
        "canadaeast"
        {
            $LocationCode = "CAE"
            $Success = $true
        }
        "westcentralus"
        {
            $LocationCode = "USWC"
            $Success = $true
        }
        "westus2"
        {
            $LocationCode = "USW2"
            $Success = $true
        }
        "koreacentral"
        {
            $LocationCode = "KOC"
            $Success = $true
        }
        "koreasouth"
        {
            $LocationCode = "KOS"
            $Success = $true
        }
    }
    $result = @{Result = $Success; Error = $Error; LocationCode = $LocationCode}
    return $result
}