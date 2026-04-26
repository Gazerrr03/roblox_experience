[CmdletBinding()]
param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..')).Path

Push-Location $repoRoot
try {
    function Build-Harness {
        param(
            [string]$ProjectPath,
            [string]$OutputPath
        )

        if ((Test-Path $OutputPath) -and -not $Force) {
            Write-Host "Skipping existing harness $OutputPath (pass -Force to rebuild from source scaffold)"
            return
        }

        rojo build $ProjectPath -o $OutputPath

        if ($OutputPath -eq 'places/maze/harness/maze.rbxlx') {
            python scripts/hydrate-maze-harness.py $OutputPath
        }
    }

    Build-Harness places/run/default.project.json places/run/harness/run.rbxlx
    Build-Harness places/maze/default.project.json places/maze/harness/maze.rbxlx
} finally {
    Pop-Location
}
