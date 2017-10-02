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
Update-MRVzureTag -VMname "MRV-SH-TEST-015" -ResourceGroupName "MRV-RG-TEST-010" -SubscriptionName PROD -TagName "AlwaysOFF" -TagValue '$false'
.Example
To update VM tag "AlwaysOFF" to '$false' using existing Subscription context:
Update-MRVzureTag -VMname "MRV-SH-TEST-015" -ResourceGroupName "MRV-RG-TEST-010" -SkipSubscriptionSelection -TagName "AlwaysOFF" -TagValue '$false'
.Example
Update tag "AlwaysOFF" to '$false' for ALL Vms in the ResourceGroup
Get-AzureRMVM -ResourceGroupName MRV-RG-SQL-005 | % {Update-MRVzureTag -VMname $_.Name -ResourceGroupName $_.ResourceGroupName -SubscriptionName PROD -SkipSubscriptionSelection -TagName "AlwaysOFF" -TagValue '$false'}
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
Update-MRVzureTag -VMname MRV-SH-TEST-010 -ResourceGroupName MRV-RG-TEST-001 -TagsTable  $Tags -SubscriptionName PROD
#>
Function Update-MRVzureTag
{
    Param
    (
        # Virtual Machine name
        [Parameter(ParameterSetName = 'OneTag', Mandatory = $true)]
        [Parameter(ParameterSetName = 'TableTag', Mandatory = $true)]
        [String]
        $VMname,

        # Service name to deploy to
        [Parameter(ParameterSetName = 'OneTag', Mandatory = $true)]
        [Parameter(ParameterSetName = 'TableTag', Mandatory = $true)]
        [String]
        $ResourceGroupName,

        # Type of the VM
        [Parameter(ParameterSetName = 'OneTag', Mandatory = $true)]
        [Parameter(ParameterSetName = 'TableTag', Mandatory = $true)]
        [String]
        $SubscriptionName,


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
    $Subscription = Select-MRVSubscription -SubscriptionName $SubscriptionName
    If (!$Subscription.Result)
    {
        Write-Error 'Make sure that you have access and logged in to Azure'
        return
    }
    else
    {
        Write-Verbose 'Subscription has been selected Sucessfully.'
    }
    Write-Host "Looking for the VM with the name:[$VMname] in ResourceGroup:[$ResourceGroupName]"
    $VM = get-azurermvm -ResourceGroupName  $ResourceGroupName -Name $VMname
    if ($Vm -ne $null )
    {
        Write-Host "VM with the name:[$VMname] have been found in ResourceGroup:[$ResourceGroupName]" -ForegroundColor Green
        $VMres = Get-AzureRmResource -ResourceId $vm.Id
        $Tags = $VMres.Tags
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
                    if ($Tags[$TagName] -eq $TagValue)
                    {
                        Write-Verbose "Tag [$TagName] already has value [$TagValue]. Skipping... "
                    }
                    else
                    {
                        Write-Verbose "Updating the value to:[$TagValue]"
                        $Tags[$TagName] = $TagValue
                    }
                }
                else
                {
                    Write-Verbose "Tag with the name:[$TagName] have not been found."
                    if ($EnforceTag)
                    {
                        Write-Verbose "Enforcing (adding the tag)"
                        $Tags += @{ $TagName = $TagValue; }
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
        Write-host "Trying to update the VM with the new tags.."
        try
        {
            $VMres | Set-AzureRmResource -Tag $Tags -Force
        }
        catch
        {
            Write-Error "Update the VM with the new tags FAILED"
            return $false
        }
        Write-host "Update the VM with the new tags have been sucessfull" -ForegroundColor Green
    }
    else
    {
        Write-Error "VM with the name:[$VMname] have not been found in ResourceGroup:[$ResourceGroupName]"
        return $false
    }
    return $true
}


