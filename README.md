# project-scaffold

project-scaffold 是工程化工作流实践脚手架，用来把 SCALE Engine 的治理基线复制到新项目：任务分级、探索记录、计划/验证/评审产物、服务矩阵、资源治理、Agent 协作规范和发布前证据检查。

它不是业务代码模板，而是项目治理模板。业务项目接入后，应保留通用工作流，再按自己的语言、服务和部署方式调整 `.agent/project.json`、`.scale/verification.json` 和项目文档。

## 🌐 社区与推广

### 链接

| 平台 | 链接 | 说明 |
|------|------|------|
| 📦 **GitHub** | [https://github.com/hongmaple0820/scale-engine](https://github.com/hongmaple0820/scale-engine) | 源码 + Issues + PR |
| 🔧 **Gitee** | [https://gitee.com/hongmaple/scale-engine](https://gitee.com/hongmaple/scale-engine) | 国内镜像 |
| 📦 **npm** | [https://www.npmjs.com/package/@hongmaple0820/scale-engine](https://www.npmjs.com/package/@hongmaple0820/scale-engine) | 包下载 |

## 快速开始

```bash
make preflight
make new-task NAME=feature-slug LEVEL=M
make explore FILES='AGENTS.md CLAUDE.md README.md' MSG='workflow adaptation'
make gate-workflow
make verify PROFILE=scaffold
```

## SCALE v0.21.1 能力入口

```bash
make scale-smoke TASK='为 Go 服务接入工作流' FILES='AGENTS.md,README.md'
make scale-mode TASK='修复登录权限校验' FILES='src/auth.ts,tests/auth.test.ts'
make scale-radar TASK='设计上传页面 UI' PHASE=plan LEVEL=M FILES='src/pages/upload.tsx'
make scale-dashboard
```

Windows PowerShell 用户可直接运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/workflow/scale-smoke.ps1 -Task "为 Go 服务接入工作流" -Files "AGENTS.md,README.md"
```

这些命令用于演示和复制：

- `governance mode`：按任务描述和文件风险自动升级治理强度。
- `context budget`：报告 Always/on-demand/evidence/archive/generated 上下文成本。
- `codegraph status`：优先使用 CodeGraph/Graphify，缺失时显式回退到本地扫描。
- `eval run`：运行工作流基线评测，保留失败复盘数据。
- `skill radar`：按任务阶段推荐 skills、MCP、浏览器、桌面自动化和外部 CLI，并输出置信度、安全等级和证据要求。
- `artifact dashboard`：生成本地 HTML 治理看板，方便人类审阅。

## 目录职责

| 路径 | 职责 |
| --- | --- |
| `AGENTS.md` | Agent 通用协作规则和红线 |
| `CLAUDE.md` | Claude Code 兼容入口，链接回通用规则 |
| `CONTEXT.md` | 低 token 领域词汇和禁止误解项 |
| `docs/CONTEXT-MAP.md` | 模块、文档和更新触发关系 |
| `.agent/project.json` | service matrix、verification profile 和语言命令 |
| `.scale/` | SCALE 运行策略、评测基线、代码智能配置和本地证据 |
| `scripts/workflow/` | new-task、explore、resume、verify 等工作流命令 |
| `scripts/gates/` | G1-G7 门禁 |
| `docs/workflow/` | 工作流说明 |
| `docs/standards/` | 跨项目工程规范 |
| `docs/worklog/` | 任务产物、验证记录和指标 |

## Git 分支规范

默认格式：
```text
<type>/<human-author>/<agent-platform>-<scope>-<task>-<MMDD>
```

示例：
```text
feature/maple/codex-workflow-service-matrix-0519
fix/maple/claude-auth-token-refresh-0519
docs/maple/codex-scaffold-readme-0519
```

规则：
- `feature/`、`fix/`、`docs/`、`chore/` 用于人类和 Agent 协作分支。
- `main/master` 不直接操作，除非用户明确要求。
- 合并前必须有真实验证命令和输出摘要。
- 不使用 `git add .` 混入临时文件、生成报告或本地配置。

## 文档和资源治理
- 长期维护：README、AGENTS、CLAUDE、标准、ADR、可复用脚本。
- 任务证据：worklog、verification、review、summary，按需提交。
- 临时产物：截图、视频、coverage、E2E report、运行日志、一次性脚本，默认不提交。
- 最终事实：任务结束后沉淀到长期文档，删除或忽略中间方案，避免历史版本污染。

## 完成定义

只有同时满足以下条件，Agent 才能声明完成：
- 改动范围和用户目标一致。
- 相关验证已实际运行，失败项已说明。
- 没有把跳过、缺工具或 dry-run 说成通过。
- 文档、服务矩阵和工作流入口没有互相矛盾。
- 最终回复包含完成内容、验证结果和剩余风险。
