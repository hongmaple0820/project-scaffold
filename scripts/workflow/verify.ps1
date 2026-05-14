param([ValidateSet('all','workflow')][string]$Target='all')
$ErrorActionPreference = 'Stop'
$Root = Resolve-Path (Join-Path $PSScriptRoot '..\..')
Push-Location $Root
try {
  Write-Host '== scaffold workflow =='
  bash scripts/gates/all.sh --dry-run
  bash -n scripts/gates/all.sh scripts/workflow/new-task.sh scripts/workflow/explore.sh scripts/workflow/resume.sh
  python3 -m py_compile scripts/lib/workflow_state.py
  Write-Host 'scaffold verification passed'
} finally {
  Pop-Location
}
