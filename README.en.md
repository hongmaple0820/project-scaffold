# project-scaffold

Language: [中文](README.md) | English

project-scaffold is an engineering workflow scaffold for applying the SCALE Engine governance baseline to new projects: task levels, exploration records, plan/runtime/reality-check/resource-cleanup artifacts, service matrices, quality gates, agent collaboration rules, and pre-release evidence checks.

It is not an application starter template and does not bind a project to a specific language or framework. After adopting it, keep the shared workflow and adapt `.agent/project.json`, `.scale/verification.json`, and project documentation to the target language, services, configuration, and deployment model.

## Community And Distribution

| Platform | Link | Description |
| --- | --- | --- |
| Source repository | [GitHub: scale-engine](https://github.com/hongmaple0820/scale-engine) | SCALE Engine source, Issues, and PRs |
| China mirror | [Gitee: scale-engine](https://gitee.com/hongmaple/scale-engine) | Mirror for domestic access |
| npm | [@hongmaple0820/scale-engine](https://www.npmjs.com/package/@hongmaple0820/scale-engine) | CLI package distribution |

## Quick Start

```bash
make preflight
make new-task NAME=feature-slug LEVEL=M
make explore FILES='AGENTS.md CLAUDE.md README.md' MSG='workflow adaptation'
make gate-workflow
make verify PROFILE=scaffold
```

## SCALE v0.21.1 Entrypoints

```bash
make scale-smoke TASK='adopt workflow for a Go service' FILES='AGENTS.md,README.md'
make scale-mode TASK='fix login authorization check' FILES='src/auth.ts,tests/auth.test.ts'
make scale-radar TASK='design upload page UI' PHASE=plan LEVEL=M FILES='src/pages/upload.tsx'
make scale-dashboard
```

PowerShell:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/workflow/scale-smoke.ps1 -Task "adopt workflow for a Go service" -Files "AGENTS.md,README.md"
```

## Directory Responsibilities

| Path | Responsibility |
| --- | --- |
| `AGENTS.md` | Shared agent collaboration rules and red lines |
| `CLAUDE.md` | Claude Code compatible entrypoint |
| `CONTEXT.md` | Low-token domain vocabulary and anti-misunderstanding notes |
| `docs/CONTEXT-MAP.md` | Relationship between modules, docs, and update triggers |
| `.agent/project.json` | Service matrix, verification profiles, and language commands |
| `.scale/` | SCALE runtime policy, eval baselines, code intelligence config, and local evidence |
| `scripts/workflow/` | `new-task`, `explore`, `resume`, `verify`, and related workflow commands |
| `scripts/gates/` | G1-G7 gates |
| `docs/workflow/` | Workflow documentation |
| `docs/standards/` | Cross-project engineering standards |
| `.planning/tasks/` | Task-scoped planning, verification, and retrospective artifacts |

## Resource Governance

- Maintained long-term: `README`, `AGENTS`, `CLAUDE`, standards, ADRs, and reusable scripts.
- Task evidence: keep it under `.planning/tasks/<task>/`, including `runtime.md`, `reality-check.md`, and `resource-cleanup.md`.
- Temporary outputs: screenshots, videos, coverage, E2E reports, runtime logs, and one-off scripts are not committed by default.
- Final facts: promote durable conclusions to maintained docs and remove or ignore intermediate artifacts.

## Definition Of Done

An agent can claim completion only when:

- The change scope matches the user goal.
- Relevant verification commands actually ran, and failures are disclosed.
- Skipped checks, missing tools, or dry-runs are not described as passing.
- Documentation, service matrix, and workflow entrypoints do not contradict each other.
- The final response includes completed work, verification results, and remaining risk.
