param(
    [switch]$Apply
)

$ErrorActionPreference = "Stop"
$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$ArchiveRoot = Join-Path $ProjectRoot ".planning\archive\legacy-doc-artifacts"

$legacyRoots = @(
    "docs\worklog\tasks",
    "docs\plans",
    "docs\superpowers"
)

$items = @()
foreach ($relativeRoot in $legacyRoots) {
    $root = Join-Path $ProjectRoot $relativeRoot
    if (-not (Test-Path $root)) {
        continue
    }
    Get-ChildItem $root -Recurse -File | ForEach-Object {
        $relativePath = Resolve-Path -Relative $_.FullName
        $items += [pscustomobject]@{
            Source = $relativePath.TrimStart(".", "\", "/")
            Target = (Join-Path $ArchiveRoot $relativePath.TrimStart(".", "\", "/"))
        }
    }
}

if ($items.Count -eq 0) {
    Write-Host "[ARCHIVE] no legacy doc artifacts found"
    exit 0
}

Write-Host "[ARCHIVE] legacy doc artifacts: $($items.Count)"
foreach ($item in $items) {
    Write-Host "[ARCHIVE] $($item.Source)"
}

if (-not $Apply) {
    Write-Host "[ARCHIVE] dry-run only; re-run with -Apply to move files into .planning\archive"
    exit 0
}

$resolvedArchive = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ArchiveRoot)
if (-not $resolvedArchive.StartsWith($ProjectRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Archive root is outside workspace: $resolvedArchive"
}

foreach ($item in $items) {
    $source = Join-Path $ProjectRoot $item.Source
    $target = $item.Target
    $targetDir = Split-Path $target -Parent
    New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
    Move-Item -LiteralPath $source -Destination $target
}

Write-Host "[ARCHIVE] moved legacy artifacts into $ArchiveRoot"
