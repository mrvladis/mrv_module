Function New-MRVAzureAutomationAccount
{
    [CmdletBinding()]
    Param
    (
        [Parameter(ParameterSetName = 'set1', Mandatory = $true)]
        [String]
        $AutomationAccountName,

        [Parameter(ParameterSetName = 'set1', Mandatory = $true)]
        [String]
        $ResourceGroupName,

        [Parameter(ParameterSetName = 'set1', Mandatory = $true)]
        [String]
        $SubscriptionName
    )
    $ResourceGroupName = $ResourceGroupName.ToUpper()
    
    if ( -not (Get-AzureRmResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue))
    {
        Write-Host  "Resource Group ($ResourceGroupName) was not found! Trying to create it..."
        New-AzureRmResourceGroup -Location $location -Name $ResourceGroupName
        Start-MRVWait -AprxDur 5 -Wait_Activity "Waiting for Resource Group to propagate"
    }
    else
    {
        Write-Host  "Resource Group ($ResourceGroupName) has been found!"
    }
    $DeploymentName = $timestamp + '-' + $ResourceGroupName + '-Dep-' + $VMname




}