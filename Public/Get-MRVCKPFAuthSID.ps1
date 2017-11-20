<#


.SYNOPSIS
This Powershell Script authenticates users to the Check Point API of specific SmartCenter Servers or domains.

.DESCRIPTION
The script allows users to authenticate themselves to some specific Check Point SmartCenter or Domain.
Users can enter parameters (username, password, domain, server address) in advance or interactively, when running the scripts.
If Authenthe script leaves behind in the shell environment two objects, $myCPHeader and $SmartCenterAddress, that can be used to create additional calls to the APIs.
The script also outputs the contents of the reply from the server, if authentication succeeds.

.EXAMPLE


.NOTES
Entering the password in cleartext is optional. If you don't enter that parameter, you'll be prompted to enter the password into a secured string


.LINK



#>

Function Get-MRVCKPFAuthSID
{
    param(
        [Parameter(ParameterSetName = 'UserNamePassword', Mandatory = $true, HelpMessage = "username")]
        [String]$UserName,

        [Parameter(ParameterSetName = 'Credentials', Mandatory = $true, HelpMessage = "Credentials")]
        [ValidateNotNullOrEmpty()]
        [Management.Automation.PSCredential] $Credentials,

        [Parameter(ParameterSetName = 'UserNamePassword', Mandatory = $true, HelpMessage = "clear text password")]
        [String]$ClearTextPassword,

        [Parameter(ParameterSetName = 'UserNamePassword', Mandatory = $false, HelpMessage = "IP Addess of Management Server")]
        [Parameter(ParameterSetName = 'Credentials', Mandatory = $false, HelpMessage = "IP Addess of Management Server")]
        [String]$SmartCenterAddress = $(throw "Please Provide IP or FQDN for the CheckPoint Management Server"),

        [Parameter(ParameterSetName = 'UserNamePassword', Mandatory = $false, HelpMessage = "If connecting to a domain in an MDS, specify it")][AllowNull()]
        [Parameter(ParameterSetName = 'Credentials', Mandatory = $false, HelpMessage = "If connecting to a domain in an MDS, specify it")][AllowNull()]
        [String]$DomainName

    )
    # securely prompt for password if none was provided
    switch ($PsCmdlet.ParameterSetName)
    {
        'UserNamePassword'
        {
            $password = $ClearTextPassword
        }

        'Credentials'
        {
            $password = $Credentials.GetNetworkCredential().password
            $username = $Credentials.UserName
        }
    }
    #create credential json
    $myCredentialhash = @{user = $username; password = $password}

    if ($DomainName.length -gt 0)
    {
        $myCredentialhash.add("domain", $DomainName)
    }

    $myjson = $myCredentialhash | convertto-json -compress
    # create login URI
    $loginURI = "https://$SmartCenterAddress/web_api/login"
    #allow self signed certs
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $True }
    #log in and capture response
    Try
    {
        Write-Host "Going to invoke a request to URI [$loginURI]"
        $myresponse = Invoke-WebRequest -Uri $loginURI -Body $myjson -ContentType application/json -Method POST  -ErrorAction SilentlyContinue
    }
    catch
    {
        Write-Host "Error Accessing the CKPF Management Server" -ForegroundColor Red
        $Error[0]
        Return $false
    }
    #make the content of the response a powershell object
    If ($myresponse -ne $null)
    {
        $myresponsecontent = $myresponse.Content | ConvertFrom-Json
    }
    else
    {
        Write-Host "Got an empty response" -ForegroundColor Red
        Return $false
    }
    #get the sid of the response into its own object
    If ($myresponsecontent -ne $null)
    {
        $mysid = $myresponsecontent.sid
    }
    else
    {
        Write-Host "Got an empty response" -ForegroundColor Red
        Return $false
    }
    #create an x-chkp-sid header
    $myCPHeader = @{"x-chkp-sid" = $mysid}
    return $myCPHeader
    ## make the SmartCenter Address a Global Parameter
}