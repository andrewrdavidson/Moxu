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
    $BuildProperties = "Build.Properties.json"
)

# Build the Moxu modules
Write-Verbose "Loading Build Properties"
try {
    $buildProperties = Get-Content -Path $BuildProperties | ConvertFrom-Json
}
catch {
    throw "Error loading the Build Properties file"
}

# Check that the build pre-requisites are available
Write-Verbose "Verifying pre-requisites are available"

try {

    foreach ($preReq in $buildProperties.PreRequisites.PSObject.Properties) {

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
$builtModuleLocation = (Split-Path -Path $PSScriptRoot -Parent)
Write-Verbose "Build Location: $builtModuleLocation"

$PSQualityCheckSplat = @{}
if (-not ([string]::IsNullOrEmpty($buildProperties.Support.PSQualityCheck.SonarQubeRulesPath))) {
    $PSQualityCheckSplat.Add("SonarQubeRulesPath", $buildProperties.Support.PSQualityCheck.SonarQubeRulesPath)
}

# Loop through the modules
foreach ($module in $buildProperties.Module.Location.PSObject.Properties) {

    Write-Verbose "Building module : $($module.Name)"

    Write-Verbose "Getting Public modules"
    $functionPublicPath = Join-Path -Path (Join-Path -Path $builtModuleLocation -ChildPath $module.Name) -ChildPath "public"
    $sourcePublicFiles = Get-ChildItem -Path $functionPublicPath -Recurse

    Write-Verbose "Getting Private modules"
    $functionPrivatePath = Join-Path -Path (Join-Path -Path $builtModuleLocation -ChildPath $module.Name) -ChildPath "private"
    $sourcePrivateFiles = Get-ChildItem -Path $functionPrivatePath -Recurse

    Write-Verbose "Generating module file name"
    $moduleName = "{0}{1}" -f $module.Name, '.psm1'
    $moduleFileName = Join-Path -Path (Join-Path -Path $builtModuleLocation -ChildPath $module.Name) -ChildPath $moduleName

    # # remove the module if it exists
    if (Test-Path -Path $moduleFileName) {
        Write-Verbose "Removing existing module file name"
        Remove-Item -Path $moduleFileName -Force
    }

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

    $newModuleManifest = @{
        Path = $manifestFileName
        Guid = $buildProperties.ModuleData.Guid.($module.Name)
        RootModule = ("{0}{1}" -f $module.Name, '.psm1')

        ModuleVersion = $buildProperties.ModuleData.ModuleVersion.($module.Name)
        PowerShellVersion = $buildProperties.ModuleData.PowerShellVersion

        FunctionsToExport = $functionsToExport
        CmdletsToExport = @()
        VariablesToExport = @()
        AliasesToExport = @()

        Author = $buildProperties.ModuleData.Author
        Company = $buildProperties.ModuleData.Company
        Copyright = $buildProperties.ModuleData.Copyright
        Description = $buildProperties.ModuleData.Description.($module.Name)
        FileList = $buildProperties.ModuleData.FileList.($module.Name)
        HelpInfoURI = $buildProperties.ModuleData.HelpInfoURI
        LicenseUri = $buildProperties.ModuleData.LicenseUri
        ProjectUri = $buildProperties.ModuleData.ProjectUri
        Tags = $buildProperties.ModuleData.Tags

        NestedModules = $buildProperties.ModuleData.NestedModules.($module.Name)

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
$rootModule = "{0}{1}" -f $buildProperties.Module.Root.PSObject.Properties.Name, '.psd1'
$rootModuleName = Join-Path -Path $buildProperties.Module.Root.PSObject.Properties.Value -ChildPath $rootModule

# remove the module if it exists
if (Test-Path -Path $rootModuleName) {
    Remove-Item -Path $rootModuleName -Force
}

$newModuleManifest = @{
    Path = $rootModuleName
    Guid = $buildProperties.ModuleData.Guid.($buildProperties.Module.Root.PSObject.Properties.Name)
    # RootModule = ("{0}{1}" -f $buildProperties.Module.Root.PSObject.Properties.Name, '.psm1')

    ModuleVersion = $buildProperties.ModuleData.ModuleVersion.($buildProperties.Module.Root.PSObject.Properties.Name)
    PowerShellVersion = $buildProperties.ModuleData.PowerShellVersion

    FunctionsToExport = $functionsToExport
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()

    Author = $buildProperties.ModuleData.Author
    Company = $buildProperties.ModuleData.Company
    Copyright = $buildProperties.ModuleData.Copyright
    Description = $buildProperties.ModuleData.Description.($buildProperties.Module.Root.PSObject.Properties.Name)
    FileList = $buildProperties.ModuleData.FileList.($buildProperties.Module.Root.PSObject.Properties.Name)
    HelpInfoURI = $buildProperties.ModuleData.HelpInfoURI
    LicenseUri = $buildProperties.ModuleData.LicenseUri
    ProjectUri = $buildProperties.ModuleData.ProjectUri
    Tags = $buildProperties.ModuleData.Tags

    NestedModules = $buildProperties.ModuleData.NestedModules.($buildProperties.Module.Root.PSObject.Properties.Name)

}

New-ModuleManifest @newModuleManifest

Write-Verbose "Testing Root Manifest"
Test-ModuleManifest -Path $rootModuleName
