<#
.Synopsis
Function to delete VM and all assosiated componets.
.Description
Function to delete VM and all assosiated componets.
	Limitations
	----------

	Change Log
	----------
	v.1.0.0.0		- Initial Version

	Backlog
	--------

	Output
    Name	            		Value
    ----	            		-----
	Result	            		True / False
    Error               $error

Syntax: Function has the following parameters:
.Parameter VMname
Name of the Virtual Machine that need to be deleted.
.Parameter ResourceGroupName
Name of Resource Group forthe Virtual Machine that need to be deleted.


.Example


#>
Function Remove-MRVAzureVM
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $VMname,
        [Parameter(Mandatory = $true)]
        [String]
        $ResourceGroupName,
        [Parameter(Mandatory = $false)]
        [Int]
        $TimeOut = 300,
        [Parameter (Mandatory = $false)]
        [switch]
        $Simulate,
        [Parameter(Mandatory = $false)]
        [String]
        $KillTagName = 'KillDate'

    )
    $ManagedDisks = $false
    try
    {
        $ResourceGroup = Get-AzureRmResourceGroup -Name $ResourceGroupName
    }
    catch
    {
        Write-Error "Can't find resource group [$ResourceGroupName]"
        return $false
    }
    If ($ResourceGroup -eq $null)
    {
        Write-Error "Can't find resource group [$ResourceGroupName]"
        return $false
    }
    try
    {
        $VM = Get-AzureRmVM -Name $VMname -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
    }
    catch
    {
        Write-Error "Can't find VM [$VMname] within resource group [$ResourceGroupName]"
        return $false
    }
    If ($VM -eq $null)
    {
        Write-Error "Can't find VM [$VMname] within resource group [$ResourceGroupName]"
        return $false
    }

    Write-Verbose "Identifying Boot Diagnostics Information"
    $vmResource = Get-AzureRmResource -ResourceName $VMname -ResourceGroupName $ResourceGroupName -ResourceType 'Microsoft.Compute/virtualMachines'
    $Tags = $vmResource.Tags
    $KillDate = ($Tags.GetEnumerator() | Where-Object {$_.Key -like $KillTagName}).value
    $DiagStorageAccount = [regex]::match($vm.DiagnosticsProfile.bootDiagnostics.storageUri, '^http[s]?://(.+?)\.').groups[1].value
    $DiagContainerName = ('bootdiagnostics-{0}-{1}' -f $vm.Name.ToLower().Replace('-', '').Substring(0, 9), $vmResource.Properties.vmId)
    Write-Verbose "We have identified [$DiagStorageAccount] as Storage account name."
    Write-Verbose "We have identified [$DiagContainerName] as container name."
    try
    {
        $DiagStorageAccountResourceGroup = (Get-AzureRmStorageAccount | where { $_.StorageAccountName -eq $DiagStorageAccount }).ResourceGroupName
    }
    catch
    {
        Write-Error "Can't get boot diagnostics storage account. Can't identify the resource Group."
    }
    if (!$Simulate)
    {
        Write-Verbose "Trying to delete Boot Diagnostic Data"
        try
        {
            Write-verbose "We have Container [$DiagContainerName] Diag Storage Account [$DiagStorageAccount] ResourceGroupName [$DiagStorageAccountResourceGroup] "
            Get-AzureRmStorageAccount -ResourceGroupName $DiagStorageAccountResourceGroup -Name $DiagStorageAccount | Get-AzureStorageContainer | where { $_.Name -eq $DiagContainerName } | Remove-AzureStorageContainer -Force
        }
        catch
        {
            Write-Error "Can't delete boot diagnostics container storage account."
        }

        Write-Verbose "Removing VM"
        $vm | Remove-AzureRmVM -Force
        Start-MRVWait -AprxDur 10 -Wait_Activity "Wait for backend to be updated with VM deletion"
        Write-Verbose "Removing VM Interfaces"
        foreach ($Interface in $VM.NetworkProfile.NetworkInterfaces)
        {
            Write-Verbose "Updating Interfaces KillDate with VM Kill date [$KillDate]"
            $InterfaceResource = Get-AzureRmResource -Id $Interface.Id
            Update-MRVAzureTag -ResourceName $InterfaceResource.Name -ResourceGroupName $InterfaceResource.ResourceGroupName -TagName $KillTagName -TagValue $KillDate -EnforceTag -Verbose
            $i = 0
            $IsRemoved = $false
            While (!$IsRemoved)
            {
                $i ++
                Start-Sleep 1
                Write-Verbose "Tryin to remove iInterface. Attempt [$i]"
                if ($i -gt $TimeOut)
                {
                    Write-Error "Counter [$i] has reached Timeout [$TimeOut]. Exiting."
                    break
                }

                try
                {
                    Remove-AzureRmResource -ResourceId $Interface.Id -Force | Out-Null
                }
                catch
                {
                    continue
                }
                Write-Verbose "Interface removed"
                $IsRemoved = $true
            }
        }
        If ($vm.StorageProfile.OSDisk.ManagedDisk -eq $null)
        {
            Write-verbose "We have VHDs on Storage Account"
            $osDiskUri = $vm.StorageProfile.OSDisk.Vhd.Uri
            $osDiskContainerName = $osDiskUri.Split('/')[-2]
            Write-Verbose "Trying to remove VHD for OS disk"
            $osDiskStorageAcct = Get-AzureRmStorageAccount | where { $_.StorageAccountName -eq $osDiskUri.Split('/')[2].Split('.')[0] }
            $i = 0
            $IsRemoved = $false
            While (!$IsRemoved)
            {
                if ($i -gt $TimeOut)
                {
                    Write-Error "Timeout reached [$i]. Exiting."
                    return $false
                }
                $i ++
                Start-Sleep 1
                Write-Verbose "Tryin to remove VHD. Attempt [$i]"
                try
                {
                    $osDiskStorageAcct | Remove-AzureStorageBlob -Container $osDiskContainerName -Blob $osDiskUri.Split('/')[-1]
                }
                catch
                {
                    continue
                }
                Write-Verbose "VHD removed"
                $IsRemoved = $true
            }
            While (!$IsRemoved)
            {
                if ($i -gt $TimeOut)
                {
                    Write-Error "Timeout reached [$i]. Exiting."
                    return $false
                }
                $i ++
                Start-Sleep 1
                Write-Verbose "Tryin to remove VHD Status. Attempt [$i]"
                try
                {
                    $osDiskStorageAcct | Get-AzureStorageBlob -Container $osDiskContainerName -Blob "$($vm.Name)*.status" | Remove-AzureStorageBlob
                }
                catch
                {
                    continue
                }
                Write-Verbose "VHD Status removed"
                $IsRemoved = $true
            }
        }
        else
        {
            Write-Verbose "VM Uses Managed Disks"
            $ManagedDisks = $true
            Write-Verbose "Updating OS Disks KillDate with VM Kill date [$KillDate]"
            $DiskResource = Get-AzureRmResource  -Id $vm.StorageProfile.OSDisk.ManagedDisk.Id
            Update-MRVAzureTag -ResourceName $DiskResource.Name -ResourceGroupName $DiskResource.ResourceGroupName -TagName $KillTagName -TagValue $KillDate -EnforceTag -Verbose
            Write-verbose "Removing OS Disk"
            $i = 0
            $IsRemoved = $false
            While (!$IsRemoved)
            {
                $i ++
                Start-Sleep 1
                Write-Verbose "Tryin to remove Disk. Attempt [$i]"
                if ($i -gt $TimeOut)
                {
                    Write-Error "Counter [$i] has reached Timeout [$TimeOut]. Exiting."
                    break
                }
                try
                {
                    Remove-AzureRmResource -ResourceId $vm.StorageProfile.OSDisk.ManagedDisk.Id -Force
                }
                catch
                {
                    continue
                }
                Write-Verbose "Disk removed"
                $IsRemoved = $true
            }


        }
        if ($vm.StorageProfile.DataDisks.Count -gt 0)
        {
            Write-Verbose -Message 'Removing data disks...'
            foreach ($disk in $vm.StorageProfile.DataDisks)
            {
                Write-verbose "Removeing Disk [$($disk.Name)]"
                If ($ManagedDisks)
                {
                    Write-Verbose "Updating Data Disks KillDate with VM Kill date [$KillDate]"
                    $DiskResource = Get-AzureRmResource  -Id $disk.ManagedDisk.Id
                    Update-MRVAzureTag -ResourceName $DiskResource.Name -ResourceGroupName $DiskResource.ResourceGroupName -TagName $KillTagName -TagValue $KillDate -EnforceTag -Verbose
                    $i = 0
                    $IsRemoved = $false
                    While (!$IsRemoved)
                    {
                        $i ++
                        Start-Sleep 1
                        Write-Verbose "Tryin to remove Disk. Attempt [$i]"
                        if ($i -gt $TimeOut)
                        {
                            Write-Error "Counter [$i] has reached Timeout [$TimeOut]. Exiting."
                            break
                        }

                        try
                        {
                            Remove-AzureRmResource -ResourceId $disk.ManagedDisk.Id -Force | Out-Null
                        }
                        catch
                        {
                            continue
                        }
                        Write-Verbose "Disk removed"
                        $IsRemoved = $true
                    }
                }
                else
                {
                    $DataDiskStorageAcct = Get-AzureRmStorageAccount | where { $_.StorageAccountName -eq $disk.Vhd.Uri.Split('/')[2].Split('.')[0]}
                    $DataDiskStorageAcct | Remove-AzureStorageBlob -Container $disk.Vhd.Uri.Split('/')[-2] -Blob $disk.Vhd.Uri.Split('/')[-1] -ea Ignore
                }
            }
        }
    }
    else
    {
        Write-verbose "Skipping removal as runing in Simulation Mode"
    }
}