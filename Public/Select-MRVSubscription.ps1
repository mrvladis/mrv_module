<#
.Synopsis
Subscription selection function with additional values returned based on selection. Please update the list of subscriptions / regions and any returned values, so the meet the requirements of your environemnt.
.Description
Script verify existing Azure context and sign-in to Azure if not yet signed in providing set of subscription or region dependant values as output.
You can configure Active Directory Server names, that can be used by any other script requires interaction with AD. This will allow to avoid any AD replication issues during those groups adding to the local groups on the server.
Subscription Code, that would be used in any Azure object name within selected subscription to meet naming convention.
You can amend the set of parameters and their values to meet the requirements of your environment.

Prerequisites - Azure and AzureRM Modules.

	Limitations
	----------
    LiveID credentials not supported to be passed as parameter. / https://github.com/Azure/azure-powershell/issues/4386

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
    Action	            Connected / Existing Context
    Error               $error[0]
    SubscriptionCode    PRO / DEV


Syntax: Function has the following parameters:

 .Parameter SubscriptionName
Used to specify the subscription you want to switch too.
Please update the validation list below with the subscription name you have, like in example below:
MSDN_02,MSDN_01

 .Parameter Credentials
Credentials passed as PS object that can be used to sign-in to Azure

.Parameter Location
Azure region

 .Example
 Select-mrvSubscription -SubscriptionName MSDN_01
 .Example
 Select-mrvSubscription -SubscriptionName MSDN_02 -location northeurope

#>
Function Select-MRVSubscription
{
    param (
        [Parameter(ParameterSetName = 'InteractiveLogin', Mandatory = $true)]
        [Parameter(ParameterSetName = 'CredentialsLogin', Mandatory = $true)]
        [Parameter(ParameterSetName = 'SPNLogin', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $SubscriptionName = $(throw "Please Provide the name for Subscription!"),

        [Parameter(ParameterSetName = 'InteractiveLogin', Mandatory = $false)]
        [Parameter(ParameterSetName = 'CredentialsLogin', Mandatory = $false)]
        [Parameter(ParameterSetName = 'SPNLogin', Mandatory = $false)]
        [ValidateSet('eastasia',
            'southeastasia',
            'centralus',
            'eastus',
            '  ',
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
        $Location = "northeurope",

        [Parameter(ParameterSetName = 'CredentialsLogin', Mandatory = $true)]
        [Parameter(ParameterSetName = 'SPNLogin', Mandatory = $true)]
        [Management.Automation.PSCredential]
        $Credentials = $null,

        [Parameter(ParameterSetName = 'SPNLogin', Mandatory = $true)]
        [switch]
        $ServicePrincipal,

        [Parameter(ParameterSetName = 'SPNLogin', Mandatory = $false)]
        [string]
        $TenantID = "NotConfigured"

    )
    # Initial values for variables. Please Update them here.
    $NEADDS = @("MRV-SH-ADDS-201.MRVLAB.CO.UK", "MRV-SH-ADDS-202.MRVLAB.CO.UK")
    $WEADDS = @("MRV-SH-ADDS-001.MRVLAB.CO.UK", "MRV-SH-ADDS-002.MRVLAB.CO.UK")
    $UKADDS = @("MRV-SH-ADDS-101.MRVLAB.CO.UK", "MRV-SH-ADDS-102.MRVLAB.CO.UK")


    $LoggedIn = $false
    [array]$ADDSServers = @()
    $SubscriptionCode = 'NotSelected'
    $Reason = 'Unknown'

    $AzureContext = Get-AzureRmContext -ErrorAction SilentlyContinue
    If ($AzureContext -ne $null)
    {
        if ($AzureContext.Environment -ne $null)
        {
            $LoggedIn = $true
        }
    }
    if (!$LoggedIn)
    {
        Write-Verbose "Looks Like You have not logged into Azure"
        Write-Verbose "Let's try to login...."
        switch ($PsCmdlet.ParameterSetName)
        {
            'InteractiveLogin'
            {
                $AzureContext = Login-AzureRmAccount -ErrorAction SilentlyContinue
            }
            'CredentialsLogin'
            {
                $AzureContext = Login-AzureRmAccount -Credential $Credentials -ErrorAction SilentlyContinue
            }
            'SPNLogin'
            {
                $AzureContext = Login-AzureRmAccount -Credential $Credentials -ServicePrincipal -TenantId $TenantID -ErrorAction SilentlyContinue
            }
        }
        If ($AzureContext -ne $null)
        {
            Write-Verbose "We have something in context. Need to check if we have Environement."
            if ($AzureContext.Environments -ne $null)
            {
                Write-Verbose "It looks we have logged in. There are [$($AzureContext.Environments.count)]"
                $LoggedIn = $true
            }
            else
            {
                Write-Verbose "Looks strange, but I can't see any Environment. Does this account has access to any?"
                Write-Verbose "Context we have got:"
                $AzureContext
                Write-Verbose "Environments:"
                Write-Verbose "[$($AzureContext.Environments)]"

            }
        }
        else
        {
            Write-Verbose "Can't see anything in the Context. Looks login has failed."
        }
    }
    else
    {
        $Reason = "Can't not log in to Azure"
    }
    If ($LoggedIn)
    {
        Write-Verbose "Trying to select [$SubscriptionName] Azure Subscription"
        If ($AzureContext.Subscription.Name -ieq $SubscriptionName)
        {
            Write-Verbose "We are already in the proper Context. There is no need to change anything"
        }
        else
        {
            if (!(Select-AzureRMSubscription -SubscriptionName $SubscriptionName))
            {
                Write-Error "Can't select subscription [$SubscriptionName]. Make sure that you have access and logged in to Azure"
                $Reason = "Can't select subscription [$SubscriptionName]"
                $LoggedIn = $false
                $result = @{Result = $LoggedIn; ADDSServers = $adservers; SubscriptionCode = $SubscriptionCode; Reson = $Reason; Error = $($Error[0]); AzureContext = $AzureContext}
                return $result
            }
        }
        Write-Verbose "Populating variables for [$SubscriptionName] Azure Subscription in [$location] region."
        #This is the place to populate subscription agnostic common variables that can be amended below, in subscription section.
        if ($location -like "northeurope")
        {
            $adservers = $NEADDS
        }
        elseif ($location -like "westeurope")
        {
            $adservers = $WEADDS
        }
        elseif ($location -like "uksouth")
        {
            $adservers = $UKADDS
        }
        elseif ($location -like "ukwest")
        {
            $adservers = $UKADDS
        }
        <#Don't forget to update subscription names, codes and return object values below:
====> <=====
#>
        switch ($SubscriptionName)
        {
            "MSDN_01"
            {
                $SubscriptionCode = "DEV"
                Write-Verbose "Code for [$SubscriptionName] Azure Subscription set as  [$SubscriptionCode]"
            }
            "MSDN_02"
            {
                $SubscriptionCode = "TST"
                Write-Verbose "Code for [$SubscriptionName] Azure Subscription set as  [$SubscriptionCode]"
            }
            "mr.vladis_Cloud_Essentials"
            {
                $SubscriptionCode = "PRO"
                Write-Verbose "Code for [$SubscriptionName] Azure Subscription set as  [$SubscriptionCode]"
            }
        }
        $Reason = "Success"
    }
    $result = @{Result = $LoggedIn; ADDSServers = $adservers; SubscriptionCode = $SubscriptionCode; Reason = $Reason; Error = $($Error[0]); AzureContext = $AzureContext}
    return $result
}