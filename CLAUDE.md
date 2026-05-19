# CLAUDE.md

Claude Code 入口。通用规则以 `AGENTS.md` 为准，本文件只保留 Claude 使用时最常用的提醒。

## 先读

1. `AGENTS.md`
2. `CONTEXT.md`
3. `docs/CONTEXT-MAP.md`
4. `docs/workflow/README.md`
5. `docs/standards/README.md`

## 常用命令

```bash
make preflight
make new-task NAME=task-slug LEVEL=M
make explore FILES='AGENTS.md CLAUDE.md README.md' MSG='main contradiction'
make gate-workflow
make verify PROFILE=scaffold
make scale-smoke TASK='workflow scaffold adaptation' FILES='AGENTS.md,README.md'
```

PowerShell:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/workflow/scale-smoke.ps1 -Task "workflow scaffold adaptation" -Files "AGENTS.md,README.md"
```

## 行为约束

- 未运行验证不能说通过。
- 发现不确定事实要标记 `[UNCERTAIN]`。
- 修改前确认 Git 状态，避免覆盖人类改动。
- 对 UI、浏览器、MCP、桌面自动化、外部 CLI 的使用必须写明证据。
- 任务结束时，把可复用经验沉淀到长期文档，不提交临时报告。
