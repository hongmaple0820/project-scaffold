# project-scaffold

[![GitHub Sponsors](https://img.shields.io/badge/Sponsor-GitHub%20Sponsors-ea4aaa?logo=githubsponsors)](https://github.com/sponsors/hongmaple0820)
[![SCALE Engine](https://img.shields.io/badge/Powered%20by-SCALE%20Engine-2563eb)](https://github.com/hongmaple0820/scale-engine)
[![npm](https://img.shields.io/badge/npm-%40hongmaple0820%2Fscale--engine-cb3837?logo=npm)](https://www.npmjs.com/package/@hongmaple0820/scale-engine)

## 社区与赞助

这个脚手架沉淀自 SCALE Engine 的 agent 工程治理实践，用于把可执行工作流、质量门禁、任务产物和项目规范快速复制到新项目。

- GitHub 社区: [hongmaple0820/scale-engine](https://github.com/hongmaple0820/scale-engine)
- Gitee 镜像: [hongmaple/scale-engine](https://gitee.com/hongmaple/scale-engine)
- npm 包: [@hongmaple0820/scale-engine](https://www.npmjs.com/package/@hongmaple0820/scale-engine)
- 打赏支持: [GitHub Sponsors](https://github.com/sponsors/hongmaple0820)
- 社区文档: [docs/COMMUNITY.md](docs/COMMUNITY.md)

如果这套脚手架帮你节省了项目治理、Agent 工作流和质量门禁搭建时间，欢迎 Star、反馈 issue，或通过 GitHub Sponsors 打赏支持持续维护。

通用工程化脚手架，用来给新项目复制一套可执行的 Agent 工作流、规范入口、质量门禁和任务记录结构。

本仓库不是业务项目模板本身，而是治理基线。派生到 Go、Node、Python、Java、前端或其他项目时，保留通用工作流，按目标技术栈改 `.agent/project.json` 和验证命令。

## 快速开始

```bash
# 1. 环境预检
make preflight

# 2. 创建任务
make new-task NAME=feature-slug LEVEL=M

# 3. 记录探索
bash scripts/workflow/explore.sh AGENTS.md CLAUDE.md README.md "主要矛盾"

# 4. 跑工作流门禁
make gate-workflow

# 5. 跑脚手架自检
make verify
```

任务产物会写入：

```text
docs/worklog/tasks/<yyyy-mm-dd>-<task-slug>/
```

## 仓库内容

| 区域 | 路径 | 用途 |
| --- | --- | --- |
| Agent 规则 | `AGENTS.md`、`CLAUDE.md` | 工作方式、门禁、红线、完成定义 |
| 工作流脚本 | `scripts/workflow/` | 新任务、探索记录、计划、恢复、自检 |
| 门禁脚本 | `scripts/gates/` | G1-G7 质量门禁 |
| 技术栈配置 | `.agent/project.json` | 不同语言的 lint/test/coverage/security 命令 |
| 规范文档 | `docs/standards/` | 通用命名、API、数据库、Git、协作、文档规范 |
| 工作流文档 | `docs/workflow/README.md` | 五阶段工作流和门禁说明 |
| 任务记录 | `docs/worklog/` | 任务过程、验证记录、指标 |
| 模板 | `templates/` | 计划和 ADR 模板 |

## Git 维护策略

分支必须带人类负责人和 Agent 平台，标准格式：

```text
<type>/<human-author>/<agent-platform>-<scope>-<task>-<MMDD>
```

示例：

```bash
feature/maple/codex-platform-tool-user-tool-release-0515
fix/maple/claude-auth-token-refresh-0515
docs/maple/codex-scaffold-git-workflow-0515
```

关键规则：

- 默认在 feature/fix/docs/chore 分支开发。
- 人类负责人和 Agent 平台必须都出现在分支名中。
- 协同开发时先看 `git status --short`，不得覆盖人类未提交改动。
- 验证没有阻断问题后，才允许推送或合并到远程 `dev`。
- `master` / `main` 不能自主操作，必须等待明确指令。
- 推送 `origin/dev` 前必须确认当前提交包含最新 `origin/dev`。

详见 [Git 工作流规范](docs/standards/common/GIT_STANDARDS.md)。

## 文档资产策略

- 文档按模块维护：通用规范、项目差异、架构、工作流、任务记录和经验沉淀分目录归档。
- 总入口只做导航和红线，细节放到对应模块文档。
- 新增或修改模块时，同步更新相关索引、上下游说明、版本号和变更记录。
- 文档冲突解决后必须检查相对链接，避免入口指向不存在的文件。

详见 [文档规范](docs/standards/common/DOCUMENT_STANDARDS.md)。

## 工作流

```text
探索 -> 规划 -> 执行 -> 验证 -> 沉淀
```

| 阶段 | 关键动作 | 产物 |
| --- | --- | --- |
| 探索 | 读规则、读相关文件、识别主要矛盾 | `.agent/state/explore.json` |
| 规划 | 明确范围、边界、验收标准、风险、回滚 | `plan.md` |
| 执行 | 小步修改，保护既有行为 | 代码/文档/脚本 |
| 验证 | 实际运行相关命令 | `verification.md` |
| 沉淀 | 更新总结和指标 | `summary.md`、`metrics.md` |

## 门禁命令

```bash
# 检查脚本是否存在
bash scripts/gates/all.sh --dry-run

# 检查探索和计划
bash scripts/gates/all.sh --workflow

# 检查脚本、技术栈命令和安全门禁
bash scripts/gates/all.sh --quality

# 全部门禁
bash scripts/gates/all.sh --all
```

Profile/service 验证入口：

```bash
bash scripts/workflow/verify.sh --list
bash scripts/workflow/verify.sh --profile scaffold
bash scripts/workflow/verify.sh --profile default
bash scripts/workflow/verify.sh --service service-name
```

PowerShell 包装入口：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/workflow/verify.ps1
```

## 技术栈适配

派生项目后，先改 `.agent/project.json`：

```json
{
  "profiles": {
    "default": {
      "services": ["api"],
      "checks": ["lint", "test", "build"]
    }
  },
  "services": {
    "api": {
      "path": "services/api",
      "stack": "go",
      "required": true
    }
  }
}
```

默认支持：

| 技术栈 | 探测文件 | 命令来源 |
| --- | --- | --- |
| Go | `go.mod` | `golangci-lint`、`go test`、`gosec` |
| Node | `package.json` | `npm run lint`、`npm test`、`npm audit` |
| Python | `pyproject.toml`、`requirements.txt`、`setup.py` | `ruff`、`pytest`、`bandit` |

原则：G1/G2 是通用工作流；G3-G7 按语言差异化。目标项目已有命令时，优先复用已有命令。

## 常用 Make 命令

```bash
make help
make preflight
make new-task NAME=task-slug LEVEL=M
make explore FILES='AGENTS.md CLAUDE.md README.md' MSG='主要矛盾'
make checkpoint PHASE=execute
make resume
make gate-workflow
make gate-quality
make gate
make verify
make verify-list
make validate
```

## 目录结构

```text
project-scaffold/
├── AGENTS.md
├── CLAUDE.md
├── README.md
├── Makefile
├── .agent/
│   └── project.json
├── .claude/
│   ├── settings.json
│   └── workflow.json
├── docs/
│   ├── standards/
│   ├── workflow/
│   └── worklog/
├── scripts/
│   ├── gates/
│   ├── lib/
│   ├── preflight/
│   └── workflow/
└── templates/
```

## 完成标准

- 已按任务等级运行必要工作流。
- 相关门禁或自检命令实际运行。
- 失败、跳过、不适用和工具缺失都如实记录。
- 没有引入密钥、临时文件或业务项目专属假设。

## 贡献

参见 [CONTRIBUTING.md](CONTRIBUTING.md)。
