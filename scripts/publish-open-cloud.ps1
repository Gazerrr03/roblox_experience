param(
    [ValidateSet('all', 'lobby', 'run', 'maze')]
    [string]$Place = 'all',

    [string]$UniverseId = [Environment]::GetEnvironmentVariable('ROBLOX_UNIVERSE_ID', 'User')
)

$ErrorActionPreference = 'Stop'

$apiKey = [Environment]::GetEnvironmentVariable('ROBLOX_OPEN_CLOUD_API_KEY', 'User')

if ([string]::IsNullOrWhiteSpace($apiKey)) {
    throw 'Missing ROBLOX_OPEN_CLOUD_API_KEY in user environment.'
}

if ([string]::IsNullOrWhiteSpace($UniverseId)) {
    throw 'Missing ROBLOX_UNIVERSE_ID in user environment or -UniverseId argument.'
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$tmpDir = Join-Path $repoRoot 'tmp'

$placeConfigs = [ordered]@{
    lobby = @{
        PlaceId = '99207062749924'
        FilePath = Join-Path $tmpDir 'lobby.rbxlx'
    }
    run = @{
        PlaceId = '137478567439901'
        FilePath = Join-Path $tmpDir 'run.rbxlx'
    }
    maze = @{
        PlaceId = '114148445477110'
        FilePath = Join-Path $tmpDir 'maze.rbxlx'
    }
}

if ($Place -eq 'all') {
    $targets = @('lobby', 'run', 'maze')
} else {
    $targets = @($Place)
}

$headers = @{
    'x-api-key' = $apiKey
}

foreach ($target in $targets) {
    $config = $placeConfigs[$target]
    $filePath = $config.FilePath

    if (-not (Test-Path $filePath)) {
        throw "Missing build artifact for $target at $filePath"
    }

    $uri = "https://apis.roblox.com/universes/v1/$UniverseId/places/$($config.PlaceId)/versions?versionType=Published"

    Write-Host "Publishing $target -> place $($config.PlaceId)"
    $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -ContentType 'application/xml' -InFile $filePath
    $response | ConvertTo-Json -Compress | Write-Host
}
