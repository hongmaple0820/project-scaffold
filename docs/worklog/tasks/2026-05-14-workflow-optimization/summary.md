# Summary - 2026-05-14-workflow-optimization

Date: 2026-05-14
Level: M

## Delivered Changes

- Rewrote `AGENTS.md`, `CLAUDE.md`, `README.md`, `docs/workflow/README.md`, and `docs/standards/README.md` as a clean scaffold governance baseline.
- Removed stale and noisy instructions such as mandatory hidden reasoning output, hard `jq` dependency, outdated links, and duplicated workflow claims.
- Updated `new-task.sh` and `templates/plan/plan.md` so generated plans include Scope, Boundary, Acceptance Criteria, Risks, Rollback, and Verification sections.
- Fixed G2 to check real plan headings instead of mojibake patterns.
- Expanded G4 to syntax-check all workflow/gate shell scripts and the Python state helper.
- Updated G5 to run PowerShell self-check only when PowerShell is runnable from the current shell.
- Updated project config reading to use `jq` when available and Python fallback otherwise.

## Verification

All scaffold verification commands passed. Details are in `verification.md`.

## Follow-Ups

- When a real project is generated from this scaffold, update `.agent/project.json` to match that project's actual commands.
- Run language-specific G3-G7 gates in the generated project after its dependencies are installed.
