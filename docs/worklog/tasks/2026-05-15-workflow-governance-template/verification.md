# verification - 2026-05-15-workflow-governance-template

Date: 2026-05-15
Level: M

## Commands / 命令

| Command | Result | Notes |
| --- | --- | --- |
| `bash scripts/gates/G1-verify.sh` | PASS | Exploration state has 10 files and a main contradiction |
| `bash scripts/gates/G2-verify.sh` | PASS | Plan has meaningful scope, boundary, acceptance, risks, rollback, verification |
| `bash scripts/workflow/verify.sh --list` | PASS | Listed `scaffold`, `default`, and `all` profiles |
| `bash scripts/workflow/verify.sh --profile scaffold` | PASS | Ran scaffold syntax check and gate dry-run |
| `bash scripts/gates/all.sh --workflow` | PASS | G1-G2 passed |
| `bash scripts/gates/all.sh --quality` | PASS | G3-G7 passed; stack-specific checks not applicable in scaffold root |
| `bash scripts/tests/run.sh` | PASS | 7 passed, 0 failed |
| `bash scripts/validate-config.sh` | PASS | Required files, JSON, executable scripts, and LF checks passed |
| `bash scripts/gates/all.sh --all` | PASS | Full G1-G7 chain passed |
| `git diff --check` | PASS | No whitespace errors |
| `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/workflow/verify.ps1` | PASS | PowerShell wrapper found Git Bash and ran scaffold profile |

## Failures / 失败项

- Initial `scripts/tests/run.sh` failed because tests still expected old dry-run output and did not use service matrix verification.
- Initial `validate-config.sh` failed because CRLF detection used Git Bash `grep` behavior incorrectly.
- Initial Go stack tests detected `none` because Windows `jq` emitted CRLF markers; `project-config.sh` now strips `\r`.

## Final Status / 最终状态

- PASS.
- Local `main` is ahead of `origin/main` by one commit (`25497ca 优化`).
