Function Get-MRVRandomString
{
    param (
        [int]$Length
    )
    $set = "abcdefghijklmnopqrstuvwxyz0123456789".ToCharArray()
    $result = ""
    for ($x = 0; $x -lt $Length; $x++)
    {
        $result += $set | Get-Random
    }
    return $result
}
