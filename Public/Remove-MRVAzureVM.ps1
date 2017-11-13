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
        [Parameter (Mandatory = $false)]
        [switch]
        $Simulate

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
        Write-Verbose "Removing VM Interfaces"
        foreach ($Interface in $VM.NetworkProfile.NetworkInterfaces)
        {
            Remove-AzureRmResource -ResourceId $Interface.Id -Force
        }

        If ($vm.StorageProfile.OSDisk.ManagedDisk -eq $null)
        {
            Write-verbose "We have VHDs on Storage Account"
            $osDiskUri = $vm.StorageProfile.OSDisk.Vhd.Uri
            $osDiskContainerName = $osDiskUri.Split('/')[-2]
            Write-Verbose "Trying to remove VHD for OS disk"
            $osDiskStorageAcct = Get-AzureRmStorageAccount | where { $_.StorageAccountName -eq $osDiskUri.Split('/')[2].Split('.')[0] }
            $osDiskStorageAcct | Remove-AzureStorageBlob -Container $osDiskContainerName -Blob $osDiskUri.Split('/')[-1]
            $osDiskStorageAcct | Get-AzureStorageBlob -Container $osDiskContainerName -Blob "$($vm.Name)*.status" | Remove-AzureStorageBlob
        }
        else
        {
            Write-Verbose "VM Uses Managed Disks"
            Remove-AzureRmResource -ResourceId $vm.StorageProfile.OSDisk.ManagedDisk.Id -Force
            $ManagedDisks = $true
        }
        if ($vm.StorageProfile.DataDisks.Count -gt 0)
        {
            Write-Verbose -Message 'Removing data disks...'
            foreach ($disk in $vm.StorageProfile.DataDisks)
            {
                Write-verbose "Removeing Disk [$($disk.Name)]"
                If ($ManagedDisks)
                {
                    Remove-AzureRmResource -ResourceId $disk.ManagedDisk.Id -Force
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