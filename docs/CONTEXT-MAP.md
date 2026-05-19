# CONTEXT-MAP.md

Project: project-scaffold

| Module | Owner | Product Doc | Architecture Doc |
| --- | --- | --- | --- |
| Agent entry docs | workflow maintainers | `AGENTS.md`, `CLAUDE.md` | `docs/workflow/README.md` |
| Workflow scripts | workflow maintainers | `README.md` | `scripts/workflow/` |
| Gate system | workflow maintainers | `docs/workflow/README.md` | `scripts/gates/` |
| Standards | governance maintainers | `docs/standards/README.md` | `docs/standards/common/` |
| SCALE v0.20 adapters | workflow maintainers | `README.md` | `.scale/code-intelligence.json`, `.scale/evals/` |

## Cross-Module Rules

- Changes to Makefile SCALE targets must update `README.md` and `docs/workflow/README.md`.
- Changes to service matrix behavior must update `.agent/project.json` and `docs/workflow/README.md`.
- Changes to long-term standards must update `docs/standards/README.md` and any affected common standard.
- Generated HTML dashboards are review outputs and should not replace source docs.
