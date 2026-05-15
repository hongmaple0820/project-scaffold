# plan - 2026-05-15-workflow-governance-template

Date: 2026-05-15
Level: M

## Scope / 范围

- Align workflow state, task artifacts, gates, and verification entrypoints.
- Add reusable task templates, Mini-PRD template, metrics validation, and profile/service matrix verification.
- Strengthen human + agent Git collaboration rules and modular documentation governance.
- Document the governance set as a `scale init` template baseline.

## Boundary / 边界

- Do not add CI or hooks in this slice.
- Do not add business-project-specific service paths.
- Preserve existing user-created `docs/WORKFLOW_OPTIMIZATION_V2.md`.
- Do not reset or discard unrelated working tree changes.

## Required Skills / 专业能力

- [x] workflow automation
- [x] code review
- [x] documentation governance
- [ ] release review

## Acceptance Criteria / 验收标准

- `plan.sh` is removed or replaced by compatible `new-task` flow.
- `checkpoint.sh` preserves canonical `current.json` fields.
- `G2` fails empty template plans and passes meaningful plans.
- `verify.sh` supports `--list`, `--profile`, and `--service`.
- `verify.ps1` no longer calls ambiguous Windows `bash`.
- Git branch rules include human owner and agent platform.
- Documentation assets are organized by module, ADR, workflow, standards, and worklog.
- `scale init` governance baseline is documented.

## Risks / 风险

- Some historical worklog or optimization documents still mention older commands as historical records.
- Generated projects must still customize `.agent/project.json` for real services.
- Full CI parity remains future work.

## Rollback / 回滚方案

- Revert this governance patch to restore previous scripts and docs.
- Since no application data or production config is touched, rollback is limited to repository files.

## Verification / 验证

- Run scaffold profile verification.
- Run gate dry-run, workflow gate, quality gate, and scaffold tests.
- Run config validation and diff whitespace checks.
