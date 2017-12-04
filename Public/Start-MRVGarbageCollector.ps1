Function Start-MRVGarbageCollector
{
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $SubscriptionName = $(throw "Please Provide the Subscription name!"),

        [Parameter (Mandatory = $true)]
        $Connection = $(throw "Please Provide Connection to Azure"),

        [Parameter (Mandatory = $true)]
        [ValidateSet('virtualMachines',
            'Storage'
        )]
        $ResourceName,
        [Parameter (Mandatory = $false)]
        [switch]
        $Simulate,
        [Parameter(Mandatory = $false)]
        [Int]
        $TimeOut = 300
    )
    $Subscription = Select-MRVSubscription -SubscriptionName $SubscriptionName
    if (!$($Subscription.result))
    {
        Write-Error "Can't select Subscription [$SubscriptionName]"
    }
    switch ($ResourceName)
    {
        'virtualMachines'
        {
            $ResourceType = 'Microsoft.Compute/virtualMachines'
        }
        'Storage'
        {

        }
    }
    $time_start = get-date
    $Resources = Find-AzureRmResource -ResourceType $ResourceType
    $ResourcesToDelete = @()
    Foreach ($Resource in $Resources)
    {
        Write-Verbose "Processing Resource [$($Resource.Name)]"
        If ($Resource.Tags -ne $null)
        {
            Write-Verbose "Resource has some Tags, lets see if it is time to Kill it."
            $killdate = ($Resource.Tags.GetEnumerator() | Where-Object {$_.Key -like "KillDate"}).value
            If (($killdate -ne $null) -and ($killdate -notlike 'none'))
            {
                Write-Verbose "Processing Resource [$($Resource.Name)] has KillDate [$killdate]"
                If ($killdate -notlike 'none')
                {
                    If ($(get-date) -ge $(get-date -Year $killdate.Split('-')[0] -Month $killdate.Split('-')[1] -Day $killdate.Split('-')[2] -Hour $(if ($killdate.Split('-')[3] -eq $null) {'00'} else {$killdate.Split('-')[3]}) -Minute $(if ($killdate.Split('-')[4] -eq $null) {'00'} else {$killdate.Split('-')[4]})))
                    {
                        Write-Verbose "Resource [$($Resource.Name)] KillDate [$killdate] falling before today date [$(get-date)]. Adding it to the list for deletion."
                        $ResourcesToDelete += $Resource
                    }
                    else
                    {
                        Write-Verbose "Resource [$($Resource.Name)] KillDate [$killdate] is after the  [$(get-date)].  SKipping this resource Deletion."
                    }
                }
            }
            else
            {
                Write-Verbose "KillDate Value [$killdate]  does not fall under current Garbage Collection"
            }

        }
    }
    Write-Verbose "We have [$($ResourcesToDelete.Count)] to delete"

    switch ($ResourceName)
    {
        'virtualMachines'
        {
            Foreach ($Resource in $ResourcesToDelete)
            {
                Write-Verbose "Deleting VM [$($Resource.Name)] in ResourceGroup [$($Resource.ResourceGroupName)]"
                $scriptBlock = {
                    Param($Resource, $Simulate, $Connection, $SubscriptionName)
                    Write-Verbose "VM ID [$($VM.Id)]"
                    Add-AzureRMAccount -ServicePrincipal -Tenant $Connection.TenantID -ApplicationID $Connection.ApplicationID -CertificateThumbprint $Connection.CertificateThumbprint
                    Import-Module mrv_module
                    $Subscription = Select-MRVSubscription -SubscriptionName $SubscriptionName
                    If ($Subscription.result)
                    {
                        Remove-MRVAzureVM -VMname $Resource.Name -ResourceGroupName $Resource.ResourceGroupName -Verbose -Simulate:$Simulate -TimeOut $TimeOut
                    }
                    else
                    {
                        Write-Error "Failed to select Subscription [$SubscriptionName] due to [$($Subscription.reason)]"
                    }
                }
                $jobParams = @{
                    'ScriptBlock'  = $scriptBlock
                    'ArgumentList' = @($Resource, $Simulate, $Connection, $SubscriptionName)
                    'Name'         = [string]$jobname
                }
                Start-Job @jobParams
            }

        }

        'Storage'
        {

        }
    }
    $MaxWaitSec = 2400
    $WaitingSec = 0
    $JobsRCount = (Get-Job -State Running).count
    While ($JobsRCount -gt 0)
    {
        Start-Sleep 1
        $WaitingSec ++
        if ($WaitingSec % 60 -eq 0)
        {
            Write-verbose "Waiting for [$($WaitingSec /60)] minutes. [$JobsRCount] still runing. Runbook started at [$currentTime] for Subscription [$SubscriptionName]"
        }
        If ($WaitingSec -le $MaxWaitSec)
        {
            $JobsRCount = (Get-Job -State Running).count
        }
        else
        {
            Write-Host "MaxWaitSec [$MaxWaitSec] reached. Exiting...."
            $JobsRCount = 0
        }
    }
    If ((Get-Job -State Failed).count -ne 0)
    {
        foreach ($FailedJob in (Get-Job -State Failed))
        {
            [String]$FailedJobContent = $FailedJob | Receive-Job
            $Message = "Job [$($FailedJob.name)] has failed. Runbook started at [$time_start] for Subscription [$SubscriptionName]"
            Write-Verbose $Message
            Write-Verbose $FailedJobContent
        }
    }
    Get-Job | Receive-Job
    $time_end = Get-date
    Write-Verbose  "Deployment finished at [$time_end]"
    Write-Verbose  "Deployment has been running for $(($time_end - $time_start).Hours) Hours and $(($time_end - $time_start).Minutes) Minutes"
}
