# Project Scaffold 工作流治理

本仓库是工程化工作流实践脚手架，负责沉淀可复制到业务项目的通用治理模板。脚手架只维护通用机制，业务项目差异放在各自的 `.scale/verification.json`、`.scale/resource-policy.json` 和项目文档中。

## 适用边界

- 通用流程：任务分级、探索、计划、执行、验证、评审、沉淀。
- 通用产物：Mini-PRD、计划、验证、Review、Summary、HTML artifact。
- 通用工具治理：skills、MCP、浏览器、桌面自动化、外部 CLI 的证据记录。
- 不在脚手架中写死某个业务项目的端口、服务路径、数据库、账号或私有环境。

## 任务分级

| Level | 场景 | 要求 |
| --- | --- | --- |
| S | typo、注释、小范围文档或日志 | 最小验证即可 |
| M | bug、小功能、脚本或规范优化 | 记录探索、计划、验证、评审和总结 |
| L | 跨模块、架构、模板体系 | 完整计划，执行前人工确认 |
| CRITICAL | 数据、权限、安全、生产配置、破坏性操作 | 人工确认、回滚方案、安全评审、完整验证 |

## 标准任务目录

```text
docs/worklog/tasks/<yyyy-mm-dd>-<task-slug>/
|-- explore.md
|-- mini-prd.md
|-- plan.md
|-- verification.md
|-- review.md
|-- summary.md
|-- artifact-manifest.json
`-- artifacts/
    |-- index.html
    `-- release-report.html
```

## 常用入口

```bash
make new-task NAME=example LEVEL=M
make explore FILES="AGENTS.md CLAUDE.md README.md" MSG="workflow adaptation"
make gate-workflow
make gate-quality
make verify PROFILE=scaffold
```

也可以直接使用 SCALE CLI：

```bash
scale preflight --service all
scale artifact render --task-id <task-dir> --type release-report
scale artifact doctor --task-id <task-dir>
scale assets doctor --json
scale standards doctor --changed --json
```

## HTML Artifact

Markdown 是可维护源文件，HTML 是给人类审阅、对比和签收的派生视图。

默认类型：

- `plan-comparison`: 方案对比。
- `implementation-plan`: 实施方案。
- `code-review`: 代码评审摘要。
- `status-report`: 进度状态报告。
- `incident-report`: 故障复盘。
- `release-report`: 发布签收报告。

HTML artifact 必须可追溯到源 Markdown，并通过 `scale artifact doctor` 检查远程脚本、远程样式和疑似密钥。

## 资源治理

脚手架必须避免把生成物、临时报告和长期规范混在一起。

- 长期维护：标准、模板、README、ADR、可复用脚本。
- 任务证据：worklog、验证记录、review、summary，按需提交。
- 临时产物：截图、视频、coverage、E2E report、运行日志、一次性脚本，默认不提交。
- 最终事实：任务结束后沉淀到长期维护文档，不让大量中间方案污染主文档。

## 工具和 Skills

Agent 需要主动选择工具，但必须记录证据：

- UI/UX: `frontend-design`、`ui-ux-pro-max`、awesome-design-md 思路。
- 浏览器/E2E: Playwright、Agent Browser、web-access、Chrome DevTools MCP。
- 端侧/桌面: CUA/computer-use，必须有边界和人工确认。
- 外部 CLI: Codex、Claude Code、Gemini CLI、OpenCode 等必须记录版本、命令和输出摘要。

## 提交规则

- 不使用 `git add .` 提交脚手架治理变更。
- 不把业务项目专用逻辑写进脚手架通用脚本。
- 合并到 `master/main` 或推远端前，必须明确运行过相关验证。
- 未运行的验证必须写成“未验证”，不能写成“通过”。
