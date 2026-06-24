# project-scaffold

project-scaffold 是一套工程化治理工作流脚手架，用来把 SCALE Engine 的协作规则落到真实项目里。它不提供业务代码模板，而是提供一套可复制的项目治理基线：任务分级、探索记录、计划模板、验证 profile、门禁脚本、资源治理、Agent 协作规则和发布前证据检查。

使用它的目标不是增加流程负担，而是让人和 Agent 都能清楚回答四个问题：

1. 这次任务要解决什么问题？
2. 改动影响哪些文件、服务和文档？
3. 哪些验证真实运行过，哪些没有运行？
4. 哪些结论应该沉淀，哪些只是临时过程产物？

## 谁应该看什么

| 角色 | 先看 | 目的 |
| --- | --- | --- |
| 第一次接触的同事 | [docs/guides/GETTING_STARTED.md](docs/guides/GETTING_STARTED.md) | 15 分钟跑通一次最小工作流 |
| 日常开发者 | [docs/guides/DEVELOPMENT_WORKFLOW.md](docs/guides/DEVELOPMENT_WORKFLOW.md) | 按任务等级完成探索、计划、验证和提交 |
| Agent 或自动化工具 | [AGENTS.md](AGENTS.md) | 获取协作规则、红线和默认命令 |
| Claude Code | [CLAUDE.md](CLAUDE.md) | 获取 Claude 专用的最短入口 |
| 工作流维护者 | [docs/workflow/README.md](docs/workflow/README.md) | 维护脚本、门禁、验证 profile 和升级路径 |

## 一次任务怎么跑

M/L/CRITICAL 任务按这个闭环执行：

```text
探索 -> 规划 -> 执行 -> 验证 -> 沉淀
```

最小命令序列：

```bash
make preflight
make new-task NAME=feature-slug LEVEL=M
make explore FILES='AGENTS.md README.md docs/workflow/README.md' MSG='说明当前主要矛盾'
make gate-workflow
make verify PROFILE=scaffold
make resume
```

如果只是 typo、注释、小范围文档修正，可以按 S 级处理：读相关文件，做最小改动，运行相关验证，不强制创建完整任务目录。

## 什么时候升级治理强度

| 任务类型 | 建议等级 | 必做动作 |
| --- | --- | --- |
| typo、注释、小范围文档 | S | 最小验证，说明影响范围 |
| 脚本、文档结构、小功能、普通 bug | M | 创建任务目录，记录探索、计划和验证 |
| 跨模块、跨服务、架构、模板体系 | L | 完整计划、回滚方案、影响面验证 |
| 数据、权限、安全、生产配置、发布、破坏性操作 | CRITICAL | 人工确认、回滚方案、安全评审、完整验证 |

不知道该选哪一级时，先按 M 级处理。后续如果发现影响面扩大，再升级。

## 常用入口

基础工作流：

```bash
make preflight
make new-task NAME=task-slug LEVEL=M
make explore FILES='file1 file2' MSG='主要矛盾'
make gate-workflow
make gate-quality
make verify PROFILE=scaffold
make resume
```

SCALE 安装和升级：

```bash
make bootstrap-scale
make bootstrap-scale-install
make workflow-upgrade-check
make workflow-upgrade-plan
make workflow-upgrade-apply
make workflow-upgrade-verify
make workflow-aios-adopt
```

`workflow-upgrade-apply` 只能在审阅计划后使用。遇到 `manual-review` 时，不要覆盖本地项目语义。需要刷新 AI OS runtime 证据时运行 `make workflow-aios-adopt`。

SCALE 能力演示：

```bash
make scale-smoke TASK='为 Go 服务接入工作流' FILES='AGENTS.md,README.md'
make scale-mode TASK='修复登录权限校验' FILES='src/auth.ts,tests/auth.test.ts'
make scale-radar TASK='设计上传页面 UI' PHASE=plan LEVEL=M FILES='src/pages/upload.tsx'
make scale-dashboard
```

Windows PowerShell：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/workflow/scale-smoke.ps1 -Task "为 Go 服务接入工作流" -Files "AGENTS.md,README.md"
```

## 目录怎么理解

| 路径 | 职责 |
| --- | --- |
| `README.md` | 人类入口，说明这套工作流怎么学、怎么用 |
| `AGENTS.md` | Agent 通用协作规则和红线 |
| `CLAUDE.md` | Claude Code 兼容入口 |
| `CONTEXT.md` | 低 token 背景信息和禁止误解项 |
| `docs/guides/` | 新同事上手和日常开发说明 |
| `docs/workflow/` | 工作流脚本、门禁、升级和资源治理说明 |
| `docs/standards/` | 跨项目工程规范 |
| `.agent/project.json` | 服务矩阵和验证 profile |
| `.scale/` | SCALE 策略、评测基线和治理锁文件 |
| `scripts/workflow/` | new-task、explore、resume、verify 等命令 |
| `scripts/gates/` | G1-G7 门禁 |

## 提交前检查

提交前至少确认：

```bash
git status --short
git diff --check
make gate-workflow
make verify PROFILE=scaffold
```

不要使用 `git add .`。只 stage 本次任务相关文件，避免混入本地配置、临时报告、截图、日志、Agent worktree 或生成缓存。

## 什么能提交

可以提交：

- 稳定规则：`README.md`、`AGENTS.md`、`CLAUDE.md`、标准、ADR、可复用脚本。
- 任务证据：按任务需要提交的 `verification.md`、`review.md`、`summary.md`。
- 治理锁和明确要共享的配置：例如 `.scale/governance.lock.json`。

默认不提交：

- `.claude/worktrees/`、`.codex/tmp/`、`.cursor/tmp/` 等 Agent 本地状态。
- coverage、Playwright report、截图、视频、运行日志、生成 HTML。
- 一次性分析草稿和本地调试配置。

## 社区链接

| 平台 | 链接 | 说明 |
| --- | --- | --- |
| GitHub | [https://github.com/hongmaple0820/scale-engine](https://github.com/hongmaple0820/scale-engine) | SCALE Engine 源码、Issues、PR |
| Gitee | [https://gitee.com/hongmaple/scale-engine](https://gitee.com/hongmaple/scale-engine) | 国内镜像 |
| npm | [https://www.npmjs.com/package/@hongmaple0820/scale-engine](https://www.npmjs.com/package/@hongmaple0820/scale-engine) | CLI 包 |
