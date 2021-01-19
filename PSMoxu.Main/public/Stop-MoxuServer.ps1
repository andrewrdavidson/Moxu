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
