Function New-MRVAzureSPNVMPower
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

    $AppName = $AutomationAccountName + "VMPowerManagementSPN"
    $AzureADApplication = Get-AzureRmADApplication -DisplayNameStartWith $AppName
    If ($AzureADApplication.Count -gt 0)
    {
        Write-Verbose "SPN with the name [$AppName] already exist"
        $AzureADApplication = $AzureADApplication[0]
    }
    else
    {
        $Password = Get-MRVTempPassword -length 30
        $AzureADApplication = New-AzureRmADApplication `
            -DisplayName $AppName `
            -HomePage "https://localhost/$AppName" `
            -IdentifierUris "https://localhost/$AppName" `
            -Password $Password `
            -EndDate (Get-Date).AddYears(5)
    }

    if (Get-AzureRmRoleDefinition -Name "Virtual Machine Power Operator")
    {
        $true
    }
    else
    {
        Write-Host "Determine OS we are running script from..."
        If ($($ENV:OS) -eq $null)
        {

            $ScriptRuntimeWin = $false
            $JsonTempFolder = '/tmp/'
            $PathDelimiter = '/'
        }
        else
        {
            Write-Host "OS has been identified as Windows"
            $ScriptRuntimeWin = $true
            $PathDelimiter = '\'
        }

        $JSONRolseBaseFile = 'Azure_Role_VMPowerOperator.json'
        $JsonSourceTemlates = $PathDelimiter + 'Resources' + $PathDelimiter + 'Templates' + $PathDelimiter
        $InputTemplatePath = $PSScriptRoot.Substring(0, $PSScriptRoot.LastIndexOf($PathDelimiter)) + $JsonSourceTemlates + $JSONBaseTemplateFile
        Write-Host  "Loading Template from file [$InputTemplatePath]"
        try
        {
            $RoleTemplate = [system.io.file]::ReadAllText($InputTemplatePath) -join "`n" | ConvertFrom-Json
        }
        catch
        {
            Write-Error  "Can't load the main template! Please check the path [$InputTemplatePath]"
            return $false
        }
    }


}