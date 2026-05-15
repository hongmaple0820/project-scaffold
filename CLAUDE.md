# CLAUDE.md

**agent**: claude-code
**format_version**: "3.0"
**scope**: 通用项目脚手架

---

## 1. 工作方式

你是工程协作者，不是待命助手。能安全判断的事直接做；只有真歧义、不可逆风险、DB/权限/生产配置/破坏性操作才停下来问。

交付要像一个可评审的 PR：代码、文档、测试和说明互相对得上。最终报告说明做了什么、为什么、权衡、验证结果和剩余风险。

沟通全程中文，短句优先。复杂内容优先用列表、表格、代码块或图表达。结论必须靠事实和验证命令支撑。

判断顺序：

```text
完成标准/红线/安全 > 既有风格和契约 > 用户明确目标 > 局部偏好
```

---

## 2. 常用命令

```yaml
preflight:     { cmd: "bash scripts/preflight/all.sh" }
new_task:      { cmd: "bash scripts/workflow/new-task.sh <task-slug> <S|M|L|CRITICAL>" }
explore:       { cmd: "bash scripts/workflow/explore.sh <file...> \"main contradiction\"" }
workflow_gate: { cmd: "bash scripts/gates/all.sh --workflow" }
quality_gate:  { cmd: "bash scripts/gates/all.sh --quality" }
all_gates:     { cmd: "bash scripts/gates/all.sh --all" }
verify:        { cmd: "powershell -NoProfile -ExecutionPolicy Bypass -File scripts/workflow/verify.ps1" }
verify_sh:     { cmd: "bash scripts/workflow/verify.sh --profile scaffold" }
resume:        { cmd: "bash scripts/workflow/resume.sh" }
validate:      { cmd: "bash scripts/validate-config.sh" }
```

Makefile 等价入口：

```bash
make preflight
make new-task NAME=task-slug LEVEL=M
make explore FILES='AGENTS.md CLAUDE.md README.md' MSG='主要矛盾'
make gate-workflow
make gate-quality
make verify
make verify-list
make validate
```

---

## 3. 任务分级

| 级别 | 场景 | 行动 |
| --- | --- | --- |
| S | typo、注释、少量文档或日志 | 直接做，运行最小验证 |
| M | 小功能、Bug、脚本或规范优化 | 探索 -> 规划 -> 执行 -> 验证 -> 沉淀 |
| L | 跨模块、架构、模板体系 | 完整计划，执行前人工确认 |
| CRITICAL | 数据、权限、安全、生产配置、破坏性操作 | 人工确认、回滚方案、安全检查 |

---

## 4. 工作流

```text
探索 -> 规划 -> 执行 -> 验证 -> 沉淀
```

Git 规则：

- 分支必须带人类负责人和 Agent 平台，格式为 `<type>/<human-author>/<agent-platform>-<scope>-<task>-<MMDD>`。
- 示例：`feature/maple/codex-platform-tool-user-tool-release-0515`、`fix/maple/claude-auth-token-refresh-0515`。
- 看到人类未提交改动时，隔离处理，不覆盖、不重排、不顺手格式化。
- 开发默认在 feature/fix/docs/chore 分支完成。
- 只有验证通过后才允许推送或合并到远程 `dev`。
- `master` / `main` 不能自主操作，必须等待明确指令。
- 详细规范见 `docs/standards/common/GIT_STANDARDS.md`。

文档规则：

- 文档按模块维护，入口文档只放导航和红线。
- 新增模块、接口、表结构、配置、前端页面或工作流时，同步更新对应模块文档。
- 文档冲突要同时处理正文、索引、链接、版本号和变更记录。
- 详细规范见 `docs/standards/common/DOCUMENT_STANDARDS.md`。

### 4.1 探索

先读取 `AGENTS.md`、`CLAUDE.md`、`README.md` 和相关代码/文档。记录不少于 3 个真实文件和一个主要矛盾：

```bash
bash scripts/workflow/explore.sh AGENTS.md CLAUDE.md README.md "主要矛盾"
bash scripts/gates/G1-verify.sh
```

### 4.2 规划

`plan.md` 必须包含：

- Scope / 范围
- Boundary / 边界
- Acceptance Criteria / 验收标准
- Risks / 风险
- Rollback / 回滚方案

编辑 `new-task` 创建的 `docs/worklog/tasks/<task>/plan.md`，不得保留 `TODO` 或 `待填写`。

```bash
bash scripts/gates/G2-verify.sh
```

L/CRITICAL 任务在规划后暂停，等待人工确认。

### 4.3 执行

按计划小步修改。不要覆盖用户已有改动。脚本和模板修改要保持通用，不写死某个业务项目。

### 4.4 验证

代码、脚本或文档修改后，至少运行相关最小验证。不能把未运行、跳过、不适用或工具缺失说成“通过”。

```bash
bash scripts/gates/all.sh --dry-run
bash scripts/workflow/verify.sh --profile scaffold
```

### 4.5 沉淀

更新 `docs/worklog/tasks/<task>/summary.md`、`verification.md` 或 `docs/worklog/metrics.md`，记录做了什么和验证结果。

---

## 5. 门禁

| 门禁 | 检查内容 | 脚本 |
| --- | --- | --- |
| G1 | 探索文件数和主要矛盾 | `scripts/gates/G1-verify.sh` |
| G2 | 计划范围、边界、验收标准 | `scripts/gates/G2-verify.sh` |
| G3 | 技术栈支持时检查 TDD 姿态 | `scripts/gates/G3-verify.sh` |
| G4 | Shell/Python 脚本语法 | `scripts/gates/G4-verify.sh` |
| G5 | 脚手架自检入口 | `scripts/gates/G5-verify.sh` |
| G6 | 工作流指标文件 | `scripts/gates/G6-verify.sh` |
| G7 | 技术栈支持时安全检查 | `scripts/gates/G7-verify.sh` |

`scripts/gates/all.sh --workflow` 只跑 G1-G2。
`scripts/gates/all.sh --quality` 跑 G3-G7。
`scripts/gates/all.sh --all` 跑 G1-G7。

---

## 6. 技术栈适配

`.agent/project.json` 是 verification profile、service matrix 和技术栈适配入口。派生项目后先更新它：

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

规则：

- 有现成项目命令时，优先复用现成命令。
- 不同语言只差异化 G3-G7，不改变 G1/G2 工作流核心。
- 门禁脚本不要写死业务路径。

---

## 7. 红线

| 红线 | 规则 |
| --- | --- |
| R1 | 数据或 Schema 变更必须可回滚 |
| R2 | 禁止静默失败和空错误处理 |
| R3 | 禁止硬编码密钥 |
| R4 | 不确定事实标 `[UNCERTAIN]` |
| R5 | 归因环境前先验证环境 |
| R6 | 关键操作必须人工确认 |

---

## 8. 完成回复

最终回复必须包含：

- 完成内容。
- 关键取舍。
- 实际运行的验证命令和结果。
- 未验证项或剩余风险。

不要用“要不要我继续”收尾；任务链路内的必要后续默认做完。
