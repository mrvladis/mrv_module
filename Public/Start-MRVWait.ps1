<#
 .Synopsis
 Function to wait specified amount of time, providing a description of the wait activity.
 .Description
 Function to wait specified amount of time, providing a description of the wait activity.

  Prequisites
  -----------


  Returns
  -------
$null

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

 .Example
Start-MRVWait -AprxDur 150 -Wait_Activity "TestWait for 150 seconds"
#>
Function Start-MRVWait
{
    param (
        [Parameter( Mandatory = $true)]
        [int] $AprxDur = $(throw "Please specify the amount of seconds to wait"),

        [Parameter( Mandatory = $true)]
        [string] $Wait_Activity = $(throw "The activity Description")
    )

    $sec = 0
    $wait_status = "Time to wait: $aprxdur seconds. Currently $($aprxdur - $sec) left"
    Write-Progress -Id 1 -Activity $wait_activity -Status $wait_status -PercentComplete (($sec / $aprxdur) * 100)
    while ($sec -lt $aprxdur)
    {
        $sec += 1
        $wait_status = "Time to wait: $aprxdur seconds. Currently $($aprxdur - $sec) left"
        Start-Sleep -Seconds 1
        Write-Progress -Id 1 -Activity $wait_activity -Status $wait_status -PercentComplete (($sec / $aprxdur) * 100)
    }
    Write-Progress -Id 1 -Activity $wait_activity -Status "Completed. Continue..." -PercentComplete 100 -Completed
}
