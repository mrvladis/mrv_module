<#
 .Synopsis
 Function that can be used to update specific VM Tag.

 .Description
	Function that can be used to update specific VM Tag.
	Function can also create a tag if it does not exist.

  Prequisites - Azure and AzureRM Modules.

  Limitations -


  Change Log
  ----------
  v.1.0.1.0 - Added ParameterSet
  v.1.1.0.0 - Added TagTable Option. You can now push Hash Table as input.
  v.1.1.0.1 - Parameter SkipSubscriptionSelection removed.

  Backlog
  --------


 Syntax: Function has the following parameters:

 .Parameter VMname
Name for the Virtual Machine that will be used to represent the VM in Azure and used as a Computer name.
Should be formatted according to the Naming Convention.
 .Parameter ResourceGroupName
Name for the Resource Group that will represent the service within the Azure and contain all the service elements.
Should be formatted according to the Naming Convention.
 .Parameter SubscriptionName
Used to specify the subscription that the VM belongs to.
 .Parameter TagName
Name of the Tag that needs to be updated.
 .Parameter TagValue
Value for the Tag
 .Parameter EnforceTag
Enforce Tag creation if it does not exist.
 .Parameter TagsTable
Hashtable that contains tags required update.

.Example
To update VM tag "AlwaysOFF" to '$false' specifying Subscription context:
Update-MRVzureTag -ResourceName "MRV-SH-TEST-015" -ResourceGroupName "MRV-RG-TEST-010" -SubscriptionName PROD -TagName "AlwaysOFF" -TagValue '$false'
.Example
To update VM tag "AlwaysOFF" to '$false' using existing Subscription context:
Update-MRVzureTag -ResourceName "MRV-SH-TEST-015" -ResourceGroupName "MRV-RG-TEST-010" -TagName "AlwaysOFF" -TagValue '$false'
.Example
Update tag "AlwaysOFF" to '$false' for ALL Vms in the ResourceGroup
Get-AzureRMVM -ResourceGroupName MRV-RG-SQL-005 | % {Update-MRVzureTag -ResourceName $_.Name -ResourceGroupName $_.ResourceGroupName -SubscriptionName PROD -TagName "AlwaysOFF" -TagValue '$false'}
.Example
Update Set of Tags on one go.
$Tags = @{"Schedule_Monday"="->01:00,02:00->";
			  "Schedule_Tuesday"="->01:00,02:00->";
			  "Schedule_Wednesday"="->01:00,02:00->";
			  "Schedule_Thursday"="->01:00,02:00->";
			  "Schedule_Friday"="->01:00,02:00->";
			  "Schedule_Saturday"="->01:00,02:00->";
			  "Schedule_Sunday"="->01:00,02:00->";
			  "AlwaysOFF"='$false';
			  "AlwaysON"='$false';}
Update-MRVzureTag -ResourceName MRV-SH-TEST-010 -ResourceGroupName MRV-RG-TEST-001 -TagsTable  $Tags -SubscriptionName PROD
#>
Function Update-MRVAzureTag
{
    Param
    (
        [Parameter(ParameterSetName = 'OneTag', Mandatory = $true)]
        [Parameter(ParameterSetName = 'TableTag', Mandatory = $true)]
        [String]
        $ResourceName,

        [Parameter(ParameterSetName = 'OneTag', Mandatory = $false)]
        [Parameter(ParameterSetName = 'TableTag', Mandatory = $false)]
        [String]
        $ResourceGroupName = $null,

        [Parameter(ParameterSetName = 'OneTag', Mandatory = $false)]
        [Parameter(ParameterSetName = 'TableTag', Mandatory = $false)]
        [String]
        $ResourceType = $null,

        [Parameter(ParameterSetName = 'OneTag', Mandatory = $false)]
        [Parameter(ParameterSetName = 'TableTag', Mandatory = $false)]
        [String]
        $SubscriptionName = '',

        [Parameter(ParameterSetName = 'TableTag', Mandatory = $true)]
        [Hashtable]
        $TagsTable,

        [Parameter(ParameterSetName = 'OneTag', Mandatory = $true)]
        [String]
        $TagName,

        [Parameter(ParameterSetName = 'OneTag', Mandatory = $true)]
        $TagValue,

        [Parameter(ParameterSetName = 'OneTag', Mandatory = $false)]
        [Parameter(ParameterSetName = 'TableTag', Mandatory = $false)]
        [switch]
        $EnforceTag
    )
    If ($SubscriptionName -ne '')
    {
        $Subscription = Select-MRVSubscription -SubscriptionName $SubscriptionName
        If (!$Subscription.Result)
        {
            Write-Error 'Make sure that you have access and logged in to Azure'
            return
        }
        else
        {
            Write-Verbose 'Subscription has been selected successfully.'
        }
    }
    else
    {
        Write-Verbose "Subscription Selection has been skipped as no subscription provided."
    }
    Write-Host "Looking for the Resource with the name:[$ResourceName]"
    If ($ResourceGroupName -eq $null)
    {
        $Resources = Get-AzureRmResource  | where-object ResourceName -like $ResourceName
    }
    else
    {
        $Resources = Get-AzureRmResource  | where-object {($_.ResourceName -like $ResourceName) -and ($_.ResourceGroupName -like $ResourceGroupName)}
    }
    If ($Resources.Count -gt 1)
    {
        Write-Error "More than one resource with name [$ResourceName] has been found. Use -verbose to see them."
        Write-Verbose "$Resources"
    }
    elseif ($Resources.Count -eq 0)
    {
        Write-host "Can't find any resources with the name [$ResourceName]"
        return $false
    }
    Write-Host "Resource with the name:[$($Resources.ResourceName)] have been found in ResourceGroup:[$($Resources.ResourceGroupName)]" -ForegroundColor Green
    $Tags = $Resources.Tags
    if ($PsCmdlet.ParameterSetName -ne 'TableTag' )
    {
        $TagsTable = @{$TagName = $TagValue}
    }
    ForEach ($TagName in $TagsTable.Keys)
    {
        $TagValue = $TagsTable.$TagName
        Write-Verbose "Looking for the tag with the name:[$TagName] "
        if ($Tags -ne $null)
        {
            if ($Tags.Keys -contains $TagName)
            {
                Write-Verbose "Tag with the name:[$TagName] have been found."
                if (($Tags.GetEnumerator() | Where-Object {$_.Key -like $TagName}).value -eq $TagValue)
                {
                    Write-Verbose "Tag [$TagName] already has value [$TagValue]. Skipping... "
                }
                else
                {
                    Write-Verbose "Updating the value from [$(($Tags.GetEnumerator() | Where-Object {$_.Key -like $TagName}).value)] to:[$TagValue]"
                    $Tags[($Tags.GetEnumerator() | Where-Object {$_.Key -like $TagName}).Key] = $TagValue
                }
            }
            else
            {
                Write-Verbose "Tag with the name:[$TagName] have not been found."
                if ($EnforceTag)
                {
                    Write-Verbose "Enforcing (adding the tag)"
                    $Tags += @{$TagName = $TagValue; }
                }
                else
                {
                    Write-Host "Tag have not being Enforced. Please use [-EnforceTag] if you want to add a new one" -ForegroundColor Red
                }
            }
        }
        else
        {
            Write-Verbose "Tag with the name:[$TagName] have not been found."
            if ($EnforceTag)
            {
                Write-Verbose "Enforcing (adding the tag)"
                $Tags = @{ $TagName = $TagValue; }
            }
            else
            {
                Write-Host "Tag have not being Enforced. Please use [-EnforceTag] if you want to add a new one" -ForegroundColor Red
            }
        }
    }
    Write-host "Trying to update the Resource with the new tags.."
    try
    {
        $Resources | Set-AzureRmResource -Tag $Tags -Force
    }
    catch
    {
        Write-Error "Update the Resource with the new tags FAILED"
        return $false
    }
    Write-host "Update the Resource with the new tags have been successful" -ForegroundColor Green
    return $true
}


