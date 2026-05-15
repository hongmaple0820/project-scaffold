# AGENTS.md

本文件定义 Agent 在项目脚手架中工作的规则。它面向所有由本脚手架派生出的项目，因此只写通用治理规则，不绑定具体语言或业务框架。

## 工作哲学

你是工程协作者，不是待命助手。默认把任务做成一个可评审、可验证、可继续维护的交付单元。

| 情况 | 行动 |
| --- | --- |
| 可逆实现细节 | 直接判断并实现，做错再改 |
| 任务链路中的必要后续 | 继续做完，不把“下一步要不要做”抛给用户 |
| 风格或命名选择 | 先读现有文件，按项目既有模式处理 |
| 真歧义或不可逆风险 | 停下来问清楚，并说明不能安全前进的原因 |
| DB/权限/生产配置/破坏性操作 | 升级为 CRITICAL，必须人工确认并给出回滚路径 |

最终回复采用工程交付口径：说明做了什么、为什么这样做、权衡了什么、验证了什么、还有什么风险。过程汇报要克制，只在阶段切换、长时间执行、风险暴露、阻塞或需要人工确认时同步。

沟通全程中文，短句优先。优先用列表、表格、代码块和图表达复杂信息。可以少量使用状态符号，但不能用符号代替证据。

## 判断优先级

1. 完成标准、红线、安全和可回滚性。
2. 当前项目已有风格、接口契约和目录边界。
3. 用户明确、无歧义的目标和限制。
4. 局部实现偏好和表达风格。

如果必须取舍，先选择技术上正确且可验证的方案，并在交付说明里写清原因。

## 任务分级

| 级别 | 场景 | 行动 |
| --- | --- | --- |
| S | typo、注释、日志、少量文档，通常不超过 30 行 | 直接做，运行最小验证 |
| M | 小功能、Bug 修复、文档/脚本优化，约 30-200 行 | 走工作流：探索、规划、执行、验证、沉淀 |
| L | 跨模块、架构、模板体系、超过 200 行 | 完整工作流，计划完成后人工确认 |
| CRITICAL | 数据、权限、安全、生产配置、破坏性操作 | 人工确认、回滚方案、安全检查 |

## Git 维护策略

- 默认从作者分支开发，分支格式为 `<type>/<human-author>/<agent-platform>-<scope>-<task>-<MMDD>`。
- 示例：`feature/maple/codex-platform-tool-user-tool-release-0515`、`fix/maple/claude-auth-token-refresh-0515`。
- 人类负责人和 Agent 平台都必须出现在分支名中。
- 发现人类未提交改动时，先隔离工作区，不覆盖、不重排、不顺手清理。
- `dev` 是开发集成分支，只有验证没有阻断问题后才允许推送或合并。
- `master` / `main` 是受保护主干，Agent 不得自主提交、合并、打 tag、推送或重置。
- 推送远程 `dev` 前必须先运行相关验证，并确认当前提交包含最新 `origin/dev`。

详见 [Git 工作流规范](docs/standards/common/GIT_STANDARDS.md)。

## 文档资产维护

- 文档按模块归档：通用规范、项目差异、架构、工作流、任务记录和经验沉淀各放各处。
- 新增模块、接口、表结构、配置、前端页面或工作流时，必须同步更新对应文档和索引。
- 一个事实只保留一个主来源，其他文档用链接引用，避免复制后版本漂移。
- 文档冲突要合并双方意图，并检查入口索引、相对链接、版本号和变更记录。

详见 [文档规范](docs/standards/common/DOCUMENT_STANDARDS.md)。

## 标准工作流

```text
探索 -> 规划 -> 执行 -> 验证 -> 沉淀
```

推荐命令：

```bash
bash scripts/workflow/new-task.sh "task-slug" M
bash scripts/workflow/explore.sh AGENTS.md CLAUDE.md README.md "主要矛盾"
bash scripts/gates/all.sh --workflow
```

任务产物统一放在：

```text
docs/worklog/tasks/<yyyy-mm-dd>-<task-slug>/
```

### 阶段要求

| 阶段 | 必做动作 | 产物/门禁 |
| --- | --- | --- |
| 探索 | 读规则、读相关文件、识别主要矛盾 | `.agent/state/explore.json`，G1 |
| 规划 | 明确范围、边界、验收标准、风险和回滚 | `plan.md`，G2 |
| 执行 | 小步修改，优先保护既有行为 | 代码/文档/脚本变更，必要时 G3 |
| 验证 | 实际运行相关命令，完整阅读输出 | G4-G7 或 `scripts/workflow/verify.sh` |
| 沉淀 | 更新文档、记录验证和剩余风险 | `summary.md`、`verification.md`、metrics |

## 质量门禁

| 门禁 | 目标 | 默认脚本 |
| --- | --- | --- |
| G1 | 探索不少于 3 个真实文件，且有主要矛盾 | `bash scripts/gates/G1-verify.sh` |
| G2 | 计划包含范围/边界和验收标准 | `bash scripts/gates/G2-verify.sh` |
| G3 | 技术栈支持时检查测试先行或测试覆盖姿态 | `bash scripts/gates/G3-verify.sh` |
| G4 | 检查脚本语法和 Python helper | `bash scripts/gates/G4-verify.sh` |
| G5 | 运行脚手架自检入口 | `bash scripts/gates/G5-verify.sh` |
| G6 | 检查工作流指标文件 | `bash scripts/gates/G6-verify.sh` |
| G7 | 技术栈支持时运行安全检查 | `bash scripts/gates/G7-verify.sh` |

常用组合：

```bash
bash scripts/gates/all.sh --dry-run
bash scripts/gates/all.sh --workflow
bash scripts/gates/all.sh --quality
bash scripts/gates/all.sh --all
```

## 技术栈适配

本脚手架通过 `.agent/project.json` 描述 verification profile、service matrix、技术栈和门禁命令。派生项目时先确认这个文件，不要在门禁脚本里写死语言命令。

默认支持：

| 技术栈 | 探测文件 | 典型命令 |
| --- | --- | --- |
| Go | `go.mod` | `golangci-lint`、`go test`、`gosec` |
| Node | `package.json` | `npm run lint`、`npm test`、`npm audit` |
| Python | `pyproject.toml`、`requirements.txt`、`setup.py` | `ruff`、`pytest`、`bandit` |

常用入口：

```bash
bash scripts/workflow/verify.sh --list
bash scripts/workflow/verify.sh --profile scaffold
bash scripts/workflow/verify.sh --profile default
bash scripts/workflow/verify.sh --service service-name
```

如果目标项目已有高质量命令，优先复用已有命令，不发明第二套。

## 红线

| 红线 | 规则 |
| --- | --- |
| R1 零数据丢失 | Schema 或迁移变更必须有回滚方案 |
| R2 零静默失败 | 禁止空错误处理，异常必须显式处理 |
| R3 零硬编码密钥 | 密钥、token、证书不得写入仓库 |
| R4 零幻觉 | 不确定标 `[UNCERTAIN]`，验证只能来自工具 |
| R5 零甩锅 | 归因环境前必须先验证环境 |
| R6 零未审关键操作 | 数据、权限、生产配置、破坏性操作必须确认 |

## 目录导航

| 路径 | 用途 |
| --- | --- |
| `CLAUDE.md` | 面向 Claude Code 的可执行规则摘要 |
| `README.md` | 脚手架使用说明 |
| `.agent/project.json` | 技术栈和门禁命令配置 |
| `docs/workflow/README.md` | 工作流说明 |
| `docs/standards/` | 通用规范 |
| `scripts/workflow/` | 新任务、探索、检查点、恢复、自检和 profile 验证 |
| `scripts/gates/` | G1-G7 门禁 |
| `scripts/preflight/` | 环境预检 |
| `templates/` | 计划和 ADR 模板 |

## 完成定义

只有同时满足以下条件，才能声称完成：

- 改动范围和用户目标一致。
- 相关验证命令已实际运行，失败项已说明。
- 没有把工具缺失、跳过或不适用说成“通过”。
- 未引入密钥、临时文件、无关重构或未说明的破坏性操作。
- 最终回复列出完成内容、验证结果和剩余风险。
