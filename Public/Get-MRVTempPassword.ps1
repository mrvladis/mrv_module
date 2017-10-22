Function Get-MRVTempPassword
{
    Param(
        [int]
        $length = 10
    )
    $ascii = $NULL; For ($a = 33; $a –le 126; $a++) {$ascii += , [char][byte]$a }
    For ($loop = 1; $loop –le $length; $loop++)
    {
        $TempPassword += ($ascii | GET-RANDOM)
    }
    return $TempPassword
}

