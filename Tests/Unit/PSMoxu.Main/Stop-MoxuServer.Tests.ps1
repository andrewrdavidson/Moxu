Describe "Stop-MoxuServer.Tests" {

    Context "Parameter Tests" -ForEach @(
        @{ 'Name' = 'Name'; 'Type' = 'String'; 'MandatoryFlag' = $true }
    ) {

        BeforeAll {
            $functionPath = Resolve-Path -Path "$PSScriptRoot\..\..\..\Source\PSMoxu.Main\public\Stop-MoxuServer.ps1"
            . $functionPath
            $commandletUnderTest = "Stop-MoxuServer"
        }

        It "should have $Name as a mandatory parameter" {

            (Get-Command -Name $commandletUnderTest).Parameters[$Name].Name | Should -BeExactly $Name
            (Get-Command -Name $commandletUnderTest).Parameters[$Name].Attributes.Mandatory | Should -BeExactly $MandatoryFlag

        }

        It "should $Name not belong to a parameter set" {

            (Get-Command -Name $commandletUnderTest).Parameters[$Name].ParameterSets.Keys | Should -Be '__AllParameterSets'

        }

        It "should $Name type be $Type" {

            (Get-Command -Name $commandletUnderTest).Parameters[$Name].ParameterType.Name | Should -Be $Type

        }

    }
}
