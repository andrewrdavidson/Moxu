function InstallMoxuSupportLibraries {
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

    Install-Module -Name Ldbc
    Install-Module -Name PSSQLite
    Install-Module -Name Pode
    Install-Module -Name Pode.Kestrel
}
