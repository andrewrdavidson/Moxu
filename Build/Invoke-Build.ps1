<#
    .SYNOPSIS
    Build the PSMoxu module and its sub-modules

    .DESCRIPTION
    Build the PSMoxu module and its sub-modules

    .EXAMPLE
    Invoke-Build.ps1 -BuildProperties "Build.Properties.json"
#>
[CmdletBinding()]
[OutputType([System.Void])]
param (
    [string]$BuildPropertiesFile = "Build.Properties.json",
    [string]$SourceFolder = "..\Source",
    [string]$OutputFolder = "~\OneDrive\Documents\PowerShell\Modules\PSMoxu"
)

# Build the Moxu modules
Write-Verbose "Loading Build Properties"
try {
    [PSCustomObject]$buildProperties = Get-Content -Path $BuildPropertiesFile | ConvertFrom-Json
}
catch {
    throw "Error loading the Build Properties file"
}

if ($null -eq $BuildProperties) {
    throw "Empty Build Properties file"
}

Write-Verbose "Build Properties: $($BuildProperties.PreRequisites)"
Write-Verbose "Build Properties: $($BuildProperties.Support)"
Write-Verbose "Build Properties: $($BuildProperties.Module)"
Write-Verbose "Build Properties: $($BuildProperties.ModuleData)"

# Check that the build pre-requisites are available
Write-Verbose "Verifying pre-requisites are available"

try {

    foreach ($preReq in $BuildProperties.PreRequisites.PSObject.Properties) {

        Import-Module -Name $preReq.Name -MinimumVersion $preReq.Value -Verbose:$false

        if ( -not (Get-Module -Name $preReq.Name -ListAvailable -Verbose:$false) ) {
            throw "Module '$($preReq.Name)' version '$($preReq.Value)' is not available"
        }
        else {
            Write-Verbose "Module '$($preReq.Name)' version '$($preReq.Value)' is available"
        }

    }

}
catch {

    throw

}

# Generate build location
# $builtModuleLocation = (Split-Path -Path $PSScriptRoot -Parent)
$builtModuleLocation = Join-Path -Path $OutputFolder -ChildPath $BuildProperties.ModuleData.ModuleVersion.("PSMoxu")
Write-Verbose "Build Location: $builtModuleLocation"

# remove the module root location if it exists
if (Test-Path -Path $OutputFolder) {
    Write-Verbose "Removing existing module file name"

    (Get-ChildItem $OutputFolder -Recurse -Force) |
        Sort-Object PSPath -Descending -Unique |
        Remove-Item -Recurse -Force

    Remove-Item -Path $OutputFolder -Force

}

New-Item -Path $OutputFolder -ItemType 'Directory'
New-Item -Path $builtModuleLocation -ItemType 'Directory'

$PSQualityCheckSplat = @{}
if (-not ([string]::IsNullOrEmpty($buildProperties.Support.PSQualityCheck.ScriptAnalyzerRulesPath))) {
    $PSQualityCheckSplat.Add("ScriptAnalyzerRulesPath", $BuildProperties.Support.PSQualityCheck.ScriptAnalyzerRulesPath )
    Write-Verbose "Adding ScriptAnalyzerRules: $($buildProperties.Support.PSQualityCheck.ScriptAnalyzerRulesPath)"
}

# Loop through the modules
foreach ($module in $BuildProperties.Module.Location.PSObject.Properties) {

    Write-Verbose "Building module : $($module.Name)"

    $moduleSourceFolder = Join-Path -Path $SourceFolder -ChildPath $module.Name

    Write-Verbose "Getting Public modules"
    $functionPublicPath = Join-Path -Path $moduleSourceFolder -ChildPath "public"
    $sourcePublicFiles = Get-ChildItem -Path $functionPublicPath -Recurse

    Write-Verbose "Getting Private modules"
    $functionPrivatePath = Join-Path -Path $moduleSourceFolder -ChildPath "private"
    $sourcePrivateFiles = Get-ChildItem -Path $functionPrivatePath -Recurse

    Write-Verbose "Generating module file name"
    $moduleName = "{0}{1}" -f $module.Name, '.psm1'
    $moduleFolder = Join-Path -Path $builtModuleLocation -ChildPath $module.Name
    $moduleFileName = Join-Path -Path $moduleFolder -ChildPath $moduleName

    # remove the module if it exists
    if (Test-Path -Path $moduleFolder) {
        Write-Verbose "Removing existing module file name"
        Remove-Item -Path $moduleFolder -Recurse -Force
    }

    New-Item -Path $moduleFolder -ItemType 'Directory'

    Write-Verbose "Generating manifest file name"
    $manifestName = "{0}{1}" -f $module.Name, '.psd1'
    $manifestFileName = Join-Path -Path (Join-Path -Path $builtModuleLocation -ChildPath $module.Name) -ChildPath $manifestName

    # remove the module if it exists
    if (Test-Path -Path $manifestFileName) {
        Write-Verbose "Removing existing manifest file name"
        Remove-Item -Path $manifestFileName -Force
    }

    # Run the Quality Checks
    Write-Verbose "Invoking PSQualityCheck"
    foreach ($function in $sourcePublicFiles) {

        Write-Verbose "Public function $($function.Name)"
        Invoke-PSQualityCheck -File $function.FullName @PSQualityCheckSplat

    }

    foreach ($function in $sourcePrivateFiles) {

        Write-Verbose "Private function $($function.Name)"
        Invoke-PSQualityCheck -File $function.FullName @PSQualityCheckSplat

    }

    # Run the Unit Tests
    Write-Verbose "Invoking Unit tests"
    foreach ($function in $sourcePublicFiles) {

        $script = "..\Tests\Unit\$($module.Name)\$($function.BaseName).Tests.ps1"
        Write-Verbose "Executing test $script"

        Invoke-Pester -Script $script

    }

    foreach ($function in $sourcePrivateFiles) {

        $script = "..\Tests\Unit\$($module.Name)\$($function.BaseName).Tests.ps1"
        Write-Verbose "Executing test $script"

        Invoke-Pester -Script $script

    }

    $functionsToExport = @()

    # Build up the module from public and private functions
    Write-Verbose "Generating Module"
    foreach ($function in $sourcePublicFiles) {

        Write-Verbose "Adding function $($function.Name)"
        Get-Content -Path $function.FullName | Add-Content -Path $moduleFileName

        $functionsToExport += $function.BaseName

        "" | Add-Content -Path $moduleFileName

    }

    foreach ($function in $sourcePrivateFiles) {

        Write-Verbose "Adding function $($function.Name)"
        Get-Content -Path $function.FullName | Add-Content -Path $moduleFileName

        "" | Add-Content -Path $moduleFileName

    }

    if (-not (Test-Path -Path $moduleFileName)) {
        continue
    }

    $binFolder = Join-Path -Path $moduleSourceFolder -ChildPath "bin"
    if (Test-Path -Path $binFolder) {
        Copy-Item -Path (Join-Path -Path $moduleSourceFolder -ChildPath "bin") -Destination $moduleFolder -Recurse
    }

    $newModuleManifest = @{
        Path = $manifestFileName
        Guid = $BuildProperties.ModuleData.Guid.($module.Name)
        RootModule = ("{0}{1}" -f $module.Name, '.psm1')

        ModuleVersion = $BuildProperties.ModuleData.ModuleVersion.($module.Name)
        PowerShellVersion = $BuildProperties.ModuleData.PowerShellVersion

        FunctionsToExport = $functionsToExport
        CmdletsToExport = @()
        VariablesToExport = @()
        AliasesToExport = @()

        Author = $BuildProperties.ModuleData.Author
        Company = $BuildProperties.ModuleData.Company
        Copyright = $BuildProperties.ModuleData.Copyright
        Description = $BuildProperties.ModuleData.Description.($module.Name)
        FileList = $BuildProperties.ModuleData.FileList.($module.Name)
        HelpInfoURI = $BuildProperties.ModuleData.HelpInfoURI
        LicenseUri = $BuildProperties.ModuleData.LicenseUri
        ProjectUri = $BuildProperties.ModuleData.ProjectUri
        Tags = $BuildProperties.ModuleData.Tags

        NestedModules = $BuildProperties.ModuleData.NestedModules.($module.Name)

    }

    try {
        Write-Verbose "Generating Manifest"
        $manifest = New-ModuleManifest @newModuleManifest
        Write-Verbose "Testing Manifest"
        $result = Test-ModuleManifest -Path $manifestFileName
        Write-Verbose "Pass"
    }
    catch {
        Write-Error "Fail"
    }

    $functionsToExport = $null

}

Write-Verbose "Generating Root Manifest"
$rootModule = "{0}{1}" -f $BuildProperties.Module.Root.PSObject.Properties.Name, '.psd1'
$rootModuleName = Join-Path -Path $builtModuleLocation -ChildPath $rootModule

# remove the module if it exists
if (Test-Path -Path $rootModuleName) {
    Remove-Item -Path $rootModuleName -Force
}

$newModuleManifest = @{
    Path = $rootModuleName
    Guid = $BuildProperties.ModuleData.Guid.($buildProperties.Module.Root.PSObject.Properties.Name)
    # RootModule = ("{0}{1}" -f $BuildProperties.Module.Root.PSObject.Properties.Name, '.psm1')

    ModuleVersion = $BuildProperties.ModuleData.ModuleVersion.($buildProperties.Module.Root.PSObject.Properties.Name)
    PowerShellVersion = $BuildProperties.ModuleData.PowerShellVersion

    FunctionsToExport = $functionsToExport
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()

    Author = $BuildProperties.ModuleData.Author
    Company = $BuildProperties.ModuleData.Company
    Copyright = $BuildProperties.ModuleData.Copyright
    Description = $BuildProperties.ModuleData.Description.($buildProperties.Module.Root.PSObject.Properties.Name)
    FileList = $BuildProperties.ModuleData.FileList.($buildProperties.Module.Root.PSObject.Properties.Name)
    HelpInfoURI = $BuildProperties.ModuleData.HelpInfoURI
    LicenseUri = $BuildProperties.ModuleData.LicenseUri
    ProjectUri = $BuildProperties.ModuleData.ProjectUri
    Tags = $BuildProperties.ModuleData.Tags

    NestedModules = $BuildProperties.ModuleData.NestedModules.($buildProperties.Module.Root.PSObject.Properties.Name)

}

New-ModuleManifest @newModuleManifest

Write-Verbose "Testing Root Manifest"
Test-ModuleManifest -Path $rootModuleName
