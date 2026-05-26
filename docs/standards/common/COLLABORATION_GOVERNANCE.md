# Collaboration Governance Standard

**Version**: v1.0  
**Date**: 2026-05-14  
**Scope**: Human and agent collaboration across netdisk services  
**Applies to**: `amdox-go-netdisk`, `amdox-go-auth`, `amdox-go-gateway`, `amdox-netdisk-ui`, shared documentation and workflow assets

---

## 1. Purpose

This document is the governance entry point for collaboration across people, agents, Git, documentation, and the project knowledge base.

It exists to prevent five common failures:

1. Architecture and standards decisions stay in chat history instead of durable project files.
2. Human and agent work overlaps without ownership boundaries.
3. Pull requests contain code but omit verification and documentation evidence.
4. Knowledge is written once but not discoverable by future maintainers or agents.
5. Netdisk drifts from the Java platform standards without an explicit exception record.

## 2. Source of Truth

| Concern | Authoritative file |
| --- | --- |
| Platform standard baseline | `F:/project/amdox/java/docs/standards` |
| Netdisk standards entry | `docs/standards/README.md` |
| Java alignment and deviations | `docs/standards/projects/netdisk/JAVA_ALIGNMENT.md`, `docs/standards/projects/netdisk/EXCEPTIONS.md` |
| Agent workflow | `AGENTS.md`, `docs/workflow/README.md` |
| Git workflow | `docs/standards/common/GIT_STANDARDS.md` |
| Team collaboration | `docs/standards/common/TEAM_COLLABORATION.md` |
| Documentation rules | `docs/standards/common/DOCUMENT_STANDARDS.md` |
| Knowledge sync | `docs/knowledge/SYNC_RULES.md` |
| Task evidence | `.planning/tasks/<yyyy-mm-dd>-<task-slug>/` |

Rule precedence:

1. Security, data, production, and human confirmation rules.
2. Java platform standards.
3. Netdisk common standards.
4. Netdisk project-specific standards and recorded exceptions.
5. Local task plans and implementation notes.

## 3. Role Model

| Role | Responsibility | Final authority |
| --- | --- | --- |
| Product owner | Business scope, acceptance criteria, priority | Business acceptance |
| Architect | Cross-service design, standards, public layer boundaries | Architecture decisions |
| Technical owner | Code quality, implementation feasibility, release readiness | Module technical acceptance |
| Developer | Implementation, tests, local documentation updates | Assigned task delivery |
| Reviewer | Code review, risk review, standards conformance | PR approval |
| Test owner | Test scenarios, regression scope, verification evidence | Quality sign-off |
| Agent | Exploration, planning, implementation assistance, verification evidence | No final authority on CRITICAL changes |

Agents can propose decisions and execute approved work. Humans retain final authority for production, security, database, permission, secret, and public routing changes.

## 4. Task Classification

| Level | Examples | Required governance |
| --- | --- | --- |
| S | Typo, comment, small log-only change | Minimal local validation |
| M | Bug fix, new API within one service, 2-5 files | Explore, plan, implementation, verification summary |
| L | Cross-service work, architecture change, standards change | Written plan, human confirmation, staged execution, documentation update |
| CRITICAL | Auth, permission, database, migration, production config, secrets, destructive operations | Human confirmation, rollback plan, security review, full verification evidence |

Automatic upgrades:

- Any auth, permission, role, token, secret, database schema, gateway-public-route, production config, encryption, or irreversible filesystem action is at least CRITICAL.
- Any i18n/timezone protocol change affecting frontend and backend is at least L.
- Any standard that affects more than one service is at least L.

## 5. Human Collaboration Protocol

Human collaboration follows the existing team rules, with these governance additions:

1. Standards changes require architecture review.
2. API contract changes require frontend and backend review.
3. Database changes require rollback SQL and human confirmation before execution.
4. Production configuration and secret changes are discussed without putting real secret values in Git.
5. Technical disagreements escalate in this order: task thread, module owner, technical owner, architecture review.
6. Decisions that affect future work must be recorded in standards, architecture docs, ADR/decisions, or project worklog.

Async-first rule:

- Use PR comments for code-level issues.
- Use standards docs for durable rules.
- Use worklog for task execution evidence.
- Use decisions/ADR for architecture choices.
- Use chat only for coordination, not as the final storage location for project rules.

## 6. Agent Collaboration Protocol

Agents must follow these rules when working in the repository:

1. Read the relevant standards before changing code or docs.
2. Inspect current `git status` before editing.
3. Treat existing uncommitted changes as human-owned unless the user explicitly says otherwise.
4. Do not revert, delete, reformat, or overwrite unrelated human changes.
5. For M/L/CRITICAL tasks, record explored files, plan, verification commands, and residual risks.
6. Do not claim validation passed unless commands were actually run and outputs were checked.
7. Mark uncertainty with `[UNCERTAIN]` and state what evidence is missing.
8. Stop for human confirmation when a rule in Section 11 applies.

Agent output expectations:

- Explain which files are being changed before edits.
- Keep final reports focused on files changed, validation run, failures, and next steps.
- When verification cannot run, state the reason and provide the exact command that should be run later.

## 7. Multi-Agent Work Ownership

Parallel agents are allowed only when tasks are independent and file ownership is explicit.

Before dispatching multiple agents, the coordinator must define:

| Field | Required content |
| --- | --- |
| Task boundary | What the agent owns and what it must not touch |
| Write set | Exact files, directories, or modules the agent may edit |
| Read context | Files or docs the agent must inspect |
| Integration contract | Expected output, changed files, verification commands |
| Conflict rule | How to handle overlapping edits or new human changes |

Multi-agent rules:

- Two agents must not own the same file unless one is read-only.
- Agents must not revert another agent's changes.
- Shared docs, generated files, and API contracts need a coordinator-owned integration step.
- If an agent discovers the assigned write set is insufficient, it must report the blocker instead of editing outside the boundary.

## 8. Git and Pull Request Governance

Git workflow follows `GIT_STANDARDS.md` with these additions for agent-assisted work:

Branch naming:

| Work type | Branch pattern |
| --- | --- |
| Human feature | `feature/<short-description>` |
| Agent-assisted feature | `codex/<short-description>` or `feature/<short-description>` when a human owns the branch |
| Bug fix | `fix/<short-description>` |
| Critical fix | `hotfix/<short-description>` |

Commit and PR rules:

- Do not mix unrelated standards, business code, generated code, and formatting churn in one commit.
- Generated code changes must identify the generator command.
- PR descriptions must include changed scope, validation commands, known failures, documentation updates, and risk notes.
- CRITICAL PRs require at least one technical owner review and one security or architecture review when applicable.
Documentation updates are required when the change modifies durable knowledge.
- Documents must be UTF-8 Markdown.
- A standard must state scope, authority, and enforcement expectations.
- A plan must state boundary, risks, validation, and rollback when relevant.
- No production secrets, access tokens, passwords, private keys, or real credentials may be written into docs.
