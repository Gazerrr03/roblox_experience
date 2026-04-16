[CmdletBinding()]
param(
    [ValidateSet('run', 'maze')]
    [string]$Place,
    [int]$Port = 34872
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if (-not $Place) {
    Write-Host 'Error: -Place is required. Usage: .\scripts\sync-and-serve.ps1 -Place run' -ForegroundColor Red
    Write-Host 'Supported places: run, maze' -ForegroundColor Yellow
    exit 1
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..')).Path

function Write-Step {
    param([string]$Message)
    Write-Host '' -ForegroundColor White
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

# Step 1: Git sync
$currentBranch = git branch --show-current
if (-not $currentBranch) {
    Write-Host '[WARNING] Detached HEAD detected — skipping git pull for this worktree.' -ForegroundColor Yellow
} else {
    $upstreamRef = git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>$null
    if ($LASTEXITCODE -eq 0 -and $upstreamRef) {
        Write-Step "Syncing current branch ($currentBranch)"
        git pull --ff-only
    } else {
        Write-Host "[WARNING] Branch '$currentBranch' has no upstream — skipping git pull." -ForegroundColor Yellow
    }
}

# Step 2: Print Feature Manifest
$featuresPath = switch ($Place) {
    'run'  { Join-Path $repoRoot 'places/run/FEATURES.md' }
    'maze' { Join-Path $repoRoot 'places/maze/FEATURES.md' }
}
if (Test-Path $featuresPath) {
    Write-Step "Feature Manifest ($Place)"
    Write-Host ''
    Get-Content $featuresPath
} else {
    Write-Host "[WARNING] $featuresPath not found — skip feature manifest" -ForegroundColor Yellow
}

# Step 3: Kill existing rojo serve process on target port only
Write-Step 'Stopping existing rojo serve processes'
if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) {
    $existingProcesses = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
    if ($existingProcesses) {
        $existingProcesses | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }
        Write-Host ("Rojo process on port $Port stopped.") -ForegroundColor Yellow
    } else {
        Write-Host 'No rojo process found on target port.' -ForegroundColor Green
    }
} else {
    Write-Host 'Rojo process management via port is Windows-only. Use Task Manager if needed.' -ForegroundColor Cyan
}
}

Start-Sleep -Seconds 2

# Step 4: Resolve rojo path (reuse $scriptDir/$repoRoot from Step 0)
$localToolDir = Join-Path $repoRoot '.aftman\bin'
$userToolDir = Join-Path $HOME '.aftman\bin'
$rojoPath = Join-Path $localToolDir 'rojo.exe'
$rojoUserPath = Join-Path $userToolDir 'rojo.exe'
$rojo = Resolve-Executable 'rojo' @($rojoPath, $rojoUserPath)
if (-not $rojo) {
    throw 'Rojo was not found. Run .\scripts\dev.ps1 -Place ' + $Place + ' first to install toolchain.'
}

# Step 5: Resolve project path
$projectRelativePath = switch ($Place) {
    'run' { 'places/run/default.project.json' }
    'maze' { 'places/maze/default.project.json' }
}
$projectPath = (Resolve-Path (Join-Path $repoRoot $projectRelativePath)).Path

Write-Step "Starting Rojo for $Place"
Write-Host "Place: $Place" -ForegroundColor White
Write-Host "Project: $projectRelativePath" -ForegroundColor White
Write-Host "Port: $Port" -ForegroundColor White
Write-Host ''
Write-Host 'Studio steps:' -ForegroundColor White
Write-Host '1. Open Roblox Studio and the Rojo plugin.' -ForegroundColor White
Write-Host "2. Connect to localhost:$Port." -ForegroundColor White
Write-Host '3. Sync, press Play, and enter the experience.' -ForegroundColor White

Invoke-External $rojo @('serve', $projectPath, '--port', "$Port") $repoRoot
