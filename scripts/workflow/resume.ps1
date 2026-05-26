$ErrorActionPreference = "Stop"

$Root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$Bash = Get-Command bash -ErrorAction SilentlyContinue
if (-not $Bash) {
    Write-Host "Bash is required for workflow state rendering. Use Git Bash/WSL or run scripts\workflow\resume.sh there."
    exit 1
}

function Convert-ToBashPath([string]$Path) {
    $Full = (Resolve-Path $Path).Path
    if ($Full -match "^([A-Za-z]):\\(.*)$") {
        return "/mnt/$($Matches[1].ToLower())/$($Matches[2].Replace('\', '/'))"
    }
    return $Full.Replace("\", "/")
}

$Script = Convert-ToBashPath (Join-Path $Root "scripts\workflow\resume.sh")
& bash $Script @args
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
