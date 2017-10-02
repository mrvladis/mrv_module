<#
 .Synopsis
 Function to verify credentials against domain that server used to execute is member of.

 .Description
 Function to verify credentials against domain that server used to execute is member of.
 Credentials can be provided both in UPN or DOMAIN\SAMAccount formats.

  Prequisites
  -----------
QAD Module

  Returns
  -------
Boolean $true if verification was sucessfull or $false if not.

  Limitations and Known Issues
  ----------------------------
  See Backlog !

  Backlog
  --------
  Specify domain to verify credetinals against.

  Change Log
  ----------
  v1.00

 .Parameter DomainCreds

#>
Function Test-MRVCredentials
{
    param (
        [ValidateNotNullOrEmpty()]
        [Management.Automation.PSCredential]$DomainCreds = $(throw "Please Supply Credentials!")
    )
    Write-Host "Loading Quest.ActiveRoles.ADManagement..."
    If ((Import-MRVModule Quest.ActiveRoles.ArsPowerShellSnapIn).Result)
    {
        Write-Host "Loaded Quest.ActiveRoles.ADManagement Snaping" -ForegroundColor DarkGreen
    }
    else
    {
        Write-Host "Can't Load Quest.ActiveRoles.ADManagement SnapIn! Exiting....." -ForegroundColor DarkRed
        Write-Host "Please make sure that you have Installed all the modules"
        return $false
    }
    Write-Host "`n Validating local admin domain credentialss"
    $DomainObject = connect-QADService -Credential $DomainCreds
    If ($DomainObject.DefaultNamingContext -eq $null)
    {
        Write-Host "`n`tFailed local admin domain credential validation. Exiting...`n" -ForegroundColor Red
        $false
    }
    Else
    {
        Write-Host "`n`tSuccess" -ForegroundColor Green
        $true
    }
}