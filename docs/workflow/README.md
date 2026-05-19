# Project Scaffold 工作流

本目录说明 project-scaffold 派生项目应如何使用 SCALE 工作流。目标是让 Agent 协作可验证、可审计、可恢复，而不是制造额外流程负担。

## 标准路径

```text
探索 -> 规划 -> 执行 -> 验证 -> 沉淀
```

| 阶段 | 产物 | 验证 |
| --- | --- | --- |
| 探索 | `explore.md`、`.agent/state/current.json` | G1 |
| 规划 | `plan.md`、必要时 `mini-prd.md` | G2 |
| 执行 | 代码、脚本、文档变更 | G3 可选 |
| 验证 | `verification.md`、命令输出摘要 | G4-G7 |
| 沉淀 | `summary.md`、metrics、长期文档更新 | final review |

## 任务目录

```text
.planning/tasks/<yyyy-mm-dd>-<task-slug>/
|-- explore.md
|-- mini-prd.md
|-- plan.md
|-- verification.md
|-- review.md
|-- summary.md
|-- artifact-manifest.json
`-- artifacts/
```

## 命令入口

```bash
make new-task NAME=example LEVEL=M
make explore FILES='AGENTS.md CLAUDE.md README.md' MSG='workflow adaptation'
make gate-workflow
make gate-quality
make verify PROFILE=scaffold
```

PowerShell：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/workflow/verify.ps1
```

## SCALE v0.21.2 扩展

```bash
make scale-mode TASK='修复权限校验' FILES='src/auth.ts,tests/auth.test.ts'
make scale-radar TASK='设计上传页面 UI' PHASE=plan LEVEL=M FILES='src/pages/upload.tsx'
make scale-context
make scale-codegraph
make scale-eval
make scale-dashboard
```

## 工作流升级

派生项目不需要依赖 Agent 手工复制工作流文件。优先使用仓库本地入口：

```bash
make workflow-upgrade-check
make workflow-upgrade-plan
make workflow-upgrade-apply
make workflow-upgrade-verify
```

如果本机没有 SCALE 或版本不一致，先运行 `make bootstrap-scale` 检查，使用 `make bootstrap-scale-install` 安装 locked 版本，或使用 `make bootstrap-scale-latest` 显式安装最新版。

`workflow-upgrade-check` 和 `workflow-upgrade-plan` 是默认入口；`workflow-upgrade-apply` 只能在检查计划后使用。遇到 `manual-review` 时保留本地项目语义，人工或 Agent 审阅差异后再处理。

Windows PowerShell：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/workflow/scale-smoke.ps1 -Task "修复权限校验" -Files "src/auth.ts,tests/auth.test.ts"
```

使用规则：

- S 级任务不强制完整工作流。
- 涉及 auth、permission、DB、migration、生产配置、部署、跨模块影响时，自动升级到 expanded 或 critical。
- Skill Radar 只给推荐和证据要求，不自动安装第三方工具。
- CodeGraph/Graphify 不可用时允许回退，但必须说明回退。
- HTML dashboard 是审阅视图，Markdown 和源代码仍是可维护事实来源。

## GitLab Flow 与工作树策略

脚手架默认生成 GitLab Flow 变体，并把当前仓库策略写入 `.scale/workspace.json`。

```text
feature/fix/docs/chore/codex -> dev -> main/master -> tag/package publish
```

规则：

- `dev` 是集成分支，只接收已验证变更，不在 `dev` 直接做 governed commit。
- `main` 或 `master` 是生产基线，只有用户明确要求发布或修复生产时才操作。
- `release/*` 只在 `dev` 已包含本次不发布内容时使用；它必须从生产基线拉出，再 cherry-pick 本次发布提交。
- `hotfix/*` 默认先在 `dev` 修复；紧急生产修复再 cherry-pick 到生产基线，打 tag 后同步回 `dev`。
- 工作树收口前运行 `scale workspace finish --dir .` 或同等检查，确认分支角色、未推送提交、未清理 worktree 和未记录验证项。

## 验证 profile

`.agent/project.json` 定义 service matrix 和 profiles。脚手架默认：

- `scaffold`：验证脚手架自身脚本。
- `default`：派生项目的默认服务集合。
- `all`：显式要求时才运行所有服务和安全检查。

派生项目应优先复用已有 `npm/pnpm/maven/go test` 等命令，不在门禁脚本里硬编码第二套业务验证。

## 资源治理

- 可长期维护：标准、模板、ADR、README、AGENTS、CLAUDE、CONTEXT。
- 可按任务提交：worklog、verification、review、summary。
- 默认不提交：截图、视频、coverage、playwright report、临时脚本、运行日志、生成 HTML。
- 需要保留的生成 HTML 必须能追溯到源 Markdown 或任务证据。
