<#


.SYNOPSIS
This Powershell Script authenticates users through the MSI endpoint, providing authentication token

.DESCRIPTION
This Powershell Script authenticates users through the MSI endpoint, providing authentication token

.EXAMPLE


.NOTES


.LINK



#>

Function Get-MRVAzureMSIToken
{
    param(
        [Parameter(Mandatory = $false)]
        [String]
        $apiVersion = "2017-09-01",
        [Parameter(Mandatory = $false)]
        [String]
        $resourceURI = "https://management.azure.com/",
        [Parameter(Mandatory = $false)]
        [String]
        $MSISecret,
        [Parameter(Mandatory = $false)]
        [String]
        $MSIEndpoint
    )
    $result = @{Result = $false; Token = $null; Reason = 'Failed to get token'}
    If (($MSIEndpoint -eq $null) -or ($MSIEndpoint -eq ""))
    {
        Write-Output "No MSI Endpont provided, checking in Environment Variables"
        $MSIEndpoint = $env:MSI_ENDPOINT
        if (($MSIEndpoint) -eq $null -or ($MSIEndpoint -eq ""))
        {
            Write-Error "Can't find MSI endpoint in System Variables"
            return $result
        }
    }
    If (($MSISecret -eq $null) -or ($MSISecret -eq ""))
    {
        Write-Output "No MSI Endpont provided, checking in Environment Variables"
        $MSISecret = $env:MSI_SECRET
        if (($MSIEndpoint) -eq $null -or ($MSIEndpoint -eq ""))
        {
            Write-Error "Can't find MSI endpoint in System Variables"
            return $result
        }
    }
    Write-Output "Endpoint: [$MSIEndpoint]"
    $tokenAuthURI = $MSIEndpoint + "?resource=$resourceURI&api-version=$apiVersion"
    $tokenResponse = Invoke-RestMethod -Method Get -Headers @{"Secret" = "$env:MSI_SECRET"} -Uri $tokenAuthURI
    $accessToken = $tokenResponse.access_token

    if (($accessToken -eq $null) -or ($accessToken -eq ""))
    {
        Write-Error "Failed to get Token. It is empty [$accessToken]"
        return $result
    }
    else
    {
        $result = @{Result = $true; Token = $accessToken; Reason = 'Success'}
        return $result
    }
}