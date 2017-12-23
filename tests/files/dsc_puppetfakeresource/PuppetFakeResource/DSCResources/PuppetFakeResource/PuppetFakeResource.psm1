function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $ImportantStuff,

        [parameter(Mandatory = $false)]
        [System.Boolean]
        $RequireReboot
    )

    #Write-Verbose "Use this cmdlet to deliver information about command processing."

    #Write-Debug "Use this cmdlet to write debug information while troubleshooting."


    <#
    $returnValue = @{
    Ensure = [System.String]
    ImportantStuff = [System.String]
    }

    $returnValue
    #>
    @{}
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [parameter(Mandatory = $true)]
        [System.String]
        $ImportantStuff,

        [parameter(Mandatory = $false)]
        [System.Boolean]
        $RequireReboot = $false
    )

    #Write-Verbose "Use this cmdlet to deliver information about command processing."

    #Write-Debug "Use this cmdlet to write debug information while troubleshooting."

    #Include this line if the resource requires a system reboot.
    if ($RequireReboot)
    {
        $global:DSCMachineStatus = 1
        Write-Verbose "We require reboot always!"
    }

    if ($Ensure -ieq 'Present')
    {
        $ImportantStuff | Out-File -FilePath c:\fakeresource.txt -Encoding ASCII -Force
    }
    else
    {
        Remove-Item -Path c:\fakeresource.txt -Force
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [parameter(Mandatory = $true)]
        [System.String]
        $ImportantStuff,

        [parameter(Mandatory = $false)]
        [System.Boolean]
        $RequireReboot
    )

    #Write-Verbose "Use this cmdlet to deliver information about command processing."

    #Write-Debug "Use this cmdlet to write debug information while troubleshooting."

    $exists = Test-Path -Path c:\fakeresource.txt -PathType leaf
    switch ($Ensure)
    {
        'Present'
        {
            if (!$exists) { return $false }
            return ((Get-Content c:\fakeresource.txt) -eq $ImportantStuff)
        }
        'Absent'
        {
            return !$exists
        }
    }

    <#
    $result = [System.Boolean]

    $result
    #>
    return $false
}


Export-ModuleMember -Function *-TargetResource
