# 资源治理标准

本标准用于区分长期维护资料和任务过程产物，避免 `docs/` 变成临时测试、规划、记忆和执行日志的堆放区。

## 资源分类

| 类型 | 默认位置 | 是否长期维护 | 示例 |
| --- | --- | --- | --- |
| 产品、架构、运维、标准 | `docs/` | 是 | 产品说明、架构设计、部署手册、工程标准 |
| 单次任务规划和验证 | `.planning/tasks/<task>/` | 否 | explore、mini-prd、plan、verification、review、summary |
| 本地运行日志和临时配置 | `.agent/` | 否 | smoke 日志、临时 Nacos 配置、进程状态 |
| 可重复测试和脚本 | `tests/`、`scripts/` | 是 | 自动化测试、门禁脚本、启动脚本 |
| 可沉淀知识 | `docs/knowledge/` | 有条件 | 复用经验、故障模式、跨项目规则 |
| 外部或生成产物 | 忽略目录 | 否 | graphify 输出、临时报告、一次性 dashboard |

## Docs 准入规则

内容进入 `docs/` 前必须同时满足：

1. 关闭当前任务后仍有人需要阅读。
2. 有明确维护责任或会被后续流程引用。
3. 不是单次测试证据、执行日志、临时方案、Agent 过程记忆。
4. 不包含本地路径、密钥、一次性端口、临时 token 等环境碎片。

## 任务产物规则

M/L/CRITICAL 任务必须在 `.planning/tasks/<task>/` 留下以下文件：

| 文件 | 目的 |
| --- | --- |
| `explore.md` | 记录实际读过的文件和主矛盾 |
| `mini-prd.md` | 记录本次任务目标和非目标 |
| `plan.md` | 记录执行步骤、风险和验收标准 |
| `runtime.md` | 记录运行环境、配置来源、服务拓扑和认证方式 |
| `reality-check.md` | 区分已验证、未验证、模拟、凭据受限、环境受限 |
| `resource-cleanup.md` | 记录新增产物去向、是否应沉淀、是否应清理 |
| `verification.md` | 记录真实命令和业务链路验证 |
| `review.md` | 记录缺陷、风险和复盘 |
| `summary.md` | 记录最终交付结果 |

## 沉淀和清理

- 任务结束后，只有稳定结论进入 `docs/`，过程证据保留在 `.planning/`。
- `.agent/` 只保存本地状态、日志和临时环境文件，不作为交付资料来源。
- 如果任务产物被推广成长期资料，必须从临时语气改写为维护文档，并删除一次性环境细节。
- 发现 `docs/worklog/tasks`、`docs/plans` 中新增一次性文件时，默认视为资源治理警告。
- 历史产物迁移必须先运行 `scripts/workflow/archive-legacy-doc-artifacts.ps1` dry-run，确认清单后再使用 `-Apply`。
