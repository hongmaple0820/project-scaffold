# explore - 2026-05-15-workflow-governance-template

Date: 2026-05-15
Level: M

## Files Read / 已读文件

- AGENTS.md
- CLAUDE.md
- README.md
- docs/workflow/README.md
- docs/standards/common/GIT_STANDARDS.md
- docs/standards/common/DOCUMENT_STANDARDS.md
- scripts/lib/workflow_state.py
- scripts/gates/G2-verify.sh
- scripts/workflow/checkpoint.sh
- scripts/workflow/verify.ps1

## Current Behavior / 当前行为

- `new-task.sh` creates task artifacts and initializes `.agent/state/current.json`.
- Old `plan.sh` and `init-plan.sh` still pointed to `docs/plans`, while G2 reads `current.json.artifacts_dir`.
- `checkpoint.sh` rewrote `current.json` and could drop canonical fields.
- `verify.ps1` called bare `bash`, which can hit WSL bash on Windows.
- Documentation covered Git and docs governance, but not all rules were executable or consistently referenced.

## Main Contradiction / 主要矛盾

- Workflow contracts, Git collaboration, and docs governance are partially documented but not fully enforced by scripts and templates.

## Affected Modules / 影响模块

- Workflow scripts and gates.
- Agent entry docs.
- Git and document standards.
- Task artifact templates.
- Verification profile and service matrix config.

## Evidence / 证据

- `scripts/workflow/plan.sh` generated `docs/plans/...`, but `G2-verify.sh` reads `artifacts_dir/plan.md`.
- `scripts/workflow/checkpoint.sh` previously wrote a reduced JSON state.
- Default PATH exposed `C:\Windows\System32\bash.exe`, causing `verify.ps1` instability.
