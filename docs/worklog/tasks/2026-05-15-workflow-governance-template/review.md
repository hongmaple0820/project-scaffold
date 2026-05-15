# review - 2026-05-15-workflow-governance-template

Date: 2026-05-15
Level: M

## Code Review / 代码评审

- Workflow state contract is now centralized through `workflow_state.py`.
- `checkpoint.sh` and compatibility checkpoint wrappers no longer rewrite partial state JSON.
- `G2` now rejects plans that only contain template headings or placeholders.
- `verify.sh` provides a reusable profile/service matrix entrypoint.

## Security Review / 安全评审

- No secrets, credentials, production config, destructive commands, or data migrations were introduced.
- Git governance now explicitly blocks autonomous `main/master` operations and force-push/reset behavior without human confirmation.

## Same-Pattern Scan / 同类问题扫描

- Removed direct `plan.sh` workflow entry and converted `init-plan.sh` to a compatibility wrapper.
- Updated entry docs and guides away from `docs/plans` toward `docs/worklog/tasks`.
- Normalized CRLF validation to byte-level Python scanning for Windows/Git Bash reliability.

## Residual Risks / 剩余风险

- Historical worklog and optimization documents still mention old commands as historical evidence.
- Generated business projects must still fill `.agent/project.json.services` with real service paths.
- CI and hook hardening remain future phases.
