function TESTF (
    [switch]$sw
)
{



    $VerbosePreference
    Write-Output "Runing in Verbose "
    $VerbosePreference = 'SilentlyContinue'


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

    $VerbosePreference = 'Continue'
}
