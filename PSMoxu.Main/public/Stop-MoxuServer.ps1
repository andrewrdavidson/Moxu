function Stop-MoxuServer {
    <#
        .SYNOPSIS
        Stop the MoxuServer

        .DESCRIPTION
        Stop the Moxu server

        .PARAMETER Name
        The name of the server to start

        .EXAMPLE
        Stop-MoxuServer -Name "MoxuServer"
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

    Write-Verbose "Stopping MoxuServer"

    if ($PSCmdlet.ShouldProcess('Stop MoxuServer', $Name)) {
        #Stop Server
    }

}
