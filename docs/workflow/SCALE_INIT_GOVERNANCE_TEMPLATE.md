# Scale Init Governance Template

本文件定义 `scale init` 生成项目时应落地的治理资产。目标是让新项目默认具备人类 + Agent 协作、任务产物、门禁、文档资产和验证 profile。

## Required Files

```text
AGENTS.md
CLAUDE.md
Makefile
.agent/project.json
docs/workflow/README.md
docs/workflow/templates/
docs/standards/common/GIT_STANDARDS.md
docs/standards/common/DOCUMENT_STANDARDS.md
docs/modules/README.md
docs/adr/README.md
docs/worklog/metrics.md
scripts/workflow/
scripts/gates/
scripts/lib/workflow_state.py
```

## Required Defaults

- `current.json` is the only authoritative workflow state.
- M/L/CRITICAL tasks use `.planning/tasks/<yyyy-mm-dd>-<task-slug>/`.
- `new-task.sh` creates all task artifacts from `docs/workflow/templates/`.
- `verify.sh` reads `.agent/project.json` profiles and services.
- `G2` rejects empty plan templates.
- `G6` validates metrics and M/L task artifact presence.

## Branch Naming

```text
<type>/<human-author>/<agent-platform>-<scope>-<task>-<MMDD>
```

Example:

```text
feature/maple/codex-workflow-governance-0515
```

## Project-Specific Setup

Generated projects must update `.agent/project.json`:

```json
{
  "profiles": {
    "default": {
      "services": ["api"],
      "checks": ["lint", "test", "build"]
    }
  },
  "services": {
    "api": {
      "path": "services/api",
      "stack": "go",
      "required": true
    }
  }
}
```

## Verification

```bash
bash scripts/workflow/verify.sh --list
bash scripts/workflow/verify.sh --profile scaffold
bash scripts/gates/all.sh --dry-run
```

For project services:

```bash
bash scripts/workflow/verify.sh --profile default
bash scripts/workflow/verify.sh --service api
```
