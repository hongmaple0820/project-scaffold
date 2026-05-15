# summary - 2026-05-15-workflow-governance-template

Date: 2026-05-15
Level: M

## Delivered Changes / 交付内容

- Aligned WorkflowEngine artifacts and GateSystem expectations around `.agent/state/current.json`.
- Added task artifact templates, Mini-PRD template, stricter G2/G6 gates, and `verify.sh` profile/service matrix support.
- Stabilized Windows verification through `verify.ps1` Git Bash discovery.
- Added human + agent Git collaboration rules and modular documentation governance.
- Added `scale init` governance template documentation.

## Key Tradeoffs / 关键取舍

- Kept PowerShell wrapper for Windows users, but made Bash verification the canonical implementation.
- Kept old checkpoint/init scripts as compatibility wrappers instead of deleting every legacy entry.
- Did not add CI/hooks yet because local scripts needed to be trustworthy first.

## Verification Summary / 验证摘要

- Full G1-G7 gate passed.
- Scaffold self-tests passed: 7 passed, 0 failed.
- Config validation passed.
- PowerShell wrapper verification passed.

## Follow-ups / 后续事项

- Add CI/hook hardening after generated projects validate the local gates.
- Add project-specific service matrix examples for Go/Node/Python project templates.
- Decide whether historical `docs/WORKFLOW_OPTIMIZATION.md` should be archived or rewritten.

## Metrics Row / 指标行

```text
| 2026-05-15 | workflow-governance-template | M | workflow contract + git/docs governance + verification profile | No | 3 | Yes | Pass | CI/hooks and real project service customization remain future work |
```
