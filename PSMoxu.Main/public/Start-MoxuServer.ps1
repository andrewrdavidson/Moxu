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
