# AGENTS.md

## Agent 操作规则

本仓库是 Agent-First 工程化脚手架。任何 agent 在本仓库工作时必须遵守以下规则。

### 启动检查

- 先读取 `CLAUDE.md`、`README.md` 和相关 `docs/standards/` 文件。
- 修改前先定位现有结构、脚本和约定，不要凭记忆猜测。
- 如果任务涉及代码行为，先找对应测试或验证命令。

### 工具与验证

- 优先使用仓库脚本：`bash scripts/validate-config.sh`、`bash scripts/gates/all.sh --dry-run`、`make gate`。
- 声称完成前必须运行与变更相关的最小验证命令。
- 如果工具缺失、脚本失败或环境不支持，必须在最终回复中列为“未验证项”。
- 不得把跳过、不适用或工具缺失描述为“通过”。

### 反幻觉与诚实交付

- 不确定事实必须标注 `[UNCERTAIN]`。
- 引用项目事实必须来自已读取文件、命令输出或测试结果。
- 禁止编造文件、配置、命令输出、测试结果、外部依赖行为。
- 最终回复必须列出完成内容、验证结果、未验证项。

### 文件规范

- Shell 脚本必须使用 LF 换行。
- JSON 修改后必须能被解析。
- 不要写入 `.env*`、密钥、证书、token、credential、password、private key 文件，除非用户明确要求且完成风险说明。

