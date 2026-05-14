# summary - 2026-05-15-git-workflow-policy

Date: 2026-05-15
Level: M

## Notes

## Delivered Changes

- Rewrote `docs/standards/common/GIT_STANDARDS.md` as the canonical Git maintenance policy.
- Added author branch naming format: `<type>/<author>-<scope>-<task>-<MMDD>`.
- Added examples such as `feature/maple-platform-tool-user-tool-release-0515` and `feature/maple-lms-kercheng-0514`.
- Defined `dev` as the verified integration target.
- Defined `master` / `main` as protected branches that Agent cannot operate without explicit instruction.
- Documented how to push current verified HEAD to remote `dev` using `git push origin HEAD:dev`.
- Synced the Git policy summary into `AGENTS.md`, `CLAUDE.md`, `README.md`, and `docs/workflow/README.md`.

## Verification

- See `verification.md`.

## Residual Risk

- Actual deployment commands remain project-specific and must be supplied by each generated project.
