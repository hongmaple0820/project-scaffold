# mini-prd - 2026-05-15-workflow-governance-template

Date: 2026-05-15
Level: M

## Background / 背景

- This is governance workflow work, not a user-facing product feature.
- Mini-PRD is included to verify the generated task artifact structure.

## Target Users / 目标用户

- Human maintainers using generated projects.
- Agent platforms working in the same repository.

## Core Scenario / 核心场景

- A maintainer runs `scale init`, gets executable workflow governance, and can safely collaborate with agents.

## Non-Goals / 非目标

- No CI hardening in this slice.
- No business service-specific commands are hardcoded.

## User Path / 用户路径

- Create task.
- Explore files.
- Fill plan.
- Run gates and verification profile.
- Update docs and metrics.

## Permission Rules / 权限规则

- Agents cannot overwrite human-owned changes.
- Agents cannot operate `main` or `master` without explicit instruction.

## Data Impact / 数据影响

- No application data impact.
- Workflow state contract is preserved in `.agent/state/current.json`.

## Exception Scenarios / 异常场景

- Missing Git Bash on Windows should fail with a clear message.
- Empty plan templates must fail G2.
- M/L tasks missing artifacts must fail G6.

## Acceptance Criteria / 验收标准

- Workflow contract gates pass with real artifacts.
- Service/profile verification can list and run configured profiles.
- Git and document governance are discoverable from entry docs.
