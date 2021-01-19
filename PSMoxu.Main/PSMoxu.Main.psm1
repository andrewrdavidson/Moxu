function Start-MoxuServer {
    <#
        .SYNOPSIS
        Start the MoxuServer

        .DESCRIPTION
        Start the Moxu server

        .PARAMETER Name
        The name of the server to start

        .EXAMPLE
        Start-MoxuServer -Name "MoxuServer"
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([System.Void])]
    param (

        [parameter(Mandatory = $true)]
        [string]$Name
        # $ServerName
        # or
        # MoxuServer object from pipeline
    )

    Write-Verbose "Starting MoxuServer"

    $ServerName = $Name

    if ($PSCmdlet.ShouldProcess('Start MoxuServer', $ServerName)) {
        #Start Server
    }

}

function Stop-MoxuServer {
    <#
        .SYNOPSIS
        Stop the MoxuServer

        .DESCRIPTION
        Stop the Moxu server

        .EXAMPLE
        Stop-MoxuServer
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([System.Void])]
    param (
        # $ServerName
        # or
        # MoxuServer object from pipeline
    )

    Write-Verbose "Stopping MoxuServer"

    $ServerName = "Moxu"

    if ($PSCmdlet.ShouldProcess('Stop MoxuServer', $ServerName)) {
        #Stop Server
    }

}

function LoadMoxuSupportModules {
    <#
        .SYNOPSIS
        Invoke the PSQualityCheck tests

        .DESCRIPTION
        Invoke a series of Pester-based quality tests on the passed files

        .EXAMPLE
        Invoke-PSQualityCheck -Path 'C:\Scripts'

    #>
    [CmdletBinding()]
    [OutputType([System.Void])]
    param (
    )

    Import-Module -Name Ldbc -MinimumVersion 0.7.6
    Import-Module -Name PSSQLite -MinimumVersion 1.1.0
    Import-Module -Name Pode -MinimumVersion 2.0.3
    Import-Module -Name Pode.Kestrel -MinimumVersion 1.0.0
}

