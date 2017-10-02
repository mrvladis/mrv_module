<#
.Synopsis
Script that can be used to validate connectivoty to specific port.
.Description
Script that can be used to validate if specific port is available for connection on specified IP address.


	Limitations
	----------


	Change Log
	----------
	v.1.0.0.0		- Initial Version

	Backlog
	--------

	Output
	--------
  As the result of function execution Hash Table returned. This can be ammended.
  It will have the following format:
    Name	            Value
    ----	            -----
    Result	            True / False
    Error               $error


Syntax: Function has the following parameters:
.Parameter EndPoint
IP Address or FQDN to connect to.

 .Parameter Port
Port to verify connectivity to.

 .Parameter TimeOut
Amount of time in ms to wait for before concider timeout.

 .Example
 	Test-MRVTCPPort 192.168.127.1 80
 .Example
	Test-MRVTCPPort -EndPoint 192.168.127.1 -Port 80
 .Example
	Test-MRVTCPPort -EndPoint 192.168.127.1 -Port 80 -TimeOut 900

#>
Function Test-MRVTCPPort
{
    param ( [ValidateNotNullOrEmpty()]
        [string]
        $EndPoint = $(throw "Please specify an EndPoint (Host or IP Address)"),
        [int]
        $Port = $(throw "Please specify a Port"),
        [int]
        $TimeOut = 900
    )
    $Connected = $false

    $IP = [System.Net.Dns]::GetHostAddresses($EndPoint)
    $Address = [System.Net.IPAddress]::Parse($IP)
    $Socket = New-Object System.Net.Sockets.TCPClient
    $Connect = $Socket.BeginConnect($Address, $Port, $null, $null)
    sleep 1
    if ( $Connect.IsCompleted )
    {
        $Wait = $Connect.AsyncWaitHandle.WaitOne($TimeOut, $false)
        if (!$Wait)
        {
            $Socket.Close()
        }
        else
        {
            try
            {
                $Socket.EndConnect($Connect)
                $Socket.Close()
            }
            catch
            {
                $Connected = $false
            }
            $Connected = $true
        }
    }
    $result = @{Result = $Connected; Error = $Error; }
    return $result
}