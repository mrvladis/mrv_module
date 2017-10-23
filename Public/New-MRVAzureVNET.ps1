<#
.Synopsis

.Description


	Limitations
	----------

	Change Log
	----------
	v.1.0.0.0		- Initial Version

	Backlog
	--------

	Output
	--------


Syntax: Function has the following parameters:

 .Parameter ModuleName



 .Example

#>
Function New-MRVAzureVNET
{
    [CmdletBinding()]
    Param
    (
        [Parameter(ParameterSetName = 'Basic', Mandatory = $true)]
        [Parameter(ParameterSetName = 'HashTable', Mandatory = $true)]
        [String]
        $VNETName,

        [Parameter(ParameterSetName = 'Basic', Mandatory = $true)]
        [Parameter(ParameterSetName = 'HashTable', Mandatory = $true)]
        [String]
        $VNETCIDR,

        [Parameter(ParameterSetName = 'Basic', Mandatory = $true)]
        [Parameter(ParameterSetName = 'HashTable', Mandatory = $true)]
        [String]
        $ResourceGroupName,

        [Parameter(ParameterSetName = 'Basic', Mandatory = $true)]
        [Parameter(ParameterSetName = 'HashTable', Mandatory = $true)]
        [String]
        $SubscriptionName = $(throw "Please Provide the name for Subscription!"),

        [Parameter(ParameterSetName = 'Basic', Mandatory = $true)]
        [Parameter(ParameterSetName = 'HashTable', Mandatory = $true)]
        [ValidateSet('eastasia',
            'southeastasia',
            'centralus',
            'eastus',
            'eastus2',
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
        $Location,

        [Parameter(ParameterSetName = 'Basic', Mandatory = $true)]
        [String[]]
        $SubnetNames,

        [Parameter(ParameterSetName = 'Basic', Mandatory = $true)]
        [String[]]
        $SubnetCIDRs,

        [Parameter(ParameterSetName = 'HashTable', Mandatory = $true)]
        [hashtable]
        $Subnets,

        [Parameter(ParameterSetName = 'Basic', Mandatory = $false)]
        [Parameter(ParameterSetName = 'HashTable', Mandatory = $false)]
        [string] $Prefix_Main = 'MRV',

        [Parameter(ParameterSetName = 'Basic', Mandatory = $false)]
        [Parameter(ParameterSetName = 'HashTable', Mandatory = $false)]
        [string] $Prefix_RG = 'RG',

        #Storgage account name, where the JSON Templates stored during provisioning
        [Parameter(ParameterSetName = 'Basic', Mandatory = $false)]
        [Parameter(ParameterSetName = 'HashTable', Mandatory = $false)]
        [String]
        $JsonStorageAccountName = 'notdefined',

        <#        #Storgage account key, where the JSON Templates stored during provisioning
        [Parameter(ParameterSetName = 'Basic', Mandatory = $false)]
        [Parameter(ParameterSetName = 'HashTable', Mandatory = $false)]
        [String]
        $JsonStorageAccountKey = 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxx', #>

        [Parameter(ParameterSetName = 'Basic', Mandatory = $false)]
        [Parameter(ParameterSetName = 'HashTable', Mandatory = $false)]
        [Int]
        $TokenExpiry = 45
    )

    Write-Host "VM Provisioning  v.1.0.0.0"
    ##################Loading Modules #################
    [datetime]$time_start = Get-Date
    $timestamp = Get-Date -Format 'yyyy-MM-dd-HH-mm'
    Write-Host "Deployment started at [$time_start]"
    Write-Host 'Loading Azure Modules'
    Write-Host 'Please Wait...'
    If (!(Import-MRVModule  'AzureRM').Result)
    {
        Write-Verbose "Can't load AzureRM module. Let's check if AzureRM.NetCore can be loaded"
        If (!(Import-MRVModule  'AzureRM.NetCore').Result)
        {
            Write-Error "Can't load Azure modules. Please make sure that you have Installed all the modules"
            return $false
        }
    }
    Write-Verbose "Azure Modules have been loaded sucessfully."
    ##################Loading Modules #################
    Write-Host "Determine OS we are running script from..."
    If ($($ENV:OS) -eq $null)
    {
        Write-Host "OS has been identified as NONE-Windows"
        Write-Host "   #### Warning  ####      #### Warning  ####      #### Warning  ####   " -ForegroundColor Yellow
        Write-Host "Some functionality and checks, like Active Directory will be unavailable" -ForegroundColor Yellow
        Write-Host "   #### Warning  ####      #### Warning  ####      #### Warning  ####   " -ForegroundColor Yellow
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
        Write-Host "OS has been identified as Windows"
        $ScriptRuntimeWin = $true
        $PathDelimiter = '\'
    }
    if (! (Test-Path $JsonTempFolder))
    {
        Write-Host "Folder to store temporary Deployment templates [$JsonTempFolder] does not exist! Let's try to create" -ForegroundColor Yellow
        if (New-Item $JsonTempFolder -ItemType Directory)
        {
            Write-Host "Folder to store temporary Deployment templates [$JsonTempFolder] has been created sucessfully" -ForegroundColor Green
        }
        else
        {
            Write-Error "Can't create Folder to store temporary Deployment templates [$JsonTempFolder]. Exiting....."
            return $false
        }
    }

    Write-Host  "Provisional operation has been started with timestamp $timestamp" -BackgroundColor DarkCyan
    $Subscription = Select-MRVSubscription -SubscriptionName $SubscriptionName -ErrorAction SilentlyContinue
    If (!$Subscription.Result)
    {
        Write-Error  'Make sure that you have access and logged in to Azure'
        return $false
    }
    else
    {
        Write-Verbose  'Subscription has been selected successfully.'
    }
    $JSONStorageAccount = Get-MRVAzureModuleStorageAccount -StorageAccountName $JsonStorageAccountName -AccountType JSON -Location $location -SubscriptionName $SubscriptionName -Prefix_Main $Prefix_Main -Prefix_RG $Prefix_RG -Verbose
    $JsonStorageAccountKey = $JSONStorageAccount.StorageAccountKey
    $JsonStorageAccountName = $JSONStorageAccount.StorageAccountName
    $JSONUrlBase = 'https://' + $JsonStorageAccountName + '.blob.core.windows.net/'
    $JsonSourceTemlates = $PathDelimiter + 'Resources' + $PathDelimiter + 'Templates' + $PathDelimiter
    $JSONBaseTemplateFile = 'Azure_VNET.json'
    $JSONParametersFile = 'Azure_VNET_Parameters.json'
    $VNETName = $VNETName.ToUpper()
    $ResourceGroupName = $ResourceGroupName.ToUpper()
    $RGPrefix = $Prefix_Main + '-' + $Prefix_RG + '-'
    $ResourceGroupNametmp = $ResourceGroupName.Substring(0, $ResourceGroupName.lastIndexOf('-'))
    Write-Host 'Running Pre-Checks' -BackgroundColor DarkCyan
    <# If ($ResourceGroupNametmp.Substring(0, $ResourceGroupNametmp.lastIndexOf('-') + 1) -notlike $RGPrefix)
    {
        Write-Error  "$ResourceGroupName Does not meet the naming rules. Should start with: $RGPrefix"
        return $falses
    } #>
    #Validation of the input need to be added.
    Write-Host "Input validation has not yet being defined! Deployment can fail due to incorrect input." -ForegroundColor Yellow
    #Check to validate VNET existence to be added here.
    $LocationCode = (Get-MRVLocationCode $location).LocationCode
    If ($SubnetNames.count -ne $SubnetCIDRs.Count)
    {
        Write-Error "Amount of Subnets [$($SubnetNames.count)] does not meet amount of CIDRs [$($SubnetCIDRs.Count)]"
        return $false
    }
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
    $DeploymentName = $timestamp + '-' + $ResourceGroupName + '-Dep-' + $VNETName
    Write-Verbose  "Getting storage context for account [$JsonStorageAccountName] with provided key....."
    $containername = $DeploymentName.ToLower()
    if ($containername.Length -gt 63)
    {
        $containername = $containername.Substring(0, 63)
    }
    $DeploymentTempPath = (New-Item $(join-path $JsonTempFolder $containername) -type directory).FullName + $PathDelimiter
    if ($ScriptRuntimeWin)
    {
        $storageContext = New-AzureStorageContext -StorageAccountName $JsonStorageAccountName -StorageAccountKey $JsonStorageAccountKey -ErrorAction SilentlyContinue

        If ($storageContext -eq $null)
        {
            Write-Error "Can't create a secure context for storage account [$JsonStorageAccountName]"
            return $false
        }
        else
        {
            Write-Host "Secure context for storage account [$JsonStorageAccountName] has been created sucessfully." -ForegroundColor Green
        }
    }
    Write-Verbose  "Creating container $containername"

    if ($ScriptRuntimeWin)
    {
        $containerResult = New-AzureStorageContainer -Name $containername -Context $storageContext -Permission 'Off'
    }
    else
    {
        $containerResult = az storage container create --name $containername --account-name $JsonStorageAccountName  --account-key $JsonStorageAccountKey --output json | ConvertFrom-Json
    }
    if ($ScriptRuntimeWin)
    {
        Write-Verbose  'Creating a token for the Storage Access'
        $token = New-AzureStorageContainerSASToken -Context $storageContext -Name  $containername -Permission r -StartTime ((Get-Date).ToUniversalTime().AddMinutes(-1)) -ExpiryTime ((Get-Date).ToUniversalTime().AddMinutes($TokenExpiry))
    }
    else
    {
        $token = az storage container generate-sas --name $containername --account-name $JsonStorageAccountName  --account-key $JsonStorageAccountKey --permissions r --start (get-date -Format u (Get-Date).ToUniversalTime().AddMinutes(-1)).Replace(' ', 'T') --expiry (get-date -Format u (Get-Date).ToUniversalTime().AddMinutes($TokenExpiry)).Replace(' ', 'T') --output json | ConvertFrom-Json
        if ($token -ne '')
        {
            $token = '?' + $token
        }
    }
    Write-Host  'Populating URLS for the Base Template' -ForegroundColor DarkGreen
    $JsonTemplatesUrl = $JSONUrlBase + $containername + '/'
    Write-Host  "Main Temlate URL will be $JsonUrlMain Reading Main Template to be deployed"
    Write-Host  'Preparing main template...' -BackgroundColor DarkCyan
    $OutFileName = $JSONBaseTemplateFile.Substring(0, $JSONBaseTemplateFile.IndexOf('.')) + $containername + '.json'
    $JSONParametersOutFileName = $JSONParametersFile.Substring(0, $JSONParametersFile.IndexOf('.')) + $OutFileName
    $JsonUrlMain = $JSONUrlBase + $containername + '/' + $OutFileName + $token
    $JSONParametersUrl = $JSONUrlBase + $containername + '/' + $JSONParametersOutFileName + $token

    $InputTemplate = $null
    $InputTemplatePath = $PSScriptRoot.Substring(0, $PSScriptRoot.LastIndexOf($PathDelimiter)) + $JsonSourceTemlates + $JSONBaseTemplateFile
    Write-Verbose "JSON Main Url is [$JsonUrlMain]"
    Write-Host  "Loading Main Template from file [$InputTemplatePath]"
    try
    {
        $InputTemplate = [system.io.file]::ReadAllText($InputTemplatePath) -join "`n" | ConvertFrom-Json
    }
    catch
    {
        Write-Error  "Can't load the main template! Please check the path [$InputTemplate]"
        return $false
    }
    Write-Host  'Main Template has been loaded successfully!' -ForegroundColor DarkGreen
    $InputParameters = $null
    $InputParametersPath = $PSScriptRoot.Substring(0, $PSScriptRoot.LastIndexOf($PathDelimiter)) + $JsonSourceTemlates + $JSONParametersFile
    Write-Verbose "JSON Parameters Main Url is [$JSONParametersUrl]"
    Write-Host  "Loading Main Parameters Template from file [$InputParametersPath]"
    try
    {
        $InputParameters = [system.io.file]::ReadAllText($InputParametersPath) -join "`n" | ConvertFrom-Json
    }
    catch
    {
        Write-Error  "Can't load the main Parameters template! Please check the path [$InputTemplate]"
        return $false
    }
    $InputTemplate
    $InputParameters

    $InputTemplateVariables = $InputTemplate.variables
    $InputTemplateSubnets = $InputTemplate.resources.properties.subnets

    [int]$Number = 0

    foreach ($SubnetName in $SubnetNames)
    {
        $InputTemplateVariables | Add-Member -MemberType NoteProperty -Name $('Subnet' + $Number + 'Name') -Value $SubnetName
        $InputTemplateVariables | Add-Member -MemberType NoteProperty -Name $('Subnet' + $Number + 'Prefix') -Value $SubnetCIDRs[$Number]

        $SubNet = [pscustomobject][ordered]@{
            name       = "[variables('" + $('Subnet' + $Number + 'Name') + "')]"
            properties	= [pscustomobject][ordered]@{
                addressPrefix = "[variables('" + 'Subnet' + $Number + 'Prefix' + "')]"
            }
        }
        $InputTemplate.resources.properties.subnets += $SubNet
        $Number ++
    }

    $InputParameters.parameters | Add-Member -MemberType NoteProperty -Name VNETName -Value @{Value = $VNETName}
    $InputParameters.parameters | Add-Member -MemberType NoteProperty -Name VNETAddressPrefix -Value @{Value = $VNETCIDR}

    $json_content = $null
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
    $json_content = $null

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
    Write-Host  'Going to upload the Json templated to BLOB storage' -ForegroundColor DarkGreen
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
            az storage blob upload --container-name $containername --account-name $JsonStorageAccountName  --account-key $JsonStorageAccountKey --file $($file.FullName) --name $($file.Name) --output json | ConvertFrom-Json
        }
    }
    Write-Host  'Provisioning NET.....' -ForegroundColor DarkBlue -BackgroundColor White
    $DeploymentSatus = New-AzureRmResourceGroupDeployment -ResourceGroupName $ResourceGroupName -Verbose -Name $DeploymentName -TemplateUri $JsonUrlMain -TemplateParameterUri $JSONParametersUrl


}