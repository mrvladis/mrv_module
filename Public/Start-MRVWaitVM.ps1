<#
 .Synopsis
 Function to verify required connectivity to the VM.
 .Description
 Function can be used to verify when TCP services become available (ready to accept connections)

  Prequisites
  -----------


  Returns
  -------
  As the result of function execution Hash Table will be provided.
  It will have the following format:
Name	Value
----	-----
Time	5
Result	True
Action	Connected

Where:
Time - time in seconds till connection has happend.
Result - Boolean $true or $false identifying if connection was sucessfull within the given time.
Action -  Text that may have value "Connected" or TimedOut

  Limitations and Known Issues
  ----------------------------
  See Backlog !

  Backlog
  --------
  Change Log
  ----------
  v1.00

 .Parameter AprxDur
 Approximate Duration of the proces to make progress bar moreuser friendly. Progress bar lenght  based on this value.
 .Parameter Wait_Activity
Description of the wait cativity that will be shown in the progress bar.
 .Parameter VMIPaddress
IP address or FQDN of the server we connecting to.
 .Parameter Port
Port we connecting to.
 .Parameter Maxdur
Maximum duration in seconds before function timeout. Default value is 300 seconds.
 .Example
Start-LBEDoWaitVM -AprxDur 150 -Wait_Activity "TestWait" -VMIPaddress '172.20.129.12' -Port 53
 .Example
Start-LBEDoWaitVM -AprxDur 150 -Wait_Activity "TestWait" -VMIPaddress '172.20.129.12' -Port 53 -Maxdur 250
#>
Function Start-MRVWaitVM
{
    param (

        [Parameter( Mandatory = $true)]
        [int] $AprxDur = $(throw "Please specify the amount of seconds to wait"),

        [Parameter( Mandatory = $true)]
        [string] $Wait_Activity = $(throw "The activity Description"),

        [Parameter( Mandatory = $true)]
        [string] $VMIPaddress = $(throw "Please specify the VM IP address"),

        [Parameter( Mandatory = $true)]
        [string] $Port = $(throw "Please specify the WinRM Port"),

        [Parameter( Mandatory = $false)]
        [int] $Maxdur = 300
    )
    $result = $true
    $sec = 0
    $Action = 'Connected'
    While (-not (Test-LBETCPPort -EndPoint  $VMIPaddress -Port $Port))
    {
        $sec += 1
        Start-Sleep -Seconds 1

        if ($sec -le $aprxdur - 1)
        {
            Write-Progress -Id 1 -Activity 'Waiting for VM to become available' -Status "Waiting for aproximatly $aprxdur seconds, $($aprxdur - $sec) left" -PercentComplete (($sec / $aprxdur) * 100)
        }
        else
        {
            Write-Progress -Id 1 -Activity 'Waiting for VM to become available' -Status "Taking longer then expected $aprxdur seconds, but taking $sec seconds" -PercentComplete 99
        }
        if ($Sec -eq $Maxdur)
        {
            $result = $false
            $Action = 'Timeout'
            break
        }
    }
    Write-Progress -Id 1 -Activity $wait_activity -Status "Completed. Continue..." -PercentComplete 100 -Completed
    $result = @{Result = $result; Time = $sec; Action = $action}
    return $result
}
