<#
.SYNOPSIS
    Personalizes the Belle starter template into a new app: renames BelleApp ->
    your app name and rewrites the Symbian UID.
.USAGE
    pwsh scripts/init-project.ps1 -AppName "MyApp" -Uid 0xE1234567
.NOTES
    Run once, from the repo root, on a fresh clone. Commit the result.
#>
param(
    [Parameter(Mandatory = $true)][ValidatePattern('^[A-Za-z][A-Za-z0-9]*$')][string]$AppName,
    [Parameter(Mandatory = $true)][ValidatePattern('^0x[0-9A-Fa-f]{8}$')][string]$Uid
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Info([string]$m) { Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Write-Warn([string]$m) { Write-Host "[WARN] $m" -ForegroundColor Yellow }

$repoRoot = (Resolve-Path (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) '..')).Path
Set-Location $repoRoot

$nameLower = $AppName.ToLowerInvariant()
$uidNoPrefix = $Uid.Substring(2).ToLowerInvariant()   # 8 hex chars, e.g. e1234567

Write-Info "App name : $AppName  (lower: $nameLower)"
Write-Info "UID      : $Uid  (folder: $uidNoPrefix)"

# Files to rewrite (text). Exclude binaries, git, build output, this script.
$textFiles = Get-ChildItem -Recurse -File |
    Where-Object {
        $_.FullName -notmatch '\\\.git\\' -and
        $_.FullName -notmatch '\\build-(simulator|symbian)\\' -and
        $_.Name -ne 'init-project.ps1' -and
        $_.Extension -notin @('.wav', '.png', '.jpg', '.sis', '.exe', '.dll')
    }

foreach ($f in $textFiles) {
    $c = Get-Content -Raw -LiteralPath $f.FullName
    if ($null -eq $c) { continue }   # empty file (e.g. data/.placeholder)
    $orig = $c
    $c = $c.Replace('e1000001', $uidNoPrefix)   # private-dir folder name
    $c = $c.Replace('0xE1000001', $Uid)         # pkg/pro UID literal
    $c = $c.Replace('0xe1000001', $Uid)
    $c = $c.Replace('BELLEAPP', $AppName.ToUpperInvariant())  # macro: BELLEAPP_DEBUG
    $c = $c.Replace('BelleApp', $AppName)       # PascalCase identifiers, filenames, TARGET
    $c = $c.Replace('belleapp', $nameLower)     # db file, connection name, home fallback, cert/pass
    if ($c -ne $orig) {
        Set-Content -LiteralPath $f.FullName -Value $c -Encoding UTF8
        Write-Info "patched: $($f.FullName.Substring($repoRoot.Length + 1))"
    }
}

# Rename files whose names contain BelleApp.
$toRename = Get-ChildItem -Recurse -File | Where-Object { $_.Name -like '*BelleApp*' }
foreach ($f in $toRename) {
    $new = $f.Name.Replace('BelleApp', $AppName)
    Rename-Item -LiteralPath $f.FullName -NewName $new
    Write-Info "renamed : $($f.Name) -> $new"
}

Write-Host ""
Write-Info "Done. Manual follow-ups:"
Write-Warn " - Review LICENSE / About-dialog copyright if you are not the author."
Write-Warn " - Verify the UID $Uid is in your self-signed range (0xE0000000-0xEFFFFFFF) or your registered range."
Write-Warn " - Delete docs/superpowers/ if you don't want the template's design history."
Write-Warn " - Rebuild: pwsh scripts/build-simulator.ps1 -Config Debug -Clean"
