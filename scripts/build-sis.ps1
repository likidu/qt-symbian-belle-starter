<#
.SYNOPSIS
    One-step Symbian build + self-signed SIS packaging for on-device testing.
.DESCRIPTION
    Runs build-symbian.ps1 then package-symbian.ps1 with the same parameters,
    producing build-symbian/<arch>-<config>/BelleApp_selfsigned.sis ready to
    transfer to the device. Stops if the build step fails.
.USAGE
    pwsh scripts/build-sis.ps1
    pwsh scripts/build-sis.ps1 -Config Release -Arch armv5 -Clean
    pwsh scripts/build-sis.ps1 -Force
.NOTES
    Thin wrapper: build-symbian.ps1 and package-symbian.ps1 remain usable on
    their own. Each step runs in its own PowerShell process so its exit does
    not tear down this wrapper before the exit code is captured.
#>
param(
    [ValidateNotNullOrEmpty()][string]$QtSdkRoot = 'C:\Symbian\QtSDK',
    [string]$SymbianSdkRoot,
    [ValidateSet('Debug','Release')][string]$Config = 'Debug',
    [ValidateSet('armv5','armv6')][string]$Arch = 'armv5',
    # forwarded to build-symbian.ps1
    [string]$QmakePath,
    [string]$MakePath,
    [switch]$Clean,
    [switch]$VerboseMake,
    # forwarded to package-symbian.ps1
    [string]$CertPath,
    [string]$KeyPath,
    [string]$CertPassword = 'belleapppass',
    [string]$PkgTemplatePath,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Info([string]$message) { Write-Host "[INFO] $message" -ForegroundColor Cyan }
function Write-Err([string]$message)  { Write-Host "[ERR ] $message" -ForegroundColor Red }

$buildParamNames = @('QtSdkRoot','SymbianSdkRoot','Config','Arch','QmakePath','MakePath','Clean','VerboseMake')
$packageParamNames = @('QtSdkRoot','SymbianSdkRoot','Config','Arch','CertPath','KeyPath','CertPassword','PkgTemplatePath','Force')

function Get-ForwardArgs([string[]]$names, $bound) {
    $list = @()
    foreach ($name in $names) {
        if (-not $bound.ContainsKey($name)) { continue }
        $value = $bound[$name]
        if ($value -is [System.Management.Automation.SwitchParameter]) {
            if ($value.IsPresent) { $list += "-$name" }
        } else {
            $list += "-$name"
            $list += [string]$value
        }
    }
    return ,$list
}

try {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $buildScript = Join-Path $scriptDir 'build-symbian.ps1'
    $packageScript = Join-Path $scriptDir 'package-symbian.ps1'
    foreach ($script in @($buildScript, $packageScript)) {
        if (-not (Test-Path -LiteralPath $script)) {
            throw ("Required script not found: {0}" -f $script)
        }
    }

    $psExe = (Get-Process -Id $PID).Path
    if (-not $psExe) { $psExe = (Get-Command pwsh -ErrorAction SilentlyContinue).Source }
    if (-not $psExe) { $psExe = (Get-Command powershell -ErrorAction SilentlyContinue).Source }
    if (-not $psExe) { throw 'Could not resolve the PowerShell executable to run the sub-steps.' }

    Write-Info "=== Step 1/2: build-symbian ($Config / $Arch) ==="
    $buildArgs = @('-NoProfile','-File', $buildScript) + (Get-ForwardArgs $buildParamNames $PSBoundParameters)
    & $psExe @buildArgs
    if ($LASTEXITCODE -ne 0) {
        throw ("Build step failed (exit {0}); skipping packaging." -f $LASTEXITCODE)
    }

    Write-Info "=== Step 2/2: package-symbian ($Config / $Arch) ==="
    $packageArgs = @('-NoProfile','-File', $packageScript) + (Get-ForwardArgs $packageParamNames $PSBoundParameters)
    & $psExe @packageArgs
    if ($LASTEXITCODE -ne 0) {
        throw ("Packaging step failed (exit {0})." -f $LASTEXITCODE)
    }

    $repoRoot = (Resolve-Path (Join-Path $scriptDir '..')).Path
    $finalSis = Join-Path $repoRoot ("build-symbian\{0}-{1}\BelleApp_selfsigned.sis" -f $Arch, $Config.ToLowerInvariant())
    Write-Host ""
    if (Test-Path -LiteralPath $finalSis) {
        Write-Info ("Done. Self-signed SIS ready: {0}" -f $finalSis)
        Write-Info "Transfer this .sis to the device and install."
    } else {
        Write-Info ("Done, but expected SIS not found at {0}; check the packaging output above." -f $finalSis)
    }
}
catch {
    Write-Err $_.Exception.Message
    exit 1
}
