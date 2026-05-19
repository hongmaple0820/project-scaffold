# 快速开始

目标：让第一次接触 project-scaffold 的同事在 15 分钟内知道这套工作流是什么、怎么跑、哪些文件会被写入。

## 1. 先理解一句话

project-scaffold 不是业务模板。它是工程治理模板，用来把人和 Agent 的协作过程变成可检查的文件、命令和验证记录。

一次标准任务会经历：

```text
探索 -> 规划 -> 执行 -> 验证 -> 沉淀
```

## 2. 检查环境

```bash
git --version
make --version
scale --version
```

如果没有 SCALE：

```bash
make bootstrap-scale
make bootstrap-scale-install
```

如果当前环境没有 `make`，可以直接运行 `scripts/workflow/` 下的 Bash 或 PowerShell 脚本。Windows 优先使用 PowerShell 包装脚本。

## 3. 跑一次预检

```bash
make preflight
```

预检只证明基础工具和脚手架入口可用，不等于业务测试通过。

## 4. 创建第一个任务

```bash
make new-task NAME=first-workflow-smoke LEVEL=M
```

它会创建任务目录：

```text
.planning/tasks/<date>-first-workflow-smoke/
```

常见文件含义：

| 文件 | 用途 |
| --- | --- |
| `explore.md` | 记录读过什么、主要矛盾是什么 |
| `mini-prd.md` | 用户目标、边界、验收 |
| `plan.md` | 实施方案、风险、回滚和验证策略 |
| `verification.md` | 实际运行过的验证命令和结果 |
| `review.md` | 评审发现和剩余风险 |
| `summary.md` | 最终沉淀和可复用结论 |

## 5. 记录探索

```bash
make explore FILES='AGENTS.md README.md docs/workflow/README.md' MSG='第一次理解工作流入口和主要约束'
```

探索阶段不是写长报告，而是证明你真的读了相关上下文，并知道当前任务的主要矛盾。

## 6. 跑工作流门禁

```bash
make gate-workflow
```

如果失败，先看输出中缺哪个产物。不要把失败项写成通过。

## 7. 跑脚手架验证

```bash
make verify PROFILE=scaffold
```

派生业务项目应把 `PROFILE` 换成自己的默认验证 profile，例如 `default`、`all` 或服务名。

## 8. 查看当前状态

```bash
make resume
```

`resume` 用来让人或 Agent 接着上次状态继续，不需要重新猜任务进度。

## 9. 提交前怎么做

```bash
git status --short
git diff --check
```

只 stage 本次任务相关文件。不要使用：

`git add .`

因为它容易混入本地配置、Agent worktree、日志、截图、临时报告和生成缓存。

## 10. 下一步阅读

- 日常任务流程：[DEVELOPMENT_WORKFLOW.md](DEVELOPMENT_WORKFLOW.md)
- Agent 协作规则：[../../AGENTS.md](../../AGENTS.md)
- 工作流细节：[../workflow/README.md](../workflow/README.md)
- 工程规范：[../standards/README.md](../standards/README.md)
