
<#


.SYNOPSIS
This Powershell Script adds hosts to the SmartCenter database.

.DESCRIPTION
This script adds a single host to SmartCenter. Unless the user enters the parameters to the call itself,  it prompts the user to add a host name and host IP address.
The script first tries to use shell objects to send a keepalive to the management server.
If that fails, the CPAPI-Authenticate is invoked and the user is prompted to enter his credentials and the smartcenter details.
If NAT settings need to be added, use them as parameters in the command line themselves (try typing "-" after the script name.
you'll need to add "true" to NATSettings and then all the required information)

.EXAMPLE


.NOTES
Some options of the Add-host API are not implemented in this script!


.LINK
https://sc1.checkpoint.com/documents/R80/APIs/?#cli/add-host


#>
Function New-MRVCKPFNetwork
{
    param(
        [Parameter(ParameterSetName = 'masklength', Mandatory = $true, HelpMessage = "New Network Name")]
        [Parameter(ParameterSetName = 'subnetmask', Mandatory = $true, HelpMessage = "New Network Name")]
        #[Parameter(ParameterSetName = 'Nat',Mandatory=$true, HelpMessage="New Network Name")]
        [String]$name,

        [Parameter(ParameterSetName = 'masklength', Mandatory = $true, HelpMessage = "New Network Name")]
        [Parameter(ParameterSetName = 'subnetmask', Mandatory = $true, HelpMessage = "New Network Name")]
        #[Parameter(ParameterSetName = 'Nat',Mandatory=$true, HelpMessage="New Host IP Address")]
        [String]$subnet,

        [Parameter(ParameterSetName = 'masklength', Mandatory = $true, HelpMessage = "Pv4 or IPv6 network mask length.")]
        #[Parameter(ParameterSetName = 'Nat',Mandatory=$true, HelpMessage="Pv4 or IPv6 network mask length.")]
        [String]$masklength,

        [Parameter(ParameterSetName = 'subnetmask', Mandatory = $true, HelpMessage = "IPv4 network mask.")]
        #[Parameter(ParameterSetName = 'Nat',Mandatory=$true, HelpMessage="IPv4 network mask.")]
        [String]$subnetmask,

        [Parameter(ParameterSetName = 'masklength', Mandatory = $false)]
        [Parameter(ParameterSetName = 'subnetmask', Mandatory = $false)]
        #[Parameter(ParameterSetName = 'Nat',Mandatory=$false)]
        [Validateset("aquamarine 1", "black", "blue", "dark blue", "blue 1", "burly wood 4", "cyan", "dark green", "dark khaki", "dark orchid", "dark orange 3", "dark sea green 3", "deep pink", "deep sky blue 1", "dodger blue 3", "firebrick", "foreground", "forest green", "gold", "gold 3", "gray 83", "gray 90", "green", "lemon chiffon", "light coral", "light sea green", "light sky blue 4", "magenta", "medium orchid", "medium slate blue", "medium violet red", "navy blue", "olive drab", "orange", "red", "sienna", "yellow", "none")]
        [String]$color = 'black',

        [Parameter(ParameterSetName = 'masklength', Mandatory = $false)]
        [Parameter(ParameterSetName = 'subnetmask', Mandatory = $false)]
        #[Parameter(ParameterSetName = 'Nat',Mandatory=$false)]
        [String]$comments,

        [Parameter(ParameterSetName = 'masklength', Mandatory = $false)]
        [Parameter(ParameterSetName = 'subnetmask', Mandatory = $false)]
        #[Parameter(ParameterSetName = 'Nat',Mandatory=$false)]
        [String[]]$groups,

        [Parameter(ParameterSetName = 'masklength', Mandatory = $false, HelpMessage = "define NAT?")]
        [Parameter(ParameterSetName = 'subnetmask', Mandatory = $false, HelpMessage = "define NAT?")]
        #[Parameter(ParameterSetName = 'Nat',Mandatory=$false, HelpMessage="define NAT?")]
        [switch]$NATSettings,

        [Parameter(ParameterSetName = 'masklength', Mandatory = $false, HelpMessage = "Whether to add automatic address translation rule")]
        [Parameter(ParameterSetName = 'subnetmask', Mandatory = $false, HelpMessage = "Whether to add automatic address translation rule")]
        #[Parameter(ParameterSetName = 'Nat',Mandatory=$false, HelpMessage="Whether to add automatic address translation rule")]
        [Validateset("TRUE", "FALSE")]
        [String]$autorule,

        [Parameter(ParameterSetName = 'masklength', Mandatory = $false)]
        [Parameter(ParameterSetName = 'subnetmask', Mandatory = $false)]
        #[Parameter(ParameterSetName = 'Nat',Mandatory=$false)]
        [String]$NATIPv4Address,

        [Parameter(ParameterSetName = 'masklength', Mandatory = $false)]
        [Parameter(ParameterSetName = 'subnetmask', Mandatory = $false)]
        #[Parameter(ParameterSetName = 'Nat',Mandatory=$false)]
        [String]$NATIPv6Address,

        [Parameter(ParameterSetName = 'masklength', Mandatory = $false)]
        [Parameter(ParameterSetName = 'subnetmask', Mandatory = $false)]
        #[Parameter(ParameterSetName = 'Nat',Mandatory=$false)]
        [Validateset("gateway", "ip-address")]
        [String]$HideBehind,

        [Parameter(ParameterSetName = 'masklength', Mandatory = $false)]
        [Parameter(ParameterSetName = 'subnetmask', Mandatory = $false)]
        #[Parameter(ParameterSetName = 'Nat',Mandatory=$false)]
        [String]$Installon,

        [Parameter(ParameterSetName = 'masklength', Mandatory = $false)]
        [Parameter(ParameterSetName = 'subnetmask', Mandatory = $false)]
        #[Parameter(ParameterSetName = 'Nat',Mandatory=$false)]
        [Validateset("hide", "static")]
        [String]$Method,


        [Parameter(ParameterSetName = 'masklength', Mandatory = $false)]
        [Parameter(ParameterSetName = 'subnetmask', Mandatory = $false)]
        #[Parameter(ParameterSetName = 'Nat',Mandatory=$false)]
        [String]$SmartCenterAddress = $(throw "Please Provide IP or FQDN for the CheckPoint Management Server"),

        [Parameter(ParameterSetName = 'masklength', Mandatory = $false)]
        [Parameter(ParameterSetName = 'subnetmask', Mandatory = $false)]
        #[Parameter(ParameterSetName = 'Nat',Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [hashtable] $CKPFHeader
    )


    # do a sanity check to see that the user is logged in. If not call the login script

    try
    {
        $CKPFKeepAloveURI = "https://$SmartCenterAddress/web_api/keepalive"
        $CKPFEmptyJson = @{} | convertto-json -compress
        $keepalive = Invoke-WebRequest -uri $CKPFKeepAloveURI -ContentType application/json -Method POST -headers $CKPFHeader -body $CKPFEmptyJson -ErrorAction Stop
    }
    catch
    {
        $keepalive = $_.Exception.Response
        Write-Host "It looks like session has expired. Please get a new header with Get-MRVCKPFAuthSID" -ForegroundColor Red
        return $false
    }


    # create a request body
    $CKPFRequestBody = @{name = $name; subnet = $subnet; color = $color}
    if ($NATSettings)
    {
        $nat = @{}
        if ($autorule.length -gt 0) {$nat.add("auto-rule", $autorule)}
        if ($NATIPv4Address.length -gt 0) {$nat.add("ipv4-address", $NATIPv4Address)}
        if ($NATIPv6Address.length -gt 0) {$nat.add("ipv6-address", $NATIPv6Address)}
        if ($HideBehind.length -gt 0) {$nat.add("hide-behind", $HideBehind)}
        if ($Installon.length -gt 0) {$nat.add("install-on", $Installon)}
        if ($Method.length -gt 0) {$nat.add("method", $Method)}
        $CKPFRequestBody.add("nat-settings", $nat)
    }

    switch ($PsCmdlet.ParameterSetName)
    {
        'masklength'
        {
            $CKPFRequestBody += @{ 'mask-length' = $masklength}
        }

        'subnetmask'
        {
            $CKPFRequestBody += @{ 'subnet-mask' = $subnetmask}
        }
    }

    if ($comments -ne '')
    {
        $CKPFRequestBody.add("comments", $comments)
    }

    if ($groups.Count -gt 0)
    {
        $CKPFRequestBody.add("groups", $groups)
    }
    $CKPFRequestBody
    $mybodyjson = $CKPFRequestBody | convertto-json -compress
    $mybodyjson

    #create the add host uri
    $AddURI = "https://$SmartCenterAddress/web_api/add-network"

    #allow self signed certs
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $True }

    # add host to server
    try
    {
        $CKPFResponse = Invoke-WebRequest -uri $AddURI -ContentType application/json -Method POST -headers $CKPFHeader -body $mybodyjson
    }
    catch
    {
        Write-Host "Adding failed!" -ForegroundColor Red
        return $CKPFResponse
    }
    # publish

    $CKPFPublishURI = "https://$SmartCenterAddress/web_api/publish"
    $CKPFPublishBodyJSON = @{} | convertto-json -compress

    $CKPFPublishResponse = Invoke-WebRequest -uri $CKPFPublishURI -ContentType application/json -Method POST -headers $CKPFHeader -body $CKPFPublishBodyJSON

    #show happy ending
    if ($CKPFPublishResponse.statuscode -eq 200)
    {
        Write-Host "Script completed. Host was added"
    }
    return $CKPFPublishResponse

}