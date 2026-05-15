# Agent Workflow

本目录定义脚手架的通用工作流。所有派生项目共享同一套阶段和任务产物；语言、框架、服务矩阵和构建工具差异只放在 `.agent/project.json`、`scripts/workflow/verify.sh` 与 G3-G7 门禁中。

`scale init` 生成项目时应落地的治理资产见 [SCALE_INIT_GOVERNANCE_TEMPLATE.md](SCALE_INIT_GOVERNANCE_TEMPLATE.md)。

## 任务等级

| 等级 | 场景 | 要求 |
| --- | --- | --- |
| S | typo、注释、少量文档或日志 | 直接修改，运行最小验证 |
| M | 小功能、Bug、脚本或规范优化 | 记录探索、计划、验证和总结 |
| L | 跨模块、架构、模板体系 | 完整计划，执行前人工确认 |
| CRITICAL | 数据、权限、安全、生产配置、破坏性操作 | 人工确认、回滚方案、安全检查 |

## 标准流程

```text
探索 -> 规划 -> 执行 -> 验证 -> 沉淀
```

## 创建任务

```bash
bash scripts/workflow/new-task.sh "task-slug" M
```

生成目录：

```text
docs/worklog/tasks/<yyyy-mm-dd>-<task-slug>/
├── explore.md
├── mini-prd.md
├── plan.md
├── verification.md
├── review.md
└── summary.md
```

同时更新 `.agent/state/current.json`。

## 探索

探索要记录真实文件和主要矛盾：

```bash
bash scripts/workflow/explore.sh AGENTS.md CLAUDE.md README.md "主要矛盾"
bash scripts/gates/G1-verify.sh
```

G1 要求：

- 至少 3 个真实文件。
- `main_contradiction` 非空。

## 规划

```bash
# 编辑 new-task 创建的 docs/worklog/tasks/<task>/plan.md
bash scripts/gates/G2-verify.sh
```

G2 要求 `plan.md` 至少包含有效内容，不能只保留模板占位：

- Scope / 范围
- Boundary / 边界
- Acceptance Criteria / 验收标准
- Risks / 风险
- Rollback / 回滚方案
- Verification / 验证

面向用户的新 API、UI 流程、权限、删除、恢复、分享、上传等功能，还要填写 `mini-prd.md`。

## 执行

执行阶段按计划小步修改。阶段切换时保存检查点：

```bash
bash scripts/workflow/checkpoint.sh execute
```

不要覆盖用户已有改动。不要把脚手架通用逻辑写成某个业务项目专用逻辑。

## 验证

```bash
bash scripts/gates/all.sh --dry-run
bash scripts/gates/all.sh --workflow
bash scripts/gates/all.sh --quality
bash scripts/workflow/verify.sh --profile scaffold
```

推送或合并到远程 `dev` 前，必须完成相关验证。`master` / `main` 只在用户明确指令下操作，详见 [Git 工作流规范](../standards/common/GIT_STANDARDS.md)。

PowerShell 自检：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/workflow/verify.ps1
```

Profile/service matrix：

```bash
bash scripts/workflow/verify.sh --list
bash scripts/workflow/verify.sh --profile default
bash scripts/workflow/verify.sh --service service-name
```

门禁分组：

| 分组 | 内容 |
| --- | --- |
| `--workflow` | G1、G2 |
| `--quality` | G3、G4、G5、G6、G7 |
| `--all` | G1-G7 |

## 恢复

```bash
bash scripts/workflow/resume.sh
```

该命令会显示当前任务、等级、阶段、产物目录、已探索文件、主要矛盾和已完成门禁，并给出下一步建议。

## 沉淀

任务收尾时更新：

- `verification.md`：实际运行的命令和结果。
- `summary.md`：完成内容、取舍、风险。
- `docs/worklog/metrics.md`：任务指标行。

未运行的验证必须写成“未验证”，不能写成“通过”。
