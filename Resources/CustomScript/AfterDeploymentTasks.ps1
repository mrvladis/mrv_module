$blnFullDNSRegistrationEnabled = $true
$blnDomainDNSRegistrationEnabled = $true
$start_time = Get-Date
$RootFolder = "C:\"
$ScriptFolder = "Temp"
$EnGbDefaultFile = "$($RootFolder + $ScriptFolder)\en-gb-default.reg"
$EnGbWelcomeFile = "$($RootFolder + $ScriptFolder)\en-gb-welcome.reg"
If ( -not ($($RootFolder + $ScriptFolder)))
{
    New-Item -Path $RootFolder -Name $ScriptFolder -Force
}
###Enabling WINRM HTTPS
Write-Host "Creating the Certificate and Enabling HTTPS for WinRM."
Write-Host "Getting the host name"
$HostName = [System.Net.Dns]::GetHostName()
Write-Host "Creating the Certificate"
$Cert = New-SelfSignedCertificate -certstorelocation cert:localmachine\my -dnsname $hostname -NotAfter (Get-Date).AddMonths(60)
Write-Host "Enabling HTTPS for WinRM."
winrm create winrm/config/listener?Address=*+Transport=HTTPS "@{Hostname=""$hostName"";CertificateThumbprint=""$($Cert.Thumbprint)"";port=""5986""}"
Write-Host "Enabling FireWall rule"
New-NetFirewallRule -Name WinRM-Https-In -DisplayName "Windows Remote Management (HTTPs-In)" -Direction Inbound �LocalPort 5986 -Protocol TCP -Action Allow
#####Moving any DVD from E....
Write-Host "Moving CD / DVD from Drive E if any..."
$LastDriveLetter = "O"
Get-WmiObject win32_logicaldisk -filter 'DriveType=5' | Sort-Object -property DeviceID -Descending | ForEach-Object {
    Write-Host "Found CD-ROM drive on $($_.DeviceID)"
    $A = mountvol $_.DeviceID /l
    $UseDriveLetter = Get-ChildItem function:[d-$LastDriveLetter]: -Name | Where-Object { (New-Object System.IO.DriveInfo($_)).DriveType -eq 'NoRootDirectory' } | Sort-Object -Descending | Select-Object -First 1
    If ($UseDriveLetter -ne $null -AND $UseDriveLetter -ne "")
    {
        write-host "$UseDriveLetter is available to use"
        write-host "Changing $($_.DeviceID) to $UseDriveLetter"
        mountvol $_.DeviceID /d
        $a = $a.Trim()
        mountvol $UseDriveLetter $a
    }
    else
    {
        write-host "No available drive letters found."
    }
}
Start-Sleep 5
Get-Disk | where-object {($_.PartitionStyle -like "RAW")} | Initialize-Disk -PassThru -PartitionStyle GPT | New-Partition -AssignDriveLetter -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel "Data" -Force -Confirm:$false
Write-Host "Setting Time zone to GMT Standard Time"
tzutil /s "GMT Standard Time"
diskperf -Y
$NICs = Get-WMIobject -query "SELECT * FROM Win32_NetworkAdapterConfiguration WHERE IPEnabled = True"
ForEach ($NIC in $NICs)
{
    $NIC.SetDynamicDNSRegistration($blnFullDNSRegistrationEnabled, $blnDomainDNSRegistrationEnabled)
    $Nic.SetDNSDomain($DomainFQDN)
}
Write-Host "Going to install WFC5"
Write-Host "Checking if the $ScriptFolder exist"
If (-not (Test-Path $($RootFolder + $ScriptFolder)))
{
    Write-Host "Folder for Scripts does not exit. Going to try to create it."
    If (New-Item -ItemType Directory -Name $ScriptFolder -Path $RootFolder )
    {
        Write-Host "Folder $ScriptFolder has been created."
    }
    else
    {
        Write-Host "Can't create a folder $ScriptFolder in $RootFolder " -ForegroundColor Red
        return
    }
}
else
{
    Write-host "Folder already there"
}
Write-Host "Downloading RegFile 1"
Invoke-WebRequest -Uri $EnGbDefaulturl -OutFile $EnGbDefaultFile
Write-Host "Downloading RegFile 2"
Invoke-WebRequest -Uri $EnGbWelcomeurl -OutFile $EnGbWelcomeFile
$DefaultHKEY = "HKU\DEFAULT_USER"
$DefaultRegPath = "C:\Users\Default\NTUSER.DAT"
Set-Culture en-GB
Set-WinSystemLocale en-GB
Set-WinHomeLocation -GeoId 242
Set-WinUserLanguageList en-GB -Force
Write-Host "Loading registry keys: [$DefaultHKEY] and [$DefaultRegPath]"
$RegStatus = reg load $DefaultHKEY $DefaultRegPath
Write-Host "Importing en-gb-default.reg"
$RegStatus += reg import $EnGbDefaultFile
Write-Host "Unloading [$DefaultHKEY]"
$RegStatus += reg unload $DefaultHKEY
Write-Host "Importing en-gb-welcome.reg"
$RegStatus += reg import $EnGbWelcomeFile
Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
Write-Host "Execution completed"

