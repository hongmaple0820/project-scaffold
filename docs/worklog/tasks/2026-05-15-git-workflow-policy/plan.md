# plan - 2026-05-15-git-workflow-policy

Date: 2026-05-15
Level: M

## Scope / 范围

- 补充脚手架通用 Git 维护策略。
- 规范作者分支命名、dev 推送、master/main 保护、提交和部署流程。
- 同步入口文档，让 Agent 和开发者能在首页规则中看到关键限制。

## Boundary / 边界

- 不执行实际远程推送。
- 不操作 `master` / `main`。
- 不改变业务项目的实际 CI/CD 配置，只定义脚手架基线。

## Acceptance Criteria / 验收标准

- `docs/standards/common/GIT_STANDARDS.md` 写清分支命名格式和示例。
- 规范明确 `dev` 只有验证通过后才能推送或合并。
- 规范明确 `master` / `main` 不允许 Agent 自主操作。
- `AGENTS.md`、`CLAUDE.md`、`README.md`、`docs/workflow/README.md` 能链接或摘要 Git 策略。
- 相关文档通过 `git diff --check` 和脚手架验证命令。

## Risks / 风险

- 不同项目可能使用 `main` 而不是 `master`，规范需同时保护两者。
- 直接推 `origin/dev` 容易覆盖协作改动，规范需要求包含最新 `origin/dev`。

## Rollback / 回滚方案

- 回退本次 Git 规范和入口文档变更即可；不涉及数据迁移。

## Verification / 验证

- `bash scripts/gates/all.sh --workflow`
- `bash scripts/gates/all.sh --quality`
- `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/workflow/verify.ps1`
- `git diff --check`
