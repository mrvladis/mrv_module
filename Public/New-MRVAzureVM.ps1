<#
.Synopsis
	Script to create a VM (s) in Azure according stardards and perfporm after deployment tasks.
.Description
    Script will connect to the closet domain controller to perform any AD related activities. Domain controllers returned as part of the subscription selection.
    Please customise Select-MRVSubscription to specify relevant AD DS Servers.
	Note! Cmdlet require ARM Templates to be stored in the module folder.
	Organizational Unit (OU) corresponding to the Resource Group name will be created under OU specified in AzureServersBaseOU parameter if it does not exist.
	WinRM will be configured on the server to run on port 5986 with self-signed certificate.
	Data disk will be provisioned if has not been excluded during provisioning. Script will check for RAW partitions with 100 GB size. They will be initialized, formatted and Disk Drives will be assigned. Any CD/DVD drives will be moved to Drive Letter O and further.
	Time zone will be set to "GMT Standard Time"

    Prequisites
    * AzureRM  or AzureRM.Netcore Module.
    * Azure CLI 2.0 required to provide cross patform compatibility.

  Limitations -
    * If executed from none-Windows environement any Active Directory actions will be skipped as Active Directory cmdlets are currently unavailable from Linux or MacOS.

  Change Log
  ----------
  v.1.0.0.0		- Moved history of the changes here

  Backlog
  --------
AttachDataVHDs - need to be added with the support of managed disks.
Backup - add vm to Azure Backup upon creation.


Syntax: Function has the following parameters:

 .Parameter VMname
Name for the Virtual Machine that will be used to represent the VM in Azure and used as a Computer name.
Should be formatted according to the Naming Convention.
 .Parameter ResourceGroupName
Name for the Resource Group that will represent the service within the Azure and contain all the service elements.
Should be formatted according to the Naming Convention.

 .Parameter SubscriptionName
Used to specify the subscription that the VM belongs to.

 .Parameter VMIPaddresses
Specifies the IP addresses that is going to be used by VM.
Can Accept one or multiple comma separated values. Examples:
 -VMIPaddresses “192.168.0.1” or -VMIPaddresses 192.168.0.1, 192.168.0.2, 192.168.0.3
Note!  If supplying multiple IP addresses -  IfaceCount parameter should be used and provide the number of IP addresses.
Script will look for the Virtual Networks and their subnets to identify it based on the IP address.
Note!  Subnet should be created before trying to provision VM.
Scrip will verify that IP address is free to use.

 .Parameter ChangeControl
Reference to the Change Control in Service Now that has been raised to provision the VM.
 .Parameter Description
Text Description that will be helpful to identify the provisioned VM.
You can receive the following error during such a deployment:
“New-AzureRmResourceGroupDeployment : 11:59:31 AM - Creating a virtual machine from Marketplace image requires Plan information in the request. OS disk name is mrv-sh-hi-001-osdisk.”
Note! Use this switch to try to deploy with the default Plan.

 .Parameter VMSize
Size of the Azure VM. Must be one of the standard values.

 .Parameter ASID
Availability Set ID. Should be provided in format XX where X is any number.

 .Parameter IfaceCount
Number of the Network Interfaces that needed for the VM.
Note!  If IfaceCount used and values id more than 1 - multiple IP addresses need to be supplied in VMIPaddresses parameter.
Note!  VM should meet the requirements for the Multi-Interface VM.

 .Parameter StorageAccountType
Can be used to override default value: Standard_LRS (Locally Redundant)
Can be one of the following values:
'Standard_LRS',
'Standard_GRS',
'Premium_LRS',
'Standard_RAGRS'

 .Parameter Override
Use this option to override any existing deployment.

 .Parameter StandaloneVM
VM will be deployed as standalone. It will not be joined to the domain and no access groups will be created.

 .Parameter SourceVM
Virtual machine name (Short name, eg MRV-SH-MGMT-001) should be provided.
Note!  VM should be accessible from the server script is running on ports 5985 and 5986 (Remote WMI)

 .Parameter SourceXML
Same logic ad with the SourceVm, but Roles and Features XML need to be prepared first.

 .Parameter Simulate
This parameter is used to go through the parameters population and validation, but will skip any deployment. Meanwhile, the deployment configuration will still be uploaded to Azure Blob Storage.

 .Parameter ManagedDisks
This is a switch to use if VM need to be deployed with Managed Disks.

 .Parameter UseExistingDisk
Used to create a Virtual Machine from the existing VHD disk.
Disk should be placed in to the proper storage account (according to the parameters you are using during the deployment) and be named properly.
Note!  You can use “-simulate” to check for the proper names of the system disk and storage account name!
Simulation will also create the Resource Group if it does not exist before.
Note! Storage account need to be created in the Resource Group before copying the VHD. Use ARM_Copy_VHD to perform the copy of the VM VHD disks.
Note!  Virtual Machine will be provisioned without data disks! They need to be attached later manually!
Note! Some provisioning steps will be skipped due to the fact that VM will be created from the existing one.

 .Parameter ImageSKU
You can specify SKU you want to use for the deployment.
"2012-R2-Datacenter" used by default. Please see below for details.

 .Parameter imagePublisher
You can specify Publisher you want to use for the deployment.
"MicrosoftWindowsServer" used by default. Please see below for details.

 .Parameter imageOffer
You can specify Offer you want to use for the deployment.
"WindowsServer" used by default. Please see below for details.
Note!
$loc – Azure Location (Get-AzureRMLocations)
$loc = "northeurope"
#Find all the available publishers
Get-AzureRMVMImagePublisher -Location $loc | Select PublisherName
#Pick a publisher
$pubName="MicrosoftWindowsServer"
#Get available offers
Get-AzureRMVMImageOffer -Location $loc -Publisher $pubName | Select Offer
#Pick a specific offer
$offerName="WindowsServer"
#View the different SKUs
Get-AzureRMVMImageSku -Location $loc -Publisher $pubName -Offer $offerName | Select Skus
#Pick a SKU
$skuName="2016-Datacenter"
#View the versions of a SKU
Get-AzureRMVMImage -Location $loc -PublisherName $pubName -Offer $offerName  -Skus $skuName

 .Parameter UsePlan
Some Images in the Image library require “Plan” to be a part of the deployment.

 .Parameter ForcePostTasks
Enforcing Post Deployment tasks even if deployment failed. Can be useful in case of the deployment failure due to extension.

 .Parameter SkipExtensions
Should be used to skip extensions deployment. This can be useful if Deploying unsupported version of the OS, like Windows Server 2003 or Windows Server 2008

 .Parameter DatadiskSizeGB
Size of the Data Disk in GB. Default is 128GB. Maximum value is 1023 GB.

 .Parameter DatadisksCount
 Count of the disks to be attached.

 .Parameter StorageAccountID
 ID (two numbers) of the storage account that will be hosting data disks.

 .Parameter AttachDataVHDs
 Use this switch to attache the exiting DATA VHDs for the VM you are creating from the VHD. Please not that only available when creating VM from the Existing VHD.
 For additional help please see "Get-Help Add-mrvExistingDataDisks -Detailed"

 .Parameter EnableBackup
 Use this switch to add VM to the Recovery Service Vault Backup protection.

 .Parameter DoBackup
 Please see "Get-Help Start-mrvVMBackup -Detailed"

 .Parameter EnableBackupPolicyName
 Please see "Get-Help Start-mrvVMBackup -Detailed"

 .Parameter GetLatestBackupDetails
 Please see "Get-Help Start-mrvVMBackup -Detailed"

 .Parameter BackupRetainDays
 Please see "Get-Help Start-mrvVMBackup -Detailed"

 .Parameter EnableBackupPolicyID
 ID for the Recovery Service Vault Backup policy. Usually 2 digits number, like 01 or 02 or 12

 .Parameter WaitSecondsIfBackupWasEnabled
 Please see "Get-Help Start-mrvVMBackup -Detailed"

.Parameter EnableAcceleratedNetworking
Enables Accelerated Networking which is currently off by default (as of 15/7/2017).
uses Test-mrvVMAcceleratedNetworking to validate if region / VMSize supported

.Parameter AlwaysOn
Sets the tag 'AlwaysOn' to True so that the VM stays up after deployment

.Parameter imageReferenceID
Reference to Azure Object ID that is representing image. Example: "/subscriptions/5d3731a5-a803-4fa6-ba02-52904c958ad3/resourceGroups/mrvP-RG-TMPL-01/providers/Microsoft.Compute/images/mrvP-WV-ICAMCLN-Image"

See below :
https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-create-vm-accelerated-networking#configure-wind
https://azure.microsoft.com/en-us/updates/accelerated-networking-in-preview/ for supported regions

.Example
Create VM from the Azure Market Image
New-MRVAzureVM -VMname "MRV-SH-TEST-015" -ResourceGroupName "MRV-RG-TEST-015" -VMIPaddress "172.20.65.15" -SubscriptionName "MSDN_01" -VMSize "Standard_D1_v2" -ChangeControl CHG0000000 -Description "TEST"

.Example
-Override can be used if we already have Interface provisioned or VM has non-standard name
New-MRVAzureVM -VMname MRV-SV-XXX-004 -ResourceGroupName "MRV-RG-XXX-001" -VMIPaddress "172.20.71.XX" -SubscriptionName "MSDN_01" -VMSize "Standard_D2_v2" -Override -ChangeControl CHG0000000 -Description "TEST" -Override

.Example
-UseExistingDisk Can be used to provisionn the VM from the existing VHD
New-MRVAzureVM -VMname "MRV-SH-TEST-015" -ResourceGroupName "MRV-RG-TEST-010" -VMIPaddress "172.20.65.15" -UseExistingDisk  -VMtype "MSDN_01" -VMSize "Standard_D1_v2" -ChangeControl CHG0000000 -Description "TEST"

.Example
Non standard VMs
New-MRVAzureVM -VMname "MRV-SH-HI-001" -ResourceGroupName "MRV-RG-HI-001" -VMIPaddress "172.20.158.22" -SubscriptionName "MSDN_01" -VMSize "Standard_D1_v2"  -imageOffer "hanu-insight" -imagePublisher "hanu" -ImageSku "standard-byol" -useplan
New-MRVAzureVM -VMname "MRV-SH-XXX-001" -ResourceGroupName "MRV-RG-XXX-001" -VMIPaddress "172.20.154.XX" -SubscriptionName "MSDN_01" -VMSize "Standard_D2_v2"   -ChangeControl CHG0000XXX -Description "XXXXXXXXX" -ImageSKU 8 -imagePublisher credativ -imageOffer Debian
New-MRVAzureVM -VMname "MRV-SH-XXX-002" -ResourceGroupName "MRV-RG-XXX-001" -VMIPaddress "172.20.154.XX" -SubscriptionName MSDN_01 -VMSize Standard_D2_v2  -ChangeControl CHG0000XXX -Description "Microsites Windows Server" -ImageSKU '2016-Datacenter' -Imageoffer 'WindowsServer' -ImagePublisher 'MicrosoftWindowsServer'

.Example
Attach Existing Data Disks (VHDs) for the VM when creating from existing VHD.
New-MRVAzureVM -VMname "MRV-SH-TEST-011" -ResourceGroupName "MRV-RG-TEST-010" -VMIPaddress "172.20.65.11" -SubscriptionName "MSDN_01" -VMSize "Standard_D2_v2" -ChangeControl CHG0000000 -Description "TEST" -UseExistingDisk -AttachDataVHDs

.Example
Add VM to backup (Recovery Service Vault)
New-MRVAzureVM -VMname "MRV-SH-TEST-011" -ResourceGroupName "MRV-RG-TEST-010" -VMIPaddress "172.20.65.11" -SubscriptionName "MSDN_01" -VMSize "Standard_D2_v2" -ChangeControl CHG0000000 -Description "TEST" -UseExistingDisk -AttachDataVHDs -EnableBackup
New-MRVAzureVM -VMname "MRV-SH-TEST-012" -ResourceGroupName "MRV-RG-TEST-010" -VMIPaddress "172.20.65.12" -SubscriptionName "MSDN_01" -VMSize "Standard_D1_v2" -ChangeControl CHG0000000 -Description "TEST"

#>
Function New-MRVAzureVM
{
    [CmdletBinding()]
    Param
    (
        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $true)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $true)]
        [String]
        $VMname = "MRV-SH-TEST-015",

        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $true)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $true)]
        [String]
        $ResourceGroupName,

        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $true)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $true)]
        #[ValidateSet("MSDN_01", "MSDN_02", "mr.vladis_Cloud_Essentials" )] # Comment this line out to bypass validation or replace with your own subnscription list.
        [String]
        $SubscriptionName = $(throw "Please Provide the name for Subscription!"),

        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [ValidateSet('Standard_A0',
            'Standard_A1',
            'Standard_A2',
            'Standard_A3',
            'Standard_A5',
            'Standard_A4',
            'Standard_A6',
            'Standard_A7',
            'Basic_A0',
            'Basic_A1',
            'Basic_A2',
            'Basic_A3',
            'Basic_A4',
            'Standard_D1',
            'Standard_D2',
            'Standard_D3',
            'Standard_D4',
            'Standard_D11',
            'Standard_D12',
            'Standard_D13',
            'Standard_D14',
            'Standard_A1_v2',
            'Standard_A2m_v2',
            'Standard_A2_v2',
            'Standard_A4m_v2',
            'Standard_A4_v2',
            'Standard_A8m_v2',
            'Standard_A8_v2',
            'Standard_DS1',
            'Standard_DS2',
            'Standard_DS3',
            'Standard_DS4',
            'Standard_DS11',
            'Standard_DS12',
            'Standard_DS13',
            'Standard_DS14',
            'Standard_D1_v2',
            'Standard_D2_v2',
            'Standard_D3_v2',
            'Standard_D4_v2',
            'Standard_D5_v2',
            'Standard_D11_v2',
            'Standard_D12_v2',
            'Standard_D13_v2',
            'Standard_D14_v2',
            'Standard_D15_v2',
            'Standard_D2_v2_Promo',
            'Standard_D3_v2_Promo',
            'Standard_D4_v2_Promo',
            'Standard_D5_v2_Promo',
            'Standard_D11_v2_Promo',
            'Standard_D12_v2_Promo',
            'Standard_D13_v2_Promo',
            'Standard_D14_v2_Promo',
            'Standard_F1',
            'Standard_F2',
            'Standard_F4',
            'Standard_F8',
            'Standard_F16',
            'Standard_DS1_v2',
            'Standard_DS2_v2',
            'Standard_DS3_v2',
            'Standard_DS4_v2',
            'Standard_DS5_v2',
            'Standard_DS11_v2',
            'Standard_DS12_v2',
            'Standard_DS13-2_v2',
            'Standard_DS13-4_v2',
            'Standard_DS13_v2',
            'Standard_DS14-4_v2',
            'Standard_DS14-8_v2',
            'Standard_DS14_v2',
            'Standard_DS15_v2',
            'Standard_DS2_v2_Promo',
            'Standard_DS3_v2_Promo',
            'Standard_DS4_v2_Promo',
            'Standard_DS5_v2_Promo',
            'Standard_DS11_v2_Promo',
            'Standard_DS12_v2_Promo',
            'Standard_DS13_v2_Promo',
            'Standard_DS14_v2_Promo',
            'Standard_F1s',
            'Standard_F2s',
            'Standard_F4s',
            'Standard_F8s',
            'Standard_F16s',
            'Standard_NV6',
            'Standard_NV12',
            'Standard_NV24',
            'Standard_B1ms',
            'Standard_B1s',
            'Standard_B2ms',
            'Standard_B2s',
            'Standard_B4ms',
            'Standard_B8ms',
            'Standard_D2_v3',
            'Standard_D4_v3',
            'Standard_D8_v3',
            'Standard_D16_v3',
            'Standard_D32_v3',
            'Standard_D64_v3',
            'Standard_D2s_v3',
            'Standard_D4s_v3',
            'Standard_D8s_v3',
            'Standard_D16s_v3',
            'Standard_D32s_v3',
            'Standard_D64s_v3',
            'Standard_E2_v3',
            'Standard_E4_v3',
            'Standard_E8_v3',
            'Standard_E16_v3',
            'Standard_E32_v3',
            'Standard_E64_v3',
            'Standard_E2s_v3',
            'Standard_E4s_v3',
            'Standard_E8s_v3',
            'Standard_E16s_v3',
            'Standard_E32s_v3',
            'Standard_E64s_v3',
            'Standard_H8',
            'Standard_H16',
            'Standard_H8m',
            'Standard_H16m',
            'Standard_H16r',
            'Standard_H16mr',
            'Standard_G1',
            'Standard_G2',
            'Standard_G3',
            'Standard_G4',
            'Standard_G5',
            'Standard_GS1',
            'Standard_GS2',
            'Standard_GS3',
            'Standard_GS4',
            'Standard_GS4-4',
            'Standard_GS4-8',
            'Standard_GS5',
            'Standard_GS5-8',
            'Standard_GS5-16',
            'Standard_L4s',
            'Standard_L8s',
            'Standard_L16s',
            'Standard_L32s',
            'Standard_NC6',
            'Standard_NC12',
            'Standard_NC24',
            'Standard_NC24r',
            'Standard_A8',
            'Standard_A9',
            'Standard_A10',
            'Standard_A11'
        )]
        [String]
        $VMSize = 'Standard_D1_v2',

        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [ValidateSet( 'Standard_LRS',
            'Standard_GRS',
            'Premium_LRS',
            'Standard_RAGRS')]
        [String]
        $StorageAccountType = 'Standard_LRS',

        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [ValidatePattern("(\d{2})")]
        [String]
        $StorageAccountID = '01',

        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $true)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $true)]
        [String[]]
        #[ValidatePattern("((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))")]
        $VMIPaddresses = "172.20.65.15",

        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [Int]
        $IfaceCount = 1,

        # Availability Set (AS) ID
        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [ValidatePattern("(\d{2})")]
        [String]
        $AvailabilitySetID = '00',

        # AS FaultDomainCount
        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [Int]
        $FaultDomainCount = 3,

        # VM UpdateDomainCount
        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [Int]
        $UpdateDomainCount = 3,

        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [String]
        $imagePublisher = 'MicrosoftWindowsServer',

        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [String]
        $imageOffer = 'WindowsServer',

        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [String]
        $ImageSKU = '2016-Datacenter',

        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [switch]
        $UsePlan,

        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $true)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $true)]
        [String]
        [ValidatePattern("(CHG)(\d{7})")]
        $ChangeControl = $(throw "Please specify an Change Number for this Deployment in the format CHGXXXXXXX, like CHG0000420 "),

        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $true)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $true)]
        [String]
        $Description = $(throw "Please Provide a description for the Vm you are creating"),

        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [Hashtable]
        $TagsTable = @{
            "AlwaysOFF" = '$false';
            "AlwaysON"  = '$false';
        },

        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [switch]
        $AlwaysOn,

        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [String]
        $VMAdminUsername = 'YourUserName',

        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [String]
        $VMAdminPassword = 'YourPassword',

        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [Management.Automation.PSCredential]
        $DomainAdminCreds = $null,

        #Used to provision Standalone VM. AD joing and group creation will be skipped.
        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [switch]
        $SkipExtensions,

        # Used to everride any existance checks
        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [switch]
        $Override,

        # Used to simulate without deploying anything
        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [switch]
        $Simulate,

        # Used to Force Post tasks
        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [switch]
        $ForcePostTasks,

        #Used to provision Standalone VM. AD joing and group creation will be skipped.
        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [switch]
        $StandaloneVM,

        # Virtual Machine to use as roles/features list
        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [String]
        $SourceVM = $null,

        # XML to use as roles/features list
        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [String]
        $SourceXML = $null,

        #Registry file for Regional Settings
        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [String]
        $EnGbDefaultFile = 'en-gb-default.reg',

        #Registry file for Regional Settings
        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [String]
        $EnGbWelcomeFile = 'en-gb-welcome.reg',

        #Storgage account name, where the JSON Templates stored during provisioning
        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [String]
        $JsonStorageAccountName = 'notdefined',

        <# #Storgage account key, where the JSON Templates stored during provisioning
        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [String]
        $JsonStorageAccountKey = 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
 #>
        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [String]
        $WorkSpaceId = 'notdefined',

        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [String]
        $WorkSpaceKey = 'notdefined',

        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [String]
        $WorkSpaceName = 'notdefined',

        #Time in minutes for the token to expire!
        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [Int]
        $TokenExpiry = 45,

        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [String]
        $WINRMPort = '5986',

        #"UserName for joining Domain"
        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [String]
        $DomainUser = 'NotConfigured',

        #"Password for joining Domain"
        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [String]
        $DomainPass = 'NotConfigured',

        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [String]
        $DomainDNS = 'NotConfigured',

        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [String]
        $AzureServersBaseOU = 'OU=Servers,OU=xxxxxxx',

        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [String]
        $groupOU = 'OU=Delegation Groups,OU=Groups,OU=Administration,DC=mrv,DC=local',

        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [String[]]
        $NotificationRecipients = 'Azureprovision@mrvlab.co.uk',

        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [string] $SmtpServer = 'smtprelay.mrvlab.co.uk',

        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [int] $Port = 25,

        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [String]
        [ValidateSet("Windows", "Linux")]
        $osType = 'Windows',

        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [switch]
        $ManagedDisks,

        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [String]
        $JsonTempFolder = 'C:\Temp\',

        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [switch]
        $DoNotCleanup,

        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [switch]
        $EnableAcceleratedNetworking,

        ######Image Source
        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [String]
        $imageReferenceID = '',

        ######EXISTING Disks
        # Used to create  a disk
        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $true)]
        [switch]
        $UseExistingDisk,

        # Used to create  a disk
        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [switch]
        $AttachDataVHDs,
        ######New Disks
        # VM DatadiskSizeGB
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [Int]
        $DatadiskSizeGB = 128,

        # VM DatadisksCount
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [Int]
        $DataDisksCount = 1,

        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [string] $DiagStorageAccountName = 'notdefined',

        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [string] $Prefix_Main = 'MRV',

        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [string] $Prefix_RSV = 'RSV',

        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [string] $Prefix_RSV_BP = 'BP',

        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [string] $Prefix_VM = 'SH',

        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [string] $Prefix_RG = 'RG',

        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [string] $Prefix_AS = 'AS',

        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [string] $Prefix_IFACE = 'IFACE',

        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [string] $Prefix_IPCFG = 'IPCFG',

        [Parameter(ParameterSetName = 'NewVM_ExistingVHD', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NewVM_NewDataDisks', Mandatory = $false)]
        [ValidateSet("SilentlyContinue", "Stop", "Continue", "Inquire", "Ignore", "Suspend")]
        [string] $FunctionErrorActionPreference = "Continue"

    )
    <# Below we set initial Variables
====> <=====
#>
    $MaxDiskSize = 4095
    Write-Verbose "VM Provisioning  v.1.0.0.0"
    ##################Loading Modules #################
    [datetime]$time_start = Get-Date
    $timestamp = Get-Date -Format 'yyyy-MM-dd-HH-mm'
    Write-Verbose "Deployment started at [$time_start]"
    Write-Verbose 'Loading Azure Modules'
    Write-Verbose 'Please Wait...'
    $ISVervbose = $false
    if ($VerbosePreference -like 'Continue')
    {
        Write-Output "Runing in Verbose. Switching Off to load modules... "
        $VerbosePreference = 'SilentlyContinue'
        $ISVervbose = $true
    }

    If (!(Import-MRVModule 'Azure').Result)
    {
        Write-Verbose "Can't load Azure module. Let's check if AzureRM can be loaded"
        If (!(Import-MRVModule 'AzureRM').Result)
        {
            Write-Verbose "Can't load AzureRM module. Let's check if AzureRM.NetCore can be loaded"
            If (!(Import-MRVModule 'AzureRM.NetCore').Result)
            {
                Write-Error "Can't load Azure modules. Please make sure that you have Installed all the modules"
                return $false
            }
        }
    }
    if ($ISVervbose)
    {
        Write-Output "We were runing in Verbose. Switching back on "
        $VerbosePreference = 'Continue'
    }
    Write-Verbose "Azure Modules have been loaded sucessfully."
    ##################Loading Modules #################
    Write-Verbose "Determine OS we are running script from..."
    If ($($ENV:OS) -eq $null)
    {
        Write-Verbose "OS has been identified as NONE-Windows"
        Write-Verbose "   #### Warning  ####      #### Warning  ####      #### Warning  ####   "
        Write-Verbose "Some functionality and checks, like Active Directory will be unavailable"
        Write-Verbose "   #### Warning  ####      #### Warning  ####      #### Warning  ####   "
        $ScriptRuntimeWin = $false
        $JsonTempFolder = '/tmp/'
        $PathDelimiter = '/'
        $azCMD = Get-Command az -ErrorAction SilentlyContinue
        If ($azCMD -eq $null)
        {
            Write-Error "We need at least Azure CLI 2.0 to be installed to continue. Please check https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest "
        }
    }
    else
    {
        Write-Verbose "OS has been identified as Windows"
        $ScriptRuntimeWin = $true
        $PathDelimiter = '\'
    }
    <#   Temporary disabled as currently no need in this credentials.
  if ($StandaloneVM)
    {
        Write-Verbose "Skipping Credentials  as VM is Standalone"
    }
    else
    {
        if ($DomainAdminCreds -eq $null)
        {
            try
            {
                if ($ScriptRuntimeWin)
                {
                    $LocalUserName = (whoami).ToUpper()
                    $DomainAdminCreds = Get-Credential -UserName $LocalUserName -ErrorAction SilentlyContinue -Message 'Enter Your Domain Administrative Credentials'
                    if (!(Test-MRVCredentials -DomainCreds $DomainAdminCreds))
                    {
                        Write-Error "Can't validate credentials!"
                        return $false
                    }
                }
                else
                {
                    $DomainAdminCreds = Get-Credential -ErrorAction SilentlyContinue -Message 'Enter Your Domain Administrative Credentials'
                    Write-Verbose "Skipping Credentials validation as script is executed on none-Windows OS, so we can' validate them."
                }
            }
            catch
            {
                Write-Error "Can't continue without Credentials"
                return $false
            }
        }
    } #>

    if (! (Test-Path $JsonTempFolder))
    {
        Write-Verbose "Folder to store temporary Deployment templates [$JsonTempFolder] does not exist! Let's try to create"
        if (New-Item $JsonTempFolder -ItemType Directory)
        {
            Write-Verbose "Folder to store temporary Deployment templates [$JsonTempFolder] has been created sucessfully"
        }
        else
        {
            Write-Error "Can't create Folder to store temporary Deployment templates [$JsonTempFolder]. Exiting....."
            return $false
        }
    }

    if ($SourceXML -ne '')
    {
        if (-not (Test-Path $SourceXML))
        {
            Write-Error "Can't find file name specified as SourceXML! PLease check if [$SourceXML] exist!"
            return $false
        }
    }
    Write-Verbose  "Provisional operation has been started with timestamp $timestamp"
    $Subscription = Select-MRVSubscription -SubscriptionName $SubscriptionName
    If (!$Subscription.Result)
    {
        Write-Error  'Make sure that you have access and logged in to Azure'
        return $false
    }
    else
    {
        Write-Verbose  'Subscription has been selected successfully.'
    }

    ##### Patterns
    <#     $RSVPrefix = $Prefix_Main + '-' + $Prefix_RSV + '-'
    $RSV_BPPrefix = $Prefix_Main + '-' + $Prefix_RSV_BP + '-' #>
    $VMPrefix = $Prefix_Main + '-' + $Prefix_VM + '-'
    $RGPrefix = $Prefix_Main + '-' + $Prefix_RG + '-'
    $ASPrefix = $Prefix_Main + '-' + $Prefix_AS + '-'
    $IFACEPrefix = $Prefix_Main + '-' + $Prefix_IFACE + '-'
    $IPCFGPrefix = $Prefix_Main + '-' + $Prefix_IPCFG + '-'

    #$AzureServersOU = 'OU=' + $ResourceGroupName + ',' + $AzureServersBaseOU #need to work out how to connect to Domain Controller to create OU
    $AzureServersOU = $AzureServersBaseOU

    $JsonSourceTemlates = $PathDelimiter + 'Resources' + $PathDelimiter + 'Templates' + $PathDelimiter
    $RegsPath = $PathDelimiter + 'Resources' + $PathDelimiter + 'Registry' + $PathDelimiter
    $CustomScriptPath = $PathDelimiter + 'Resources' + $PathDelimiter + 'CustomScript' + $PathDelimiter
    If ($osType -ilike "Windows")
    {
        $CustomScript = 'AfterDeploymentTasks.ps1'
    }
    elseif ($osType -ilike "Linux")
    {
        $CustomScript = 'AfterDeploymentTasks.sh'
    }
    $JSONBaseTemplateFile = 'Azure_VM.json'
    $JSONParametersFile = 'Azure_VM_Parameters.json'
    $JSONBGinfoTemplateFile = 'Azure_VM_Extention_BGINFO.json'
    $JSONAzureDiagnosticsTemplateFile = 'Azure_VM_Extention_AzureDiagnostics.json'
    $JSONOMSTemplateFile = 'Azure_VM_Extention_OMS.json'
    $JSONJoinDomainTemplateFile = 'Azure_VM_Extention_JoinDomain.json'
    $VMname = $VMname.ToUpper()
    $ResourceGroupName = $ResourceGroupName.ToUpper()

    $VMnametmp = $VMname.Substring(0, $VMname.lastIndexOf('-'))
    $ResourceGroupNametmp = $ResourceGroupName.Substring(0, $ResourceGroupName.lastIndexOf('-'))
    $SourceVMFQDN = $SourceVM + '.' + $DomainDNS

    Write-Verbose 'Running Pre-Checks'

    If (($WorkSpaceId -eq 'notdefined') -and ($WorkSpaceName -eq 'notdefined') -and (!$SkipExtensions))
    {
        Write-Error "OMS Can't be configured with current Parameters."
        Write-Error "Please use WorkSpaceId with WorkSpaceKey or WorkSpaceName only"
        return $false
    }
    If ($WorkSpaceId -ne 'notdefined')
    {
        If ($WorkSpaceName -ne 'notdefined')
        {
            Write-Error "You can't use both WorkSpaceName and WorkSpaceId parameters."
            Write-Error "Please use WorkSpaceId with WorkSpaceKey or WorkSpaceName only"
            return $false
        }
        If ($WorkSpaceKey -eq 'notdefined')
        {
            Write-Error "You can't use WorkSpaceId without WorkSpaceKey parameters."
            Write-Error "Please use WorkSpaceId with WorkSpaceKey or WorkSpaceName only"
            return $false
        }
        $OMSbyId = $true
    }
    If ($WorkSpaceName -ne 'notdefined')
    {
        If ($WorkSpaceKey -ne 'notdefined')
        {
            Write-Error "You can't use both WorkSpaceKey and WorkSpaceId parameters. WorkSpaceKey will be ignored."
            Write-Error "Please use WorkSpaceId with WorkSpaceKey or WorkSpaceName only"
        }
        Write-Verbose "We will try to add OMS Workspace by name."
        $OMSbyId = $false
    }
    if ($SourceVM -ne '')
    {
        Write-Verbose 'Performing SourceVM name check...'
        If ($SourceVM.IndexOf('.') -ge 0)
        {
            Write-Error "$SourceVM Virtual machine name (Short name, eg MRV-SH-MGMT-001 ) should be provided."
            return $false
        }
        else
        {
            Write-Verbose  "SourceVM $SourceVM Looks good!"
        }
    }
    if ($Override)
    {
        Write-Verbose 'Override has been used! Skiping VM Name Format Check'
    }
    else
    {
        If ($VMnametmp.Substring(0, $VMnametmp.lastIndexOf('-') + 1) -notlike $VMPrefix)
        {
            Write-Error "$VMname Does not meet the naming rules. Should start with: $VMPrefix"
            return $false
        }
    }
    If ($VMname.Length -gt 15)
    {
        Write-Error "$VMname Can't be longer then 15 characters"
        return $false
    }
    If ($ResourceGroupNametmp.Substring(0, $ResourceGroupNametmp.lastIndexOf('-') + 1) -notlike $RGPrefix)
    {
        Write-Error  "$ResourceGroupName Does not meet the naming rules. Should start with: $RGPrefix"
        return $false
    }
    if ($SourceVM -ne '')
    {
        Write-Verbose  "Source VM has been specified. Checking if $SourceVM exist...."
        if (!(Test-MRVVMExist $SourceVM).Result)
        {
            Write-Error  "Source VM $SourceVM Does Not Exist!"
            return $false
        }
        else
        {
            Write-Verbose  "Source VM $SourceVM Exist! Continue..."
            Write-Verbose  "Testing connectivity... trying to connect to WinRM on $SourceVMFQDN ....."

            if ((Test-MRVTCPPort -EndPoint $SourceVMFQDN -Port $WINRMPort).Result )
            {
                Write-Verbose  'Sucessfully Connected! Continue...'
            }
            else
            {
                Write-Error  "Source VM $SourceVM is not accessible to make remote connection. Check VM is up and port $WINRMPort is opened!"
                return $false
            }
        }
    }

    #} ##################Pre-run Checks
    Write-Verbose "Validating VMIPaddresses"
    if ($VMIPaddresses.Count -ne $IfaceCount)
    {
        Write-Error "You have specified [$IfaceCount] of Interfaces, but provided only [$($VMIPaddresses.Count)] IP addresses"
        return $false
    }
    if (($VMIPaddresses | Sort-Object -Unique).Count -ne $VMIPaddresses.Count)
    {
        Write-Error "Looks like you have duplicates in IP addresses"
        return $false
    }
    $VMIPaddress = $VMIPaddresses[0]
    Write-Verbose "[$VMIPaddress] will be used as main IP address."
    if ($Override)
    {
        Write-Verbose  'Override has been used! Skiping VM and IP check!!!'
    }
    else
    {
        Write-Verbose  'Performing VM verification and populating the dependent variables'
        if ((Test-MRVVMExist -name $VMname).Result)
        {
            Write-Error  "VM $VMname is already used!"
            return $false
        }
        else
        {
            Write-Verbose  "VM Name $VMname free to use."
        }
        Write-Verbose  'Performing IP verification and populating the dependent variables'
        ForEach ($IP in $VMIPaddresses)
        {
            Write-Verbose "Checking if IP [$IP] is free for use"
            if (Test-MRVIPUsed $IP)
            {
                $IPCFGUsed = Get-AzureRmNetworkInterface |
                    ForEach-Object -Process {
                    $_.IpConfigurations
                } |
                    Where-Object -FilterScript {
                    $_.PrivateIpAddress -like ($IP)
                }
                Write-Error  "IP address is already used by IP Config $($IPCFGUsed.Name)!"
                return $false
            }
            else
            {
                Write-Verbose  "IP [$IP] address free to use"
            }
        }
    }
    $counter = 1
    $SubNetNames = @()
    Write-Verbose  "Checking if Subnets do exist for the provided value for VMIPaddresses"
    ForEach ($IP in $VMIPaddresses)
    {
        Write-Verbose  "Trying to find the VNET and SubNET for the provided IP [$IP]"
        $SubNetPattern = $IP.Substring(0, $IP.LastIndexOf('.') + 1)
        $VirtualNetworkobj = Get-AzureRmVirtualNetwork  | ForEach-Object -Process {
            $_   | Where-Object -FilterScript {
                $_.Subnets.AddressPrefix -like ($SubNetPattern + '*')
            }
        }
        $Subnetobj = Get-AzureRmVirtualNetwork  |
            ForEach-Object -Process {
            $_.Subnets
        }  |
            Where-Object -FilterScript {
            $_.AddressPrefix -like ($SubNetPattern + '*')
        }
        if (($VirtualNetworkobj -eq $null) -or ($Subnetobj -eq $null))
        {
            Write-Error  "Can't find the VNET and SubNET for the IP provided! MAke sure that the IP adress is correct and SubNET has been created!"
            return $false
        }
        If (($VirtualNetworkobj.count -gt 1) -or ($Subnetobj.Count -gt 1))
        {
            Write-Verbose  "VNetName: [$VNetName]"
            Write-Verbose  "SubNetNames: [$SubNetNames]"
            Write-Error  "Multiple VNETs and / or SubNETs for the IP found! Can't understand where we going... Sorry... "
            Write-Error  "Multiple VNETs and / or SubNETs with the same CIDRs within the same subscription not supported."
            return $false
        }
        If ($counter -eq 1)
        {
            $VNetName = $VirtualNetworkobj.name
            $VNetResourceGroup = $VirtualNetworkobj.ResourceGroupName
            $location = $VirtualNetworkobj.Location
        }
        else
        {
            If (($VNetName -ne $VirtualNetworkobj.name) -or ($VNetResourceGroup -ne $VirtualNetworkobj.ResourceGroupName))
            {
                Write-Error "It looks like IP [$IP] belongs to VNET [$($VirtualNetworkobj.name)] while IP [$($VMIPaddresses[0])] belongs to VNET [$VNetName]!"
                Write-Error "ALL IP addresses must be from the same VNET"
                return $false
            }
        }
        $SubNetNames += $Subnetobj.Name
        $counter += 1
    }
    $LocationCode = (Get-MRVLocationCode $location).LocationCode
    $DiagStorageAccount = Get-MRVAzureModuleStorageAccount -StorageAccountName $DiagStorageAccountName -AccountType DIAG -Location $location -SubscriptionName $SubscriptionName -Prefix_Main $Prefix_Main -Prefix_RG $Prefix_RG -Verbose
    If (!$DiagStorageAccount.Result)
    {
        Write-Error "Failed to retrieve Diagnostic Storage account."
        $DiagStorageAccount.Error
    }
    $DiagStorageResourceGroup = $DiagStorageAccount.StorageResourceGroup
    $DiagStorageAccountName = $DiagStorageAccount.StorageAccountName
    Write-Verbose  'Virtual Macine will be deployed with the following parameters:'
    Write-Verbose  "VNetResourceGroup: [$VNetResourceGroup]"
    Write-Verbose  "VNetName: [$VNetName]"
    Write-Verbose  "Location: [$location]"
    Write-Verbose  "SubNetNames: [$SubNetNames]"
    Write-Verbose  "FaultDomainCount [$FaultDomainCount] UpdateDomainCount [$UpdateDomainCount]"
    Write-Verbose  "StorageDiagAccountName: $DiagStorageAccountName"
    If ($imagePublisher -ne 'MicrosoftWindowsServer')
    {
        Write-Verbose  'Custom image has been specified. Checking if it exist....'
        Write-Verbose  "Looking for the Image Pubslisher [$imagePublisher]."
        $publisher = Get-AzureRmVMImagePublisher -Location $location | Where-Object -FilterScript {
            $_.PublisherName -match $imagePublisher }
        If ($publisher -eq $null)
        {
            Write-Error  "Sorry, can't find the Image Pubslisher [$imagePublisher]"
            return $false
        }
        else
        {
            Write-Verbose  "Image Publisher [$imagePublisher] has been found! Looking for the imageOffer [$imageOffer]"
            $offer = Get-AzureRmVMImageOffer -Location $location -PublisherName $imagePublisher | Where-Object -FilterScript {
                $_.Offer -match $imageOffer }
            If ($offer -eq $null)
            {
                Write-Error  "Sorry, can't find the Image Offer [$imageOffer]"
                return $false
            }
            else
            {
                Write-Verbose  "Image Offer [$imageOffer] has been found! Looking for the ImageSKU [$ImageSKU]"
                $SKU = Get-AzureRmVMImageSku -Location $location -PublisherName $imagePublisher -offer $imageOffer | Where-Object -FilterScript {
                    $_.skus -match $ImageSKU }

                If ($offer -eq $null)
                {
                    Write-Error  "Sorry, can't find the Image SKU [$ImageSKU]"
                    return $false
                }
                else
                {
                    Write-Verbose  "Image SKU [$ImageSKU] has been found! "
                }
            }
        }
        Write-Verbose  "Both [$imagePublisher] and  [$imageOffer] and ImageSKU [$ImageSKU has been found. We can move forward!"
    }

    If ($osType -ilike "Linux")
    {
        Write-Verbose "OSType has been selected as [$osType]. Setting parameters to skip Windows Extentions"
        $SkipExtensions = $true
    }
    Write-Verbose  'Checking if VMSize need to have Premium Storage...'
    if (($VMSize.ToLower().Contains('ds')) -or ($VMSize.ToLower().Contains('gs') -or ($Vmsize.Substring($Vmsize.Length - 2) -match "[1-9]s") ))
    {
        if ($StorageAccountType.ToLower().Contains('standard'))
        {
            Write-Verbose  "You have specified Sandard Storage, while VMSize is set to $VMSize "
            Write-Verbose  "$VMSize require premium storage, so the type of the storage will be changed to Premium_LRS"
            $StorageAccountType = 'Premium_LRS'
        }
    }
    else
    {
        if ( -not ($StorageAccountType.ToLower().Contains('standard')))
        {
            Write-Verbose  "You have specified Premium Storage, while VMSize is set to $VMSize "
            Write-Verbose  "$VMSize does not require premium storage, so the type of the storage will be changed to Standard_LRS"
            $StorageAccountType = 'Standard_LRS'
        }
    }
    If (($DatadiskSizeGB -lt 1) -or ($DatadiskSizeGB -gt $MaxDiskSize))
    {
        Write-Error "Datadisk can't be size [$DatadiskSizeGB]. It must be from 1 to $MaxDiskSize GB"
        return $false
    }
    Write-Verbose  'Populating the StorageAccountName to use...'
    $CutIndex = 2 + $ResourceGroupName.IndexOf('-') + ($ResourceGroupName.Substring($ResourceGroupName.IndexOf('-') + 1)).IndexOf('-')
    $StorageAccountName = $($Prefix_Main + ($StorageAccountType.Substring(0, 2)).ToLower() + ($StorageAccountType.Substring($StorageAccountType.IndexOf('_') + 1, $StorageAccountType.Length - $StorageAccountType.IndexOf('_') - 1)).ToLower() + $LocationCode.ToLower() + ($ResourceGroupName.Substring($CutIndex, $ResourceGroupName.Length - $CutIndex) -replace '-', '').ToLower() + $StorageAccountID).ToLower()
    If ($StorageAccountName.Length -gt 23)
    {
        Write-Verbose "Storage account name [$StorageAccountName] is to long. Will be truncated to [$($StorageAccountName.Substring(0,23))]"
        $StorageAccountName = $StorageAccountName.Substring(0, 23)
    }

    Write-Verbose  "StorageAccountName: $StorageAccountName"
    Write-Verbose  "StorageDiagAccountName: $DiagStorageAccountName"
    Write-Verbose  'Populating the AvailabilitySetName to use...'
    if ($AvailabilitySetID -eq "00")
    {
        Write-Verbose "Availability Set ID left default [$AvailabilitySetID]. That mean that it will be ammended and NOT added to the name."
        [string]$AvailabilitySetID_Pref = ''
    }
    else
    {
        Write-Verbose "Availability Set ID specified as [$AvailabilitySetID]. That mean that it will be added to the name."
        [string]$AvailabilitySetID_Pref = '-' + $AvailabilitySetID
    }
    $availabilitySetName = $ASPrefix + $LocationCode + ($ResourceGroupName.Substring($ResourceGroupName.IndexOf('-'), $ResourceGroupName.Length - $ResourceGroupName.IndexOf('-'))).ToUpper() + $AvailabilitySetID_Pref
    Write-Verbose  "AvailabilitySetName: $availabilitySetName"
    Write-Verbose  'Populating the IfaceNames to use...'
    $IfaceNames_array = @()
    $ifacepattern = $VMname.Substring($VMname.IndexOf('-') + 1)
    $ifacepattern = $ifacepattern.Substring($ifacepattern.IndexOf('-') + 1)
    $counter = 1
    while ($counter -le $IfaceCount)
    {
        $IfaceNames_array += $IFACEPrefix + $LocationCode + '-' + $ifacepattern + '-0' + $counter
        $counter += 1
    }
    Write-Verbose  "IfaceNames: $IfaceNames_array"
    Write-Verbose  'Populating the IPConfigName to use...'
    $IPConfigNames_array = @()
    $counter = 1
    while ($counter -le $IfaceCount)
    {
        $IPConfigNames_array += $IPCFGPrefix + $LocationCode + '-' + $ifacepattern + '-0' + $counter
        $counter += 1
    }
    Write-Verbose  "IPConfigNames: $IPConfigNames_array"
    Write-Verbose  'Populating the VMDiskName to use...'
    $VMDiskName = $VMname.ToLower()
    Write-Verbose  "VMDiskName that will be used: $($VMDiskName + '-osdisk.vhd')"
    if ( -not (Get-AzureRmResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue))
    {
        Write-Verbose  "Resource Group ($ResourceGroupName) was not found! Trying to create it..."
        New-AzureRmResourceGroup -Location $location -Name $ResourceGroupName
        Start-MRVWait -AprxDur 5 -Wait_Activity "Waiting for Resource Group to propagate"
    }
    else
    {
        Write-Verbose  "Resource Group ($ResourceGroupName) has been found!"
    }
    $DeploymentName = $timestamp + '-' + $ResourceGroupName + '-Dep-' + $VMname

    $JSONStorageAccount = Get-MRVAzureModuleStorageAccount -StorageAccountName $JsonStorageAccountName -AccountType JSON -Location $location -SubscriptionName $SubscriptionName -Prefix_Main $Prefix_Main -Prefix_RG $Prefix_RG -Verbose
    $JsonStorageAccountKey = $JSONStorageAccount.StorageAccountKey
    $JsonStorageAccountName = $JSONStorageAccount.StorageAccountName
    $JSONUrlBase = 'https://' + $JsonStorageAccountName + '.blob.core.windows.net/'

    Write-Verbose  "Getting storage context for account [$JsonStorageAccountName] with provided key....."
    $containername = $DeploymentName.ToLower()
    if ($containername.Length -gt 63)
    {
        $containername = $containername.Substring(0, 63)
    }
    $DeploymentTempPath = (New-Item $(join-path $JsonTempFolder $containername) -type directory).FullName + $PathDelimiter
    if ($ScriptRuntimeWin)
    {
        $storageContext = New-AzureStorageContext -StorageAccountName $JsonStorageAccountName -StorageAccountKey "$JsonStorageAccountKey" -ErrorAction SilentlyContinue

        If ($storageContext -eq $null)
        {
            Write-Error "Can't create a secure context for storage account [$JsonStorageAccountName]"
            return $false
        }
        else
        {
            Write-Verbose "Secure context for storage account [$JsonStorageAccountName] has been created sucessfully."
        }
    }
    Write-Verbose  "Creating container $containername"

    if ($ScriptRuntimeWin)
    {
        $containerResult = New-AzureStorageContainer -Name $containername -Context $storageContext -Permission 'Off'
    }
    else
    {
        $containerResult = az storage container create --name $containername --account-name $JsonStorageAccountName  --account-key "$JsonStorageAccountKey" --output json | ConvertFrom-Json
    }
    if ($ScriptRuntimeWin)
    {
        Write-Verbose  'Creating a token for the Storage Access'
        $token = New-AzureStorageContainerSASToken -Context $storageContext -Name  $containername -Permission r -StartTime ((Get-Date).ToUniversalTime().AddMinutes(-1)) -ExpiryTime ((Get-Date).ToUniversalTime().AddMinutes($TokenExpiry))
    }
    else
    {
        $token = az storage container generate-sas --name $containername --account-name $JsonStorageAccountName  --account-key "$JsonStorageAccountKey" --permissions r --start (get-date -Format u (Get-Date).ToUniversalTime().AddMinutes(-1)).Replace(' ', 'T') --expiry (get-date -Format u (Get-Date).ToUniversalTime().AddMinutes($TokenExpiry)).Replace(' ', 'T') --output json | ConvertFrom-Json
        if ($token -ne '')
        {
            $token = '?' + $token
        }
    }
    Write-Verbose  'Populating URLS for the Base Template'
    $JsonTemplatesUrl = $JSONUrlBase + $containername + '/'
    Write-Verbose  "Main Temlate URL will be $JsonUrlMain Reading Main Template to be deployed"
    Write-Verbose  'Preparing main template...'
    $OutFileName = $JSONBaseTemplateFile.Substring(0, $JSONBaseTemplateFile.IndexOf('.')) + $containername + '.json'
    $JSONParametersOutFileName = $JSONParametersFile.Substring(0, $JSONParametersFile.IndexOf('.')) + $OutFileName
    $JsonUrlMain = $JSONUrlBase + $containername + '/' + $OutFileName + $token
    $JSONParametersUrl = $JSONUrlBase + $containername + '/' + $JSONParametersOutFileName + $token
    $CustomScriptUrl = $JSONUrlBase + $containername + '/' + $CustomScript + $token
    $InputTemplate = $null
    $InputTemplatePath = $PSScriptRoot.Substring(0, $PSScriptRoot.LastIndexOf($PathDelimiter)) + $JsonSourceTemlates + $JSONBaseTemplateFile
    Write-Verbose "JSON Main Url is [$JsonUrlMain]"
    Write-Verbose  "Loading Main Template from file [$InputTemplatePath]"
    try
    {
        $InputTemplate = [system.io.file]::ReadAllText($InputTemplatePath) -join "`n" | ConvertFrom-Json
    }
    catch
    {
        Write-Error  "Can't load the main template! Please check the path [$InputTemplatePath]"
        return $false
    }
    Write-Verbose  'Main Template has been loaded sucessfully!'
    $InputParameters = $null
    $InputParametersPath = $PSScriptRoot.Substring(0, $PSScriptRoot.LastIndexOf($PathDelimiter)) + $JsonSourceTemlates + $JSONParametersFile
    Write-Verbose "JSON Parameters Main Url is [$JSONParametersUrl]"
    Write-Verbose  "Loading Main Parameters Template from file [$InputParametersPath]"
    try
    {
        $InputParameters = [system.io.file]::ReadAllText($InputParametersPath) -join "`n" | ConvertFrom-Json
    }
    catch
    {
        Write-Error  "Can't load the main Parameters template! Please check the path [$InputParametersPath]"
        return $false
    }
    $InputPostTasksPath = $PSScriptRoot.Substring(0, $PSScriptRoot.LastIndexOf($PathDelimiter)) + $CustomScriptPath + $CustomScript
    $InputPostTasks = $null
    $InputPostTasks = '$DomainFQDN = ' + $DomainDNS + "`n"
    $InputPostTasks += '$EnGbDefaulturl = ''' + $JSONUrlBase + $containername + '/' + $EnGbDefaultFile + $token + "'`n"
    $InputPostTasks += '$EnGbWelcomeurl = ''' + $JSONUrlBase + $containername + '/' + $EnGbWelcomeFile + $token + "'`n"
    Write-Verbose "JSON Parameters After Deployment Script Url is [$CustomScriptUrl]"
    Write-Verbose  "Loading After Deployment Script file [$InputPostTasksPath]"
    try
    {
        $InputPostTasks += [system.io.file]::ReadAllText($InputPostTasksPath)
    }
    catch
    {
        Write-Error  "Can't load After Deployment Script [$CustomScript]. After Deployment tasks would fail."
    }
    If ($osType -eq "Windows")
    {
        Write-Verbose  'Copying Regional Settings REG files'
        $EnGbDefaultTemplatePath = $($PSScriptRoot.Substring(0, $PSScriptRoot.LastIndexOf($PathDelimiter)) + $RegsPath + $EnGbDefaultFile)
        Write-Verbose  "Copying Regional Settings REG from file [$EnGbDefaultTemplatePath]"
        try
        {
            Copy-Item -Path $EnGbDefaultTemplatePath  -Destination $DeploymentTempPath
        }
        catch
        {
            Write-Error  "Copying Regional Settings REG from file [$EnGbDefaultTemplatePath]  failed..."
            return $false
        }
        Write-Verbose  "Regional Settings REG from file [$EnGbDefaultTemplatePath] has been Copied sucessfully!"
        $EnGbWelcomeTemplatePath = $($PSScriptRoot.Substring(0, $PSScriptRoot.LastIndexOf($PathDelimiter)) + $RegsPath + $EnGbWelcomeFile)
        Write-Verbose  "Copying Regional Settings REG from file [$EnGbWelcomeTemplatePath]"
        try
        {
            Copy-Item -Path $EnGbWelcomeTemplatePath -Destination $DeploymentTempPath
        }
        catch
        {
            Write-Error  "Copying Regional Settings REG from file [$EnGbWelcomeTemplatePath]  failed..."
            return $false
        }
        Write-Verbose  "Regional Settings REG from file [$EnGbWelcomeFile] has been Copied sucessfully!"
    }
    Write-Verbose "Getting VM resource and updating accordingly"
    $VMResources = $InputTemplate.resources |
        ForEach-Object -Process {$_} | Where-Object -FilterScript {
        $_.name -match "\[parameters\(\'VMName\'\)\]"}
    if ($imageReferenceID -ne '')
    {
        Write-Verbose "imageReferenceID has been provided. Removing Published Image data"
        $VMResources.properties.storageProfile.imageReference.PsObject.Members.Remove('publisher')
        $VMResources.properties.storageProfile.imageReference.PsObject.Members.Remove('offer')
        $VMResources.properties.storageProfile.imageReference.PsObject.Members.Remove('sku')
        $VMResources.properties.storageProfile.imageReference.PsObject.Members.Remove('version')
        Write-Verbose "Adding imageReferenceID"
        $VMResources.properties.storageProfile.imageReference | Add-Member -MemberType NoteProperty -Name id -Value $imageReferenceID
        Write-Verbose "imageReferenceID require Managed Disks. Setting this to true"
        $ManagedDisks = $true
    }
    if ($ManagedDisks)
    {
        Write-Verbose "Changing Disk Type to [Managed]"
        $ASresource = $InputTemplate.resources |
            ForEach-Object -Process {$_} | Where-Object -FilterScript {
            $_.name -match "\[parameters\(\'availabilitySetName\'\)\]"}
        $ASresource.sku.name = 'Aligned'
        Write-Verbose  'Removing VHD to storage account reference for OS disk section'
        $VMResources.properties.storageProfile.osDisk.PsObject.Members.Remove('vhd')
        Write-Verbose  'Adding Managed disk reference for OS disk section'
        $managedDisk = [pscustomobject][ordered]@{
            storageAccountType = "[parameters('storageAccountType')]"
        }
        $VMResources.properties.storageProfile.osDisk | Add-Member -MemberType NoteProperty -Name managedDisk -Value $managedDisk
        Write-Verbose  'Removing VHD to storage account reference for Data disk section'
        $VMResources.properties.storageProfile.dataDisks[0].PsObject.Members.Remove('vhd')
        Write-Verbose  'Adding Managed disk reference for Data disk section'
        $VMResources.properties.storageProfile.dataDisks | Add-Member -MemberType NoteProperty -Name managedDisk -Value $managedDisk
        Write-Verbose  'Removing Storage account from template'
        $InputTemplate.resources = $InputTemplate.resources |
            Where-Object -FilterScript {
            $_.name -ne "[parameters('StorageAccountName')]" }
        $VMResources.dependsOn = $VMResources.dependsOn |
            Where-Object {$_ -notlike "*parameters('StorageAccountName')*" }
        #$VMResources.PsObject.Members.Remove('managedDisk')
    }
    else
    {
        Write-Verbose "Progressing VM creation with Standard Disks"
    }
    if ($UseExistingDisk)
    {
        Write-Verbose  'Changing depployment from FROMIMAGE to ATTACH'
        $VMResources.properties.storageProfile.osDisk.createOption = 'Attach'
        Write-Verbose  'Removing osProfile section'
        $VMResources.properties.PsObject.Members.Remove('osProfile')
        Write-Verbose  'Removing imageReference section'
        $VMResources.properties.storageProfile.PsObject.Members.Remove('imageReference')
        $VMResources.properties.storageProfile.osDisk | Add-Member -MemberType NoteProperty -Name osType -Value $osType
        If ($ManagedDisks)
        {
            Write-Verbose "Adding osDisk.managedDisk.id"
            $VMResources.properties.storageProfile.osDisk.managedDisk | Add-Member -MemberType NoteProperty -Name id -Value "[resourceId('Microsoft.Compute/disks', concat(parameters('VMDiskName'), '-osdisk'))]"
        }
        Write-Verbose  'Removing dataDisks section'
        Write-Verbose  'Dont forget to add DATA disks later, if VM has had any!!!!'
        $VMResources.properties.storageProfile.PsObject.Members.Remove('dataDisks')
    }
    else
    {
        Write-Verbose  "Preparing to deploy from image $ImageSKU"
    }
    Write-Verbose "Data disks count has been specified as [$DatadisksCount]"
    if ($DatadisksCount -lt 1)
    {
        Write-Verbose  'Removing dataDisks section'
        $VMResources.properties.storageProfile.PsObject.Members.Remove('dataDisks')
    }
    elseif ($DatadisksCount -gt 1)
    {
        $i = 2
        While ($i -le $DatadisksCount)
        {
            Write-Verbose "Addinig additional disk[$i]"
            $DataDiskResourceBase = $VMResources.properties.storageProfile.dataDisks[0] | ConvertTo-Json -depth 100 | ConvertFrom-Json
            $DataDiskResourceBase.lun = $($i - 1)
            $DataDiskResourceBase.name = $DataDiskResourceBase.name.Replace('1', $i)
            if (!$ManagedDisks)
            {
                Write-verbose "Updating properties of DataDisk[$i] to be managed disk"
                $DataDiskResourceBase.vhd.uri
                $DataDiskResourceBase.vhd.uri = $DataDiskResourceBase.vhd.uri.Replace('1', $i)
                $DataDiskResourceBase.vhd.uri
            }
            $VMResources.properties.storageProfile.dataDisks += $DataDiskResourceBase
            $i ++
        }
    }
    if ($IfaceCount -gt 1)
    {
        Write-Verbose  "Changing depployment For Multiple Interfaces with the number of [$IfaceCount]"
        Write-Verbose  'Adding Interfaces'
        $count = 1
        While ($count -lt $IfaceCount)
        {
            Write-Verbose "Adding interface number $($count+1)"
            $iface = [pscustomobject][ordered]@{
                id         = "[resourceId('Microsoft.Network/networkInterfaces',parameters('IfaceNames')[$count])]"
                properties	= [pscustomobject][ordered]@{
                    primary                     = "false"
                    enableAcceleratedNetworking = $strEnableAcceleratedNetworking
                }
            }
            $VMResources.properties.networkProfile.networkInterfaces += $iface
            $VMResources.dependsOn += "[resourceId('Microsoft.Network/networkInterfaces',parameters('IfaceNames')[$count])]"
            $count += 1
        }
    }
    else
    {
        Write-Verbose  "VM has only 1 interface to go with! Skipping Adding additional Interfaced to template."
    }
    if ($UsePlan)
    {
        Write-Verbose  'Adding Plan to the Deployment'
        $plan = [pscustomobject][ordered]@{
            name      = "[parameters('imageSku')]"
            publisher = "[parameters('imagePublisher')]"
            product   = "[parameters('imageOffer')]"
        }
        $VMResources | Add-Member -MemberType NoteProperty -Name plan -Value $plan
    }
    else
    {
        Write-Verbose  'No Plan has been used.'
    }
    If ($SkipExtensions)
    {
        Write-Verbose "SkipExtensions has ben selected. Exctentions will be skipped."
        Write-Verbose "Removing [MS.MicrosoftMonitoringAgent]"
        $VMResources.resources = $VMResources.resources |
            Where-Object -FilterScript {
            $_.name -notmatch "MS.MicrosoftMonitoringAgent" }
        Write-Verbose "Removing [MS.Insights.VMDSettings_template]"
        $VMResources.resources = $VMResources.resources |
            Where-Object -FilterScript {
            $_.name -notmatch "MS.Insights.VMDSettings_template" }
        Write-Verbose "Removing [BGInfo_template]"
        $InputTemplate.resources = $InputTemplate.resources |
            Where-Object -FilterScript {
            $_.name -notmatch "BGInfo_template" }
    }
    else
    {
        $MonitoringAgentResource = $VMResources.resources |
            ForEach-Object -Process {$_} | Where-Object -FilterScript {
            $_.name -eq 'MS.MicrosoftMonitoringAgent'}
        $VMDiagIngnosticsResource = $VMResources.resources |
            ForEach-Object -Process {$_} | Where-Object -FilterScript {
            $_.name -eq 'MS.Insights.VMDSettings_template'}
        $BGInfoResource = $InputTemplate.resources |
            ForEach-Object -Process {$_} | Where-Object -FilterScript {
            $_.name -eq 'BGInfo_template'}
        $MonitoringAgentResource.name += $(Get-mrvRandomString 3) + $VMname + $timestamp
        $VMDiagIngnosticsResource.name += $(Get-mrvRandomString 3) + $VMname + $timestamp
        $BGInfoResource.name += $(Get-mrvRandomString 3) + $VMname + $timestamp
        if ($VMDiagIngnosticsResource.name.length -gt 64)
        {
            $VMDiagIngnosticsResource.name = $VMDiagIngnosticsResource.name.Substring(0, 64)
        }
        if ($MonitoringAgentResource.name.length -gt 64)
        {
            $MonitoringAgentResource.name = $MonitoringAgentResource.name.Substring(0, 64)
        }
        Write-Verbose  "BGInfo url is $($JSONUrlBase + $containername + '/'+$JSONBGinfoTemplateFile+$token)"
        Copy-Item -Path $($PSScriptRoot.Substring(0, $PSScriptRoot.LastIndexOf($PathDelimiter)) + $JsonSourceTemlates + $JSONBGinfoTemplateFile) -Destination $DeploymentTempPath
        Write-Verbose  "AzureDiagnostics  url is $($JSONUrlBase + $containername + '/'+$JSONAzureDiagnosticsTemplateFile+$token)"
        Copy-Item -Path $($PSScriptRoot.Substring(0, $PSScriptRoot.LastIndexOf($PathDelimiter)) + $JsonSourceTemlates + $JSONAzureDiagnosticsTemplateFile) -Destination $DeploymentTempPath
        Write-Verbose  "AzureOMS url is $($JSONUrlBase + $containername + '/'+$JSONOMSTemplateFile+$token)"
        $OMSTemplatePath = $PSScriptRoot.Substring(0, $PSScriptRoot.LastIndexOf($PathDelimiter)) + $JsonSourceTemlates + $JSONOMSTemplateFile
        if ($OMSbyId)
        {
            Copy-Item -Path $OMSTemplatePath -Destination $DeploymentTempPath
        }
        else
        {
            Write-Verbose  "Loading OMS Template from file [$OMSTemplatePath]"
            $OMSJsonTemplate = [system.io.file]::ReadAllText($OMSTemplatePath) -join "`n" | ConvertFrom-Json
            $OMSJsonTemplate.resources[0].properties.settings.workspaceId = "[reference(resourceId('Microsoft.OperationalInsights/workspaces/', parameters('workspaceName')), '2015-03-20').customerId]"
            $OMSJsonTemplate.resources[0].properties.protectedSettings.workspaceKey = "[listKeys(resourceId('Microsoft.OperationalInsights/workspaces/', parameters('workspaceName')), '2015-03-20').primarySharedKey]"
            $json_content = $OMSJsonTemplate | ConvertTo-Json -Depth 50
            [system.io.file]::WriteAllText($($DeploymentTempPath + $JSONOMSTemplateFile), $json_content)
        }
    }
    Write-Verbose  "Saving Main Template to file [$OutFileName] as [$($DeploymentTempPath + $OutFileName)] to be uploaded for provisioning"
    try
    {
        $json_content = $InputTemplate | ConvertTo-Json -Depth 50
        [system.io.file]::WriteAllText($($DeploymentTempPath + $OutFileName), $json_content)
    }
    catch
    {
        Write-Error  "Can't save or convert the main template to a file $($DeploymentTempPath +$OutFileName) !"
        return $false
    }
    Write-Verbose "Processing Parameters for VM Deployment"
    $InputParameters.parameters | Add-Member -MemberType NoteProperty -Name VMname -Value @{Value = $VMname}
    $InputParameters.parameters | Add-Member -MemberType NoteProperty -Name location -Value @{Value = $location}
    $InputParameters.parameters | Add-Member -MemberType NoteProperty -Name StorageAccountName -Value @{Value = $StorageAccountName}
    $InputParameters.parameters | Add-Member -MemberType NoteProperty -Name ImageSKU -Value @{Value = $ImageSKU}
    $InputParameters.parameters | Add-Member -MemberType NoteProperty -Name templateBaseUrl -Value @{Value = $JsonTemplatesUrl}
    $InputParameters.parameters | Add-Member -MemberType NoteProperty -Name BGInfoTemplate -Value @{Value = $JSONBGinfoTemplateFile}
    $InputParameters.parameters | Add-Member -MemberType NoteProperty -Name AzureDiagnosticsTemplate -Value @{Value = $JSONAzureDiagnosticsTemplateFile}
    $InputParameters.parameters | Add-Member -MemberType NoteProperty -Name Token -Value @{Value = $token}
    $InputParameters.parameters | Add-Member -MemberType NoteProperty -Name vmSize -Value @{Value = $VMSize}
    $InputParameters.parameters | Add-Member -MemberType NoteProperty -Name VMIPaddresses -Value @{Value = $VMIPaddresses}
    $InputParameters.parameters | Add-Member -MemberType NoteProperty -Name VNetName -Value @{Value = $VNetName}
    $InputParameters.parameters | Add-Member -MemberType NoteProperty -Name SubNetNames -Value @{Value = $SubNetNames}
    $InputParameters.parameters | Add-Member -MemberType NoteProperty -Name IPConfigNames -Value @{Value = $IPConfigNames_array}
    $InputParameters.parameters | Add-Member -MemberType NoteProperty -Name IfaceNames -Value @{Value = $IfaceNames_array}
    $InputParameters.parameters | Add-Member -MemberType NoteProperty -Name IfaceCount -Value @{Value = $IfaceCount}
    $InputParameters.parameters | Add-Member -MemberType NoteProperty -Name VMDiskName -Value @{Value = $VMDiskName}
    $InputParameters.parameters | Add-Member -MemberType NoteProperty -Name availabilitySetName -Value @{Value = $availabilitySetName}
    $InputParameters.parameters | Add-Member -MemberType NoteProperty -Name VNetResourceGroup -Value @{Value = $VNetResourceGroup}
    $InputParameters.parameters | Add-Member -MemberType NoteProperty -Name adminUserName -Value @{Value = $VMAdminUsername}
    $InputParameters.parameters | Add-Member -MemberType NoteProperty -Name adminPassword -Value @{Value = $VMAdminPassword}
    $InputParameters.parameters | Add-Member -MemberType NoteProperty -Name storageAccountType -Value @{Value = $StorageAccountType}
    $InputParameters.parameters | Add-Member -MemberType NoteProperty -Name StorageDiagAccountName -Value @{Value = $DiagStorageAccountName}
    $InputParameters.parameters | Add-Member -MemberType NoteProperty -Name StorageDiagResourceGroup -Value @{Value = $DiagStorageResourceGroup}
    $InputParameters.parameters | Add-Member -MemberType NoteProperty -Name MicrosoftMonitoringAgentTemplate -Value @{Value = $JSONOMSTemplateFile}
    $InputParameters.parameters | Add-Member -MemberType NoteProperty -Name workspaceId -Value @{Value = $workspaceId}
    $InputParameters.parameters | Add-Member -MemberType NoteProperty -Name workspaceKey -Value @{Value = $workspaceKey}
    $InputParameters.parameters | Add-Member -MemberType NoteProperty -Name workspaceName -Value @{Value = $workspaceName}
    $InputParameters.parameters | Add-Member -MemberType NoteProperty -Name imagePublisher -Value @{Value = $imagePublisher}
    $InputParameters.parameters | Add-Member -MemberType NoteProperty -Name imageOffer -Value @{Value = $imageOffer}
    $InputParameters.parameters | Add-Member -MemberType NoteProperty -Name DatadiskSizeGB -Value @{Value = $DatadiskSizeGB}
    $InputParameters.parameters | Add-Member -MemberType NoteProperty -Name FaultDomainCount -Value @{Value = $FaultDomainCount}
    $InputParameters.parameters | Add-Member -MemberType NoteProperty -Name UpdateDomainCount -Value @{Value = $UpdateDomainCount}
    $InputParameters.parameters | Add-Member -MemberType NoteProperty -Name EnableAcceleratedNetworking -Value @{Value = $EnableAcceleratedNetworking.IsPresent}


    Write-Verbose  "Saving Main Parameters Template to file [$JSONParametersOutFileName] as [$($DeploymentTempPath + $JSONParametersOutFileName)] to be uploaded for provisioning"
    try
    {
        $json_content = $InputParameters | ConvertTo-Json -Depth 50
        [system.io.file]::WriteAllText($($DeploymentTempPath + $JSONParametersOutFileName), $json_content)
    }
    catch
    {
        Write-Error  "Can't save or convert the main template to a file $($DeploymentTempPath +$JSONParametersOutFileName) !"
        return $false
    }
    $json_content = $null

    Write-Verbose  "Saving After Deployment script to file [$CustomScript] as [$($DeploymentTempPath + $CustomScript)] to be uploaded for provisioning"
    try
    {
        [system.io.file]::WriteAllText($($DeploymentTempPath + $CustomScript), $InputPostTasks)
    }
    catch
    {
        Write-Error  "Can't save or convert the main template to a file $($DeploymentTempPath +$CustomScript) !"
        return $false
    }
    if (!$StandaloneVM)
    {
        if ($UseExistingDisk -or ($osType -eq 'Linux'))
        {
            Write-Verbose  'Skipping Domain Joining Template preparation'
        }
        else
        {
            Write-Verbose "Copying the $JSONJoinDomainTemplateFile"
            Copy-Item -Path $($PSScriptRoot.Substring(0, $PSScriptRoot.LastIndexOf($PathDelimiter)) + $JsonSourceTemlates + $JSONJoinDomainTemplateFile) -Destination $DeploymentTempPath
            $JsonUrlJoinDomain = $JSONUrlBase + $containername + '/' + $JSONJoinDomainTemplateFile + $token
            Write-Verbose  "JoinDomain url is  $JsonUrlJoinDomain"
        }
    }
    else
    {
        Write-Verbose  'Standalone Machine Skipping Domain Join Operations'
    }
    Write-Verbose  'Going to upload the Json templated to BLOB storage'
    Write-Verbose  'Uploading files.....'
    $files = Get-ChildItem -Recurse -Path $DeploymentTempPath
    foreach ($file in $files)
    {
        If ($ScriptRuntimeWin)
        {
            Set-AzureStorageBlobContent -Context $storageContext -File $($file.FullName)  -Container $containername
        }
        else
        {
            az storage blob upload --container-name $containername --account-name $JsonStorageAccountName  --account-key "$JsonStorageAccountKey" --file $($file.FullName) --name $($file.Name) --output json | ConvertFrom-Json
        }
    }
    If ( $Simulate)
    {
        Write-Verbose  'Simulate has been used!'
        Write-Verbose  'Skipping Deployment'
        return $false
    }
    else
    {
        Write-Verbose  'Provisioning VM.....'
        $DeploymentSatus = New-AzureRmResourceGroupDeployment -ResourceGroupName $ResourceGroupName -Verbose -Name $DeploymentName -TemplateUri $JsonUrlMain -TemplateParameterUri $JSONParametersUrl
        <#  $DeploymentSatus = New-AzureRmResourceGroupDeployment -ResourceGroupName $ResourceGroupName -Verbose -Name $DeploymentName -TemplateUri $JsonUrlMain -VMName $VMname `
            -location $location -StorageAccountName $StorageAccountName -ImageSKU $ImageSKU `
            -templateBaseUrl $JsonTemplatesUrl -BGInfoTemplate $JSONBGinfoTemplateFile -AzureDiagnosticsTemplate $JSONAzureDiagnosticsTemplateFile -Token $token `
            -vmSize $VMSize -VMIPaddresses $VMIPaddresses -VNetName $VNetName -SubNetNames $SubNetNames `
            -IPConfigNames $IPConfigNames_array -IfaceNames $IfaceNames_array -IfaceCount $IfaceCount -VMDiskName $VMDiskName -availabilitySetName $availabilitySetName `
            -VNetResourceGroup $VNetResourceGroup -adminUserName $VMAdminUsername -adminPassword $VMAdminPassword -storageAccountType $StorageAccountType -StorageDiagAccountName $DiagStorageAccountName `
            -MicrosoftMonitoringAgentTemplate $JSONOMSTemplateFile -workspaceId $workspaceId  -workspaceKey $workspaceKey -imagePublisher $imagePublisher -imageOffer $imageOffer `
            -DatadiskSizeGB $DatadiskSizeGB -FaultDomainCount $FaultDomainCount -UpdateDomainCount $UpdateDomainCount -EnableAcceleratedNetworking $EnableAcceleratedNetworking.IsPresent
    #>
    }
    Write-Verbose  'Deployment status ....'

    $EmailBody = [pscustomobject][ordered]@{
        VMName          = $VMname
        ResourceGroup   = $ResourceGroupName
        Subscription    = $SubscriptionName
        VMSize          = $VMSize
        VMIPaddresses   = $VMIPaddresses
        ImageSKU        = $ImageSKU
        ChangeControl   = $ChangeControl
        Description     = $Description
        ExistingVHDUsed = $UseExistingDisk
    }
    $EmailTitle = "VM Provisioning Operation for VM [$VMname] in Resource Group [$ResourceGroupName] completed with status [$($DeploymentSatus.ProvisioningState)]"
    if ($DeploymentSatus.ProvisioningState -like 'Succeeded')
    {
        Write-Verbose 'Deployment Succeed!'
    }
    if (($DeploymentSatus.ProvisioningState -like 'Succeeded') -or $ForcePostTasks)
    {
        Write-Verbose "Performing After Deployment Tasks"

        if (-not $StandaloneVM)
        {
            if ($UseExistingDisk -or ($osType -ne 'Windows') <#-or $SkipExtensions #>)
            {
                Write-Verbose  "Skipping Domain Joining as using Existing Disk or [SkipExtensions] specified or OS is not Windows."
            }
            else
            {
                Write-Verbose  "Joining Virtual Machine to Domain [$DomainDNS] "
                $DeploymentName = $ResourceGroupName + '-D-' + $VMname + '-JoinDomain-' + $timestamp
                If ($DeploymentName.Length -gt 64) { $DeploymentName = $DeploymentName.Substring(64)}
                Write-Verbose "Starting Domain Join Extention deployment"
                $JoinDomainDeployment = New-AzureRmResourceGroupDeployment -Name $DeploymentName -ResourceGroupName $ResourceGroupName -Verbose -TemplateUri $JsonUrlJoinDomain -VMName $VMname -apiVersion '2015-06-15' -location $location  -domainUsername $DomainUser -domainPassword $DomainPass -domainToJoin $DomainDNS -ouPath $AzureServersOU
                if ($JoinDomainDeployment.ProvisioningState -like 'Succeeded')
                {
                    Write-Verbose "Domain Join Operation has been completed sucessfully."
                }
                else
                {
                    Write-Error "Domain Join operation has failed."
                }
            }
        }
        else
        {
            Write-Verbose  'Standalone Machine. Skipping Domain Joing...'
        }
        if ($UseExistingDisk)
        {
            Write-Verbose  'Skipping After Deployment Tasks as using Existing VHD or [SkipExtensions] specified'
        }
        elseif (-not $SkipExtensions)
        {
            Write-Verbose  'Provisioning After Deployment Tasks....'
            $CustExtInstStatus = Set-AzureRmVMCustomScriptExtension -Name 'AfterDeploymentTasks' -FileUri $CustomScriptUrl -Run $CustomScript -VMName $VMname -Location $location -ResourceGroupName $ResourceGroupName -TypeHandlerVersion "1.4"
            If ( -not $CustExtInstStatus.IsSuccessStatusCode)
            {
                Write-Error "Custom Script Deployment failed. WinRM would be unavailable, Locale settings and other stuff will be unavailable"
                Write-Error "Error: $($CustExtInstStatus.error.code)"
                Write-Error "Message: $($CustExtInstStatus.error.Message)"
            }
            else
            {
                Write-Verbose "Provisioning After Deployment Tasks Completed Sucessfully"
            }
        }
        Start-MRVWait -AprxDur 60 -Wait_Activity "Waiting before removal of joindomain extension...."
        Write-verbose "Removing joindomain extention"
        Remove-AzureRmVMExtension -ResourceGroupName $ResourceGroupName -VMName $VMname -Name "joindomain" -Force
        Start-MRVWait -AprxDur 60 -Wait_Activity "Waiting before removal of extensions...."
        Write-verbose "Removing AfterDeploymentTasks extention AfterDeploymentTasks"
        Remove-AzureRmVMExtension -ResourceGroupName $ResourceGroupName -VMName $VMname -Name "AfterDeploymentTasks" -Force
        Write-Verbose "Updating VM Tags"
        $TagsTable.Add('Description', $Description)
        $TagsTable.Add('ChangeControl', $ChangeControl)
        Update-MRVAzureTag -ResourceName $VMname -ResourceGroupName $ResourceGroupName -TagsTable $TagsTable -EnforceTag -SubscriptionName $SubscriptionName
        $time_end = get-date
        if ($DoNotCleanup)
        {
            Write-Verbose "Skipping Temp folder [$DeploymentTempPath] cleanup"
        }
        else
        {
            Write-verbose "Cleaning Temp folder [$DeploymentTempPath]"
            Remove-Item -Path $DeploymentTempPath -Force -Recurse
        }

        Write-Verbose  "Deployment finished at [$time_end]"
        Write-Verbose  "Deployment has been running for $(($time_end - $time_start).Hours) Hours and $(($time_end - $time_start).Minutes) Minutes"
        return $true
    }
}