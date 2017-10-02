# Implement your module commands in this script.
Write-Verbose "Populating list of Public Functions"
$Public = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
Write-Verbose "Populating list of Private Functions"
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )

#Dot source the files
Write-Verbose "Loading Functions into memory"
Foreach ($Import in @($Public + $Private))
{
    Try
    {
        #Write-Host "Loading Function [$($import.fullname)]"
        . $Import.FullName
    }
    Catch
    {
        Write-Error -Message "Failed to import function $($Import.FullName): $_"
    }
}
# Export only the functions using PowerShell standard verb-noun naming.
# Be sure to list each exported functions in the FunctionsToExport field of the module manifest file.
# This improves performance of command discovery in PowerShell.
Write-Verbose "Exporting Functions....."
Export-ModuleMember -Function $Public.BaseName

