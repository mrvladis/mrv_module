Function Set-MRVVMPowerState
{
    param(
        [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()]
        [string]
        $vmId,

        [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()]
        [ValidateSet("Started", "StoppedDeallocated" )]
        [string]
        $DesiredState,

        [Parameter (Mandatory = $false)]
        [switch]
        $Simulate
    )
    $EventAppName = "PowerShellAutomation"
    # Get VM with current status
    Write-Verbose "Getting VM resource with ID $vmId"
    $VirtualMachine = Get-AzureRmResource -ResourceId $vmId
    Write-Verbose "Getting VM with Name [$($VirtualMachine.Name)] from the RG [$($VirtualMachine.ResourceGroupName)]"
    try
    {
        $VM = Get-AzureRmVM  -ResourceGroupName $VirtualMachine.ResourceGroupName -Name $VirtualMachine.Name -Status
    }
    catch
    {
        #Write-EventLog -LogName "Application" -Source "$EventAppName" -EventID 8030 -EntryType Error -Message "Failed to get VM with Name [$($VirtualMachine.Name)] from the RG [$($VirtualMachine.ResourceGroupName)]" -Category 1
        #Write-EventLog -LogName "Application" -Source "$EventAppName" -EventID 8031 -EntryType Error -Message $Error -Category 1
        return
    }

    #return
    $currentStatus = $VM.Statuses | where Code -like "PowerState*"
    $currentStatus = $currentStatus.Code -replace "PowerState/", ""

    # If should be started and isn't, start VM
    if ($DesiredState -eq "Started" -and $currentStatus -notmatch "running")
    {
        if ($Simulate)
        {
            Write-Verbose "[$($VirtualMachine.Name)]: SIMULATION -- Would have started VM. (No action taken)"
        }
        else
        {
            Write-Verbose "[$($VirtualMachine.Name)]: Starting VM"
            try
            {
                $result = $VM | Start-AzureRmVM
            }
            catch
            {
                #Write-EventLog -LogName "Application" -Source "$EventAppName" -EventID 8040 -EntryType Error -Message "[$($VirtualMachine.Name)]: VM Failed to start" -Category 1
                #Write-EventLog -LogName "Application" -Source "$EventAppName" -EventID 8041 -EntryType Error -Message $Error -Category 1
                return
            }
        }
    }
    # If should be stopped and isn't, stop VM
    elseif ($DesiredState -eq "StoppedDeallocated" -and $currentStatus -ne "deallocated")
    {
        if ($Simulate)
        {
            Write-Verbose "[$($VirtualMachine.Name)]: SIMULATION -- Would have stopped VM. (No action taken)"
        }
        else
        {
            Write-Verbose "[$($VirtualMachine.Name)]: Stopping VM due to DesiredState is $DesiredState and currentStatus is $currentStatus and ifAlwaysON is $ifAlwaysON)"
            try
            {
                $result = $VM | Stop-AzureRmVM -Force
            }
            catch
            {
                #Write-EventLog -LogName "Application" -Source $EventAppName -EventID 8050 -EntryType Error -Message "[$($VirtualMachine.Name)]: VM Failed to Stop" -Category 1
                #Write-EventLog -LogName "Application" -Source $EventAppName -EventID 8051 -EntryType Error -Message $Error -Category 1
                return
            }
        }
    }

    # Otherwise, current power state is correct
    else
    {
        Write-Verbose "[$($VirtualMachine.Name)]: Current power state [$currentStatus] is correct."
    }
    [string]$ResultText = $result

    Write-Verbose  "Assesment of VM [$($VirtualMachine.Name)] Finished Successully."
    Write-Verbose  $ResultText
}