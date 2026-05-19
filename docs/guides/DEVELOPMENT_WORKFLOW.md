# 开发工作流指南

本文说明日常任务如何使用 project-scaffold。它面向人类开发者和 Agent，重点是“怎么做”和“何时算完成”。

## 任务分级

| 等级 | 适用场景 | 最小要求 |
| --- | --- | --- |
| S | typo、注释、小范围文档 | 读相关文件，做最小改动，运行相关验证 |
| M | 普通 bug、小功能、脚本或文档结构优化 | 创建任务目录，记录探索、计划、验证和总结 |
| L | 跨模块、跨服务、架构或模板体系 | 完整计划、影响面分析、回滚方案、较完整验证 |
| CRITICAL | 数据、权限、安全、生产配置、发布、破坏性操作 | 人工确认、安全评审、回滚方案、完整验证 |

不知道选哪一级时，先按 M 级处理。

## 标准闭环

```text
探索 -> 规划 -> 执行 -> 验证 -> 沉淀
```

这不是要求写很多文档，而是要求每一步留下足够证据，避免“看起来完成、实际没验证”。

## 1. 探索

目标：读现状，找到主要矛盾。

动作：

```bash
make new-task NAME=task-slug LEVEL=M
make explore FILES='file1 file2 file3' MSG='主要矛盾说明'
make gate-workflow
```

探索记录至少回答：

- 读了哪些文件？
- 当前任务真正难点是什么？
- 哪些地方不能靠猜？
- 有没有已有规范、脚本或测试可复用？

G1 通过后再进入规划。

## 2. 规划

目标：把任务变成可执行方案。

填写任务目录里的 `mini-prd.md` 和 `plan.md`，至少包含：

- 目标和非目标。
- 影响文件、服务、文档和配置。
- 异常场景和风险。
- 回滚方案。
- 验证命令。

运行：

```bash
make gate-workflow
```

G2 失败时，不要绕过。先补齐计划里的验收、风险、回滚和验证策略。

## 3. 执行

目标：按计划做最小必要改动。

原则：

- 优先复用项目已有脚本、测试和工具。
- 不顺手重构无关文件。
- 不覆盖人类未提交改动。
- 不把临时报告、截图、日志和 Agent 本地状态混入提交。

涉及代码行为时，优先先写或补测试。没有测试条件时，在 `verification.md` 写清楚原因和替代验证。

## 4. 验证

目标：用真实命令证明当前改动是否可交付。

常用命令：

```bash
make gate-workflow
make gate-quality
make verify PROFILE=scaffold
git diff --check
```

验证记录写入 `verification.md`：

| 状态 | 写法 |
| --- | --- |
| 已通过 | 写明命令、时间、关键输出摘要 |
| 失败 | 写明失败命令、错误摘要、是否为既有问题 |
| 未运行 | 明确写“未验证”，并说明原因 |
| dry-run | 只能说明可调度，不能写成业务通过 |

## 5. 沉淀

目标：把有价值的信息留下，把临时过程清掉。

应该沉淀：

- 当前事实和最终决策。
- 可复用脚本或模板。
- 验证入口和服务矩阵变化。
- 对后续任务有用的约束。

不应沉淀：

- 过期方案。
- 一次性日志。
- 中间截图和浏览器 trace。
- Agent 本地 worktree、缓存、会话状态。

## 6. 提交

提交前：

```bash
git status --short
git diff --check
```

只 stage 本次任务相关文件，例如：

```bash
git add README.md docs/workflow/README.md scripts/workflow/verify.sh
git commit -m "chore(workflow): clarify verification flow"
```

不要使用 `git add .`。

## 常见问题

### 小改动也要完整流程吗？

不用。S 级任务保持轻量，但仍要读相关文件并运行相关验证。

### Agent 已经说完成了，还要看验证吗？

要。最终结论必须以命令输出、测试结果、浏览器验证或人工确认记录为准。

### `scale upgrade apply` 可以直接跑吗？

不建议。先运行：

```bash
make workflow-upgrade-check
make workflow-upgrade-plan
```

审阅计划后再决定是否 apply。遇到 `manual-review` 时不能自动覆盖。

### 哪些本地文件必须忽略？

根 `.gitignore` 应覆盖 Agent 本地状态，例如 `.claude/worktrees/`、`.codex/tmp/`、`.cursor/tmp/`、`.continue/`、`.aider*`、`.gemini/tmp/`、`.playwright-mcp/`。
