<#
.Synopsis
Function to find special storage accounts used by module.
.Description
Script that result with the name of the existing storage accounts and their secrets for Azure VM Diagnostics  and provisioning.
	Limitations
	----------

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
    Name	            		Value
    ----	            		-----
	Result	            		True / False
	StorageAccountName
	StorageAccountKey
    Error               $error

Syntax: Function has the following parameters:
.Parameter
Azure region that is pre-defined within the function.

.Example


#>

Function Get-MRVAzureModuleStorageAccount
{
    param (
        [Parameter(Mandatory = $false)]
        [String]
        $StorageAccountName,

        [Parameter(Mandatory = $false)]
        [ValidateSet('JSON', 'DIAG')]
        [String]
        $AccountType,

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
        $Location,

        [Parameter(Mandatory = $true)]
        $SubscriptionName,

        [Parameter(Mandatory = $false)]
        [string] $Prefix_Main = 'MRV',

        [Parameter(Mandatory = $false)]
        [string] $Prefix_RG = 'RG'

    )
    $Success = $true
    $TagName = 'Purpose'
    $DiagTagValue = 'AzureDiagnostics'
    $JsonTagValue = 'JSONStorage'
    $DiagDescription = 'Resource to host Azure Diagnostic Data. Created by New-MRVAzureVM Function.'
    $JsonDescription = 'Resource to host Json ARM Templates During Provisioning. Created by New-MRVAzureVM Function.'
    $Subscription = Select-MRVSubscription -SubscriptionName $SubscriptionName
    $Tags = @{$TagName = $DiagTagValue; Description = $DiagDescription}
    $LocationCode = (Get-MRVLocationCode $location).LocationCode
    If ($AccountType -eq 'JSON')
    {
        $TagValue = $JsonTagValue
        $Description = $JsonDescription
    }
    elseif ($AccountType -eq 'DIAG')
    {
        $TagValue = $DiagTagValue
        $Description = $DiagDescription
    }
    $Tags = @{$TagName = $TagValue; Description = $Description}
    If ($StorageAccountName -eq 'notdefined')
    {
        Write-Output "Trying to find [$AccountType] Storage account in location [$location]"
        $StorageAccount = Get-AzureRmStorageAccount  |
            Where-Object -FilterScript {
            $_.Tags.Keys -contains $TagName} |
            Where-Object -FilterScript {
            ($_.Tags.GetEnumerator() | Where-Object {$_.Key -like $TagName}).Value -like $TagValue } |
            Where-Object -FilterScript {
            $_.PrimaryLocation -like $location }
    }
    else
    {
        $StorageAccountName = $StorageAccountName.ToLower()
        $StorageAccount = Get-AzureRmStorageAccount | Where-Object StorageAccountName -eq $StorageAccountName
        If ($StorageAccount -eq $null)
        {
            Write-Error "Can't find [$AccountType] Storage account with the name [$StorageAccountName]"
            Write-Error "You can either create it before script execution or do not specify this parameter. Script will find account or create a new one."
        }
        $StorageResourceGroup = $StorageAccount.ResourceGroupName
        $StorageAccountName = $StorageAccount.StorageAccountName
    }

    If ($StorageAccount.Count -ge 1)
    {
        Write-Output "It has been found [$($StorageAccount.count)] storage accounts with [$AccountType] Tags"
        If ($StorageAccount.Count -gt 1)
        {
            $StorageAccount = $StorageAccount[0]
            Write-Output "Selecting the first one with the name [$($StorageAccount.StorageAccountName)]"
        }
        $StorageResourceGroup = $StorageAccount.ResourceGroupName
        $StorageAccountName = $StorageAccount.StorageAccountName
        Write-verbose "Storage account name [$StorageAccountName] in Resource Group  [$StorageResourceGroup] will be used"
    }
    elseif ($StorageAccount.Count -eq 0)
    {
        Write-Output "There is no [$AccountType] storage account found"
        $AccountID = 1
        $StorageAccountName = $($Prefix_Main + 'lrs' + $LocationCode + $AccountType + $AccountID + $Subscription.AzureContext.Subscription.Id).Replace('-', '').ToLower().Substring(0, 23)
        While ((Get-AzureRmStorageAccount | Where-Object StorageAccountName -eq $StorageAccountName) -and $AccountID -lt 10)
        {
            Write-Output "Storage account with name [$StorageAccountName] already exist."
            $AccountID ++
            $StorageAccountName = $($Prefix_Main + 'lrs' + $LocationCode + $AccountType + $AccountID + $Subscription.AzureContext.Subscription.Id).Replace('-', '').ToLower().Substring(0, 23)
        }
        If ($AccountID -eq 10)
        {
            Write-Error "It is more than 10 accounts has been found that meet [$AccountType] name but don't have tags associated. This looks wrong!"
            $Success = $false
        }
        $RGName = $($Prefix_Main + '-' + $Prefix_RG + '-' + $AccountType + $LocationCode).ToUpper()
        If (! (Get-AzureRmResourceGroup -Name $RGName -ErrorAction SilentlyContinue))
        {
            Write-Output "Going to create Resource Group for [$AccountType] Storage account with the name [$RGName]"
            New-AzureRmResourceGroup $RGName -Location $location
        }
        else
        {
            Write-Output "Resource Group for [$AccountType] Storage account with the name [$RGName] already exist"
        }
        Write-Output "Trying to create  [$AccountType] Storage account with the name [$StorageAccountName]"
        $StorageAccount = New-AzureRmStorageAccount -Name $StorageAccountName -ResourceGroupName $RGName -Location $location -SkuName Standard_LRS
        Start-MRVWait -AprxDur 30 -Wait_Activity  "Waiting for ARM sync"
        Write-Output "Setting tags on  [$AccountType] Storage account with the name [$StorageAccountName]"
        Update-MRVAzureTag -ResourceName $StorageAccountName -ResourceGroupName $RGName -SubscriptionName $SubscriptionName -TagsTable $Tags -EnforceTag
        $StorageResourceGroup = $RGName
    }
    $StorageAccountKey = ((Get-AzureRmStorageAccountKey -Name $StorageAccount.StorageAccountName -ResourceGroupName $StorageAccount.ResourceGroupName).GetEnumerator() | Where-Object {$_.KeyName -like 'key1'}).value
    $result = @{Result = $Success; Error = $Error; StorageAccountName = $StorageAccountName; StorageResourceGroup = $StorageResourceGroup; StorageAccountKey = $StorageAccountKey}
    return $result
}