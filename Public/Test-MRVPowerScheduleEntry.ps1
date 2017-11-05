# Define function to check current time against specified range
function Test-MRVPowerScheduleEntry
{
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $TimeRange,
        [Parameter(Mandatory = $false)]
        [switch]
        $Patching
    )
    # Initialize variables
    $rangeStart, $rangeEnd, $parsedDay = $null
    $UTCTime = (Get-Date).ToUniversalTime()
    $oToTimeZone = [System.TimeZoneInfo]::FindSystemTimeZoneById("GMT Standard Time")
    $currentTime = [System.TimeZoneInfo]::ConvertTime($UTCTime, $oToTimeZone)
    $midnight = $currentTime.AddDays(1).Date
    try
    {
        # Parse as range if contains '->'
        if ($TimeRange -like "*->*")
        {
            $timeRangeComponents = $TimeRange -split "->" | ForEach-Object {$_.Trim()}
            If ($timeRangeComponents[0] -eq "")
            {
                $timeRangeComponents[0] = "00:00"
            }
            If ($timeRangeComponents[1] -eq "")
            {
                $timeRangeComponents[1] = "23:59"
            }
            if ($timeRangeComponents.Count -eq 2)
            {
                $rangeStart = Get-Date $timeRangeComponents[0]
                $rangeEnd = Get-Date $timeRangeComponents[1]
                # Check for crossing midnight
                if ($rangeStart -gt $rangeEnd)
                {
                    # If current time is between the start of range and midnight tonight, interpret start time as earlier today and end time as tomorrow
                    if ($currentTime -ge $rangeStart -and $currentTime -lt $midnight)
                    {
                        if ($Patching)
                        {
                            Write-Verbose "Skipping Date adjust as schedule is for patching."
                        }
                        else
                        {
                            $rangeEnd = $rangeEnd.AddDays(1)
                        }
                    }
                    # Otherwise interpret start time as yesterday and end time as today
                    else
                    {
                        $rangeStart = $rangeStart.AddDays(-1)
                    }
                }
            }
            else
            {
                Write-Verbose "`tWARNING: Invalid time range format. Expects valid .Net DateTime-formatted start time and end time separated by '->'"
            }
        }
        # Otherwise attempt to parse as a full day entry, e.g. 'Monday' or 'December 25'
        else
        {
            Write-Verbose "Can't find any schedule for today! Looks like Vm needs to be stopped."
            return $false
        }
    }
    catch
    {
        # Record any errors and return false by default
        Write-Verbose "`tWARNING: Exception encountered while parsing time range. Details: $($_.Exception.Message). Check the syntax of entry, e.g. '<StartTime> -> <EndTime>', or days/dates like 'Sunday' and 'December 25'"
        return $false
    }
    if ($currentTime -ge $rangeStart -and $currentTime -le $rangeEnd)
    {
        return $true
    }
    else
    {
        return $false
    }

}

