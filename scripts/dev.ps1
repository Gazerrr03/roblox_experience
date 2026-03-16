[CmdletBinding()]
param(
    [ValidateSet('run', 'lobby', 'maze')]
    [string]$Place = 'run',
    [int]$Port = 34872,
    [switch]$RefreshTools,
    [switch]$RefreshDeps
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..')).Path
$localToolDir = Join-Path $repoRoot '.aftman\bin'
$userToolDir = Join-Path $HOME '.aftman\bin'

function Write-Step {
    param([string]$Message)

    Write-Host ''
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Resolve-Executable {
    param(
        [string]$Name,
        [string[]]$Candidates = @()
    )

    foreach ($candidate in $Candidates) {
        if ($candidate -and (Test-Path $candidate)) {
            return (Resolve-Path $candidate).Path
        }
    }

    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    return $null
}

function Invoke-External {
    param(
        [string]$FilePath,
        [string[]]$Arguments,
        [string]$WorkingDirectory
    )

    Push-Location $WorkingDirectory
    try {
        Write-Host ("[{0}] {1} {2}" -f $WorkingDirectory, $FilePath, ($Arguments -join ' '))
        & $FilePath @Arguments
        if ($LASTEXITCODE -ne 0) {
            throw ("Command failed with exit code {0}: {1} {2}" -f $LASTEXITCODE, $FilePath, ($Arguments -join ' '))
        }
    } finally {
        Pop-Location
    }
}

function Test-DirectoryHasContent {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        return $false
    }

    return (Get-ChildItem -Force $Path | Measure-Object).Count -gt 0
}

$aftman = Resolve-Executable 'aftman' @(
    (Join-Path $localToolDir 'aftman.exe'),
    (Join-Path $userToolDir 'aftman.exe')
)

if (-not $aftman) {
    throw "Aftman is required but was not found.`n`nInstall it once, restart PowerShell, then rerun this script:`n  aftman self-install"
}

$rojoPath = Join-Path $localToolDir 'rojo.exe'
$wallyPath = Join-Path $localToolDir 'wally.exe'
$rojoUserPath = Join-Path $userToolDir 'rojo.exe'
$wallyUserPath = Join-Path $userToolDir 'wally.exe'

$rojo = Resolve-Executable 'rojo' @($rojoPath, $rojoUserPath)
$wally = Resolve-Executable 'wally' @($wallyPath, $wallyUserPath)
$toolsMissing = -not $rojo -or -not $wally

if ($RefreshTools -or $toolsMissing) {
    Write-Step 'Installing repo toolchain via Aftman'
    Invoke-External $aftman @('install') $repoRoot
    $rojo = Resolve-Executable 'rojo' @($rojoPath, $rojoUserPath)
    $wally = Resolve-Executable 'wally' @($wallyPath, $wallyUserPath)
} else {
    Write-Step 'Repo toolchain already present'
}

if (-not $rojo) {
    throw 'Rojo was not found after aftman install.'
}

if (-not $wally) {
    throw 'Wally was not found after aftman install.'
}

$devPackagesPath = Join-Path $repoRoot 'DevPackages'
if ($RefreshDeps -or -not (Test-DirectoryHasContent $devPackagesPath)) {
    Write-Step 'Installing Wally dependencies'
    Invoke-External $wally @('install') $repoRoot
} else {
    Write-Step 'Wally dependencies already present'
}

$projectRelativePath = switch ($Place) {
    'run' { 'places/run/default.project.json' }
    'lobby' { 'places/lobby/default.project.json' }
    'maze' { 'places/maze/default.project.json' }
    default { throw "Unsupported place: $Place" }
}

$projectPath = (Resolve-Path (Join-Path $repoRoot $projectRelativePath)).Path

Write-Step "Starting Rojo for $Place"
Write-Host "Place: $Place"
Write-Host "Project: $projectRelativePath"
Write-Host "Port: $Port"
Write-Host ''
Write-Host 'Studio steps:'
Write-Host '1. Open Roblox Studio and the Rojo plugin.'
Write-Host "2. Connect to localhost:$Port."
Write-Host '3. Sync, press Play, and enter the experience.'

if ($Place -eq 'run') {
    Write-Host '4. In the run start menu, click "Single Player" to launch the camp flow.'
}

Write-Step 'Rojo server is running'
Invoke-External $rojo @('serve', $projectPath, '--port', "$Port") $repoRoot
