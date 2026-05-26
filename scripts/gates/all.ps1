param(
    [ValidateSet("all", "workflow", "quality")]
    [string]$Mode = "all",
    [string]$Service = "all",
    [switch]$IncludeUi,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..\..")

function Convert-ToBashPath([string]$Path) {
    $Full = (Resolve-Path $Path).Path
    if ($Full -match "^([A-Za-z]):\\(.*)$") {
        return "/mnt/$($Matches[1].ToLower())/$($Matches[2].Replace('\', '/'))"
    }
    return $Full.Replace("\", "/")
}

if ($DryRun) {
    $required = @(
        "scripts\gates\all.sh",
        "scripts\gates\G0-verify.sh",
        "scripts\gates\G1-verify.sh",
        "scripts\gates\G2-verify.sh",
        "scripts\gates\G3-verify.sh",
        "scripts\gates\G4-verify.sh",
        "scripts\gates\G5-verify.sh",
        "scripts\gates\G6-verify.sh",
        "scripts\gates\G7-verify.sh",
        "scripts\workflow\verify.ps1"
    )
    foreach ($file in $required) {
        $path = Join-Path $Root $file
        if (-not (Test-Path $path)) {
            Write-Host "[DRY-RUN] missing $file"
            exit 1
        }
        Write-Host "[DRY-RUN] $file"
    }
    exit 0
}

if ($Mode -eq "workflow" -or $Mode -eq "all") {
    $version = Join-Path $Root "scripts\version.ps1"
    & powershell -NoProfile -ExecutionPolicy Bypass -File $version check
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    $bash = Get-Command bash -ErrorAction SilentlyContinue
    if (-not $bash) {
        Write-Host "[GATE] Bash is required for workflow artifact gates on this repository."
        Write-Host "[GATE] Use Git Bash/WSL, or run PowerShell quality gate only: scripts\gates\all.ps1 -Mode quality"
        exit 1
    }
    $GateScript = Convert-ToBashPath (Join-Path $Root "scripts\gates\all.sh")
    & bash $GateScript --workflow
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

if ($Mode -eq "quality" -or $Mode -eq "all") {
    $verify = Join-Path $Root "scripts\workflow\verify.ps1"
    $args = @("-Service", $Service)
    if ($IncludeUi) { $args += "-IncludeUi" }
    & powershell -ExecutionPolicy Bypass -File $verify @args
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

Write-Host "[GATE] passed"
