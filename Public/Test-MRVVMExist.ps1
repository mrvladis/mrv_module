<#
.Synopsis
Script that can be used to validate VM existance.
.Description
Script that can be used to validate VM existance.  It can be sun within the existing context or across provided list of subscriptions.
It utilise select-mrvsubscription to jump across subscriptions.

Prequisites - Azure and AzureRM Modules.

	Limitations
	----------


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
    Action	            Connected / Exising Context
    Error               $error[0]
    SubscriptionName    PRO / DEV


Syntax: Function has the following parameters:
.Parameter Name
Name of the VM that need to be checked.

 .Parameter SubscriptionNames
Used to specify the subscription you want to look into.
It can be left empry to validate within existing context.
Subscription names can be provided as array.
MSDN_02,MSDN_01

 .Parameter AllSubscriptions
Switch that can be used to check in all subscriptions that you have access to.

 .Example
 Select-Test-MRVVMExist -Name MRV-SH-SQL-001
 .Example
 Select-Test-MRVVMExist -Name MRV-SH-SQL-001 -SubscriptionName MSDN_02,MSDN_01
 .Example
 Select-Test-MRVVMExist -Name MRV-SH-SQL-001 -AllSubscriptions

#>
Function Test-MRVVMExist
{
    Param(
        [Parameter(ParameterSetName = 'ExistingContext', Mandatory = $true)]
        [Parameter(ParameterSetName = 'SpecificSubscriptions', Mandatory = $true)]
        [Parameter(ParameterSetName = 'AllSubscription', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name = $(throw "Please Provide the name for a VM!"),

        [Parameter(ParameterSetName = 'SpecificSubscriptions', Mandatory = $true)]
        [Parameter(ParameterSetName = 'AllSubscription', Mandatory = $false)]
        [string[]]
        $SubscriptionNames,

        [Parameter(ParameterSetName = 'AllSubscription', Mandatory = $true)]
        [switch]
        $AllSubscriptions
    )
    $VmExist = $false
    $SubscriptionCode = @()
    $SubscriptionName = @()
    $AzureContext = @()
    $LogedIn = $false
    switch ($PsCmdlet.ParameterSetName)
    {
        'ExistingContext'
        {
            $Context = Get-AzureRmContext -ErrorAction SilentlyContinue
            If ($Context.Subscription.Name -ne '')
            {
                Write-Verbose "We currently in [$($Context.Subscription.Name)]. Let's re-validate the context."
                $Context = Select-MRVSubscription -SubscriptionName $($Context.Subscription.Name)  -ErrorAction SilentlyContinue
                $LogedIn = $Context.Result
            }
            else
            {
                Write-Error "Can't see any existing context. Please either specify Subscription Name or login first."
                $Reason = "SuccessCan't see any existing context"
            }
            If ($LogedIn)
            {
                if (Get-AzureRMVM | Where-Object { $_.name -eq $name })
                {
                    Write-Verbose "VM [$name] has been found in subscription [$($Context.AzureContext.Subscription.Name)]"
                    $VmExist = $true
                    $SubscriptionCode += $Context.AzureContext.Subscription.Name
                    $SubscriptionName += $Context.SubscriptionCode
                    $AzureContext += $Context.AzureContext
                    $Reason = "VM has been Found"
                }
                else
                {
                    Write-Verbose "VM [$name] has not been found in subscription [$($Context.AzureContext.Subscription.Name)]"
                    $Reason = "VM Not Found"
                }
            }
            else
            {
                Write-Error "Not sure how we get there, but can't confirm that we are logged in at all..."
            }

        }
        'SpecificSubscriptions'
        {
            Write-Verbose "We have [$($Subscriptions.Count)] to validate."
            Foreach ($Sub in $Subscriptions)
            {
                Write-Verbose "Let's check if subscription [$Sub] is valid and accessible"
                $Context = Select-MRVSubscription -SubscriptionName $($Context.Subscription.Name)
                if ($Context.Result)
                {
                    Write-Verbose "Let's check if VM exist in in subscription [$Sub]"
                    $VmSearch = Test-MRVVMExist -Name $Name
                    If ($VmSearch.Result)
                    {
                        Write-Verbose "VM [$name] has been found in subscription [$($Context.AzureContext.Subscription.Name)]"
                        $VmExist = $true
                        $SubscriptionCode += $VmSearch.AzureContext.Subscription.Name
                        $SubscriptionName += $VmSearch.SubscriptionCode
                        $AzureContext += $VmSearch.AzureContext
                        $Reason = $VmSearch.Reason
                    }
                    else
                    {
                        Write-Verbose "VM [$name] has not been found in subscription [$($Context.AzureContext.Subscription.Name)]"
                        $Reason = "VM Not Found"
                    }
                }
                else
                {
                    Write-Error "Can't select subscription [$Sub]! Check if it is valid and accessible."
                }
            }

        }
        'AllSubscription'
        {
            Write-Verbose "We need to check through all available subscriptions. Let's get the List of those."
            $Subscriptionlist = @()
            $SubscriptionNames = @()
            $Context = Get-AzureRmContext -ErrorAction SilentlyContinue
            If ($Context.Subscription.Name -ne '')
            {
                Write-Verbose "We currently in [$($Context.Subscription.Name)]. Let's re-validate the context."
                $Context = Select-MRVSubscription -SubscriptionName $($Context.Subscription.Name)
                $LogedIn = $Context.Result
            }
            else
            {
                Write-Error "Can't see any existing context. Please either specify Subscription Name or login first."
                $Reason = "SuccessCan't see any existing context"
            }
            if ($LogedIn)
            {
                Write-Verbose "Looks we are logged in, lets get a list of subscription names"
                $Subscriptionlist = Get-AzureRmSubscription -ErrorAction SilentlyContinue
                If ($Subscriptionlist -ne $null)
                {
                    $SubscriptionNames = ($Subscriptionlist | select Name).name
                    If ($SubscriptionNames.Count -gt 0)
                    {
                        Write-Verbose "We have got [$($SubscriptionNames.Count)] Subscription Names. Let's process them."
                        $VmSearch = Test-MRVVMExist -Name $Name -SubscriptionNames $SubscriptionNames
                        if ($VmSearch.Result)
                        {
                            $VmExist = $true
                            $SubscriptionCode += $VmSearch.AzureContext.Subscription.Name
                            $SubscriptionName += $VmSearch.SubscriptionCode
                            $AzureContext += $VmSearch.AzureContext
                            $Reason = $VmSearch.Reason
                        }
                    }
                }
            }

        }
    }
    $result = @{Result = $VmExist; SubscriptionCode = $SubscriptionCode; SubscriptionName = $SubscriptionName; Reason = $Reason; Error = $Error; AzureContext = $AzureContext}
    return $result
}