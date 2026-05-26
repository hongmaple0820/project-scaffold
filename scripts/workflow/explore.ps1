$ErrorActionPreference = "Stop"

$Root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$Bash = Get-Command bash -ErrorAction SilentlyContinue
if (-not $Bash) {
    Write-Host "Bash is required for workflow exploration recording. Use Git Bash/WSL or run scripts\workflow\explore.sh there."
    exit 1
}

& bash (Join-Path $Root "scripts\workflow\explore.sh") @args
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
