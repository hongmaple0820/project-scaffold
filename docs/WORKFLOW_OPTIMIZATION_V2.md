# 工作流优化方案 v2 — 基于 v3.0 实测评估

> **评估基础**：scaffold v3.0（CLAUDE.md 182行 + workflow_state.py + new-task.sh + Gate 分层）
> **结论**：核心架构正确，修 6 个一致性问题即可

---

## 一、当前架构（保留）

```
CLAUDE.md (知识)
    ↓ AI 读取后知道该做什么
new-task.sh → workflow_state.py (状态)
    ↓ 创建任务工作区 + 初始化状态
explore.sh → workflow_state.py explore (状态)
    ↓ 记录探索产物
G1-verify.sh → workflow_state.py get (状态)
    ↓ 验证探索产物
plan.md (产物)
    ↓ AI 填写内容
G2-verify.sh → grep plan.md (内容)
    ↓ 验证计划内容
Gate G3-G7 (质量)
    ↓ 验证代码质量
```

这个架构是对的。问题在细节。

---

## 二、6 个修复项

### 修复 1：合并 plan.sh 和 new-task.sh

**问题**：两个脚本都创建任务目录，但 plan.sh 不写状态文件，G2 读不到它的产物。

| 脚本 | 目录 | 状态 | G2 能读到？ |
|------|------|------|-----------|
| new-task.sh | `.planning/tasks/YYYY-MM-DD-{name}/` | ✅ init | ✅ |
| plan.sh | `.planning/tasks/YYYY-MM-DD-{name}/` | ❌ | ❌ |

**方案**：删除 `plan.sh`，统一用 `new-task.sh`。

**改动**：
1. 删除 `scripts/workflow/plan.sh`
2. CLAUDE.md §4.2 改为：
   ```bash
   # 任务已在 new-task 阶段创建，直接编辑 plan.md
   vim .planning/tasks/$TASK_ID/plan.md
   bash scripts/gates/G2-verify.sh
   ```
3. Makefile 删除 `make plan` 目标（如有）

**理由**：一个任务一个目录。`new-task.sh` 创建的目录已经包含 plan.md 模板，不需要再建第二个目录。

---

### 修复 2：verify.ps1 改名或改功能

**问题**：`verify.ps1` 只跑语法检查（`bash -n`、`py_compile`），不跑实际门控。名字叫 `verify` 但做的事是 `lint`。

**方案 A**（推荐）：改名为 `lint-scaffold.sh`，去掉 .ps1 依赖

```bash
# scripts/workflow/lint-scaffold.sh
#!/bin/bash
set -e
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
echo "== scaffold syntax check =="
bash -n "$ROOT/scripts/gates/all.sh"
bash -n "$ROOT/scripts/workflow/new-task.sh"
bash -n "$ROOT/scripts/workflow/explore.sh"
bash -n "$ROOT/scripts/workflow/resume.sh"
bash -n "$ROOT/scripts/workflow/checkpoint.sh"
python3 -m py_compile "$ROOT/scripts/lib/workflow_state.py"
echo "[LINT] scaffold scripts OK"
```

**方案 B**：保留 verify.ps1 但改为跑真正门控

```powershell
# 实际运行 G1-G2，不是 --dry-run
bash scripts/gates/all.sh --workflow
```

**改动**：
1. 方案 A：新建 `lint-scaffold.sh`，删除 `verify.ps1`，Makefile 改 `make verify` → `make lint-scaffold`
2. 方案 B：修改 `verify.ps1` 去掉 `--dry-run`

---

### 修复 3：G6 检查 metrics.md 内容

**问题**：G6 只检查文件存在，空文件也能通过。

**当前**：
```bash
[ -f "$ROOT/docs/worklog/metrics.md" ] || { echo "metrics missing"; exit 1; }
```

**改为**：
```bash
#!/bin/bash
set -e
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
METRICS="$ROOT/docs/worklog/metrics.md"

if [ ! -f "$METRICS" ]; then
    echo "[G6] ❌ metrics.md 不存在"
    exit 1
fi

LINES=$(wc -l < "$METRICS")
if [ "$LINES" -lt 3 ]; then
    echo "[G6] ❌ metrics.md 内容不足（$LINES 行，需要 ≥3）"
    exit 1
fi

# 检查是否包含至少一个数值指标
if ! grep -qE '[0-9]+' "$METRICS"; then
    echo "[G6] ❌ metrics.md 未包含数值指标"
    exit 1
fi

echo "[G6] ✅ metrics.md 存在且包含指标数据"
```

---

### 修复 4：Makefile 补齐缺失目标

**问题**：AI 要记两个入口（`make xxx` vs `bash scripts/...`）。

**当前 Makefile**：
```makefile
make preflight / new-task / gate / gate-workflow / gate-quality / resume / verify / validate
```

**补齐**：
```makefile
explore:
	@if [ -z "$(FILES)" ]; then echo "usage: make explore FILES='file1.go file2.go' MSG='main contradiction'"; exit 1; fi
	bash scripts/workflow/explore.sh $(FILES) "$(MSG)"

checkpoint:
	bash scripts/workflow/checkpoint.sh $(or $(PHASE),execute)

lint-scaffold:
	bash scripts/workflow/lint-scaffold.sh
```

**目标**：所有工作流操作都有 `make xxx` 入口，AI 不需要记脚本路径。

完整 Makefile：
```makefile
.PHONY: help preflight new-task explore checkpoint gate gate-workflow gate-quality resume lint-scaffold validate

help:
	@echo "make preflight | new-task NAME=x LEVEL=M | explore FILES='...' MSG='...' | checkpoint PHASE=execute"
	@echo "make gate | gate-workflow | gate-quality | resume | lint-scaffold | validate"

preflight:       bash scripts/preflight/all.sh
new-task:        bash scripts/workflow/new-task.sh "$(NAME)" "$(or $(LEVEL),M)"
explore:         bash scripts/workflow/explore.sh $(FILES) "$(MSG)"
checkpoint:      bash scripts/workflow/checkpoint.sh $(or $(PHASE),execute)
gate:            bash scripts/gates/all.sh --all
gate-workflow:   bash scripts/gates/all.sh --workflow
gate-quality:    bash scripts/gates/all.sh --quality
resume:          bash scripts/workflow/resume.sh
lint-scaffold:   bash scripts/workflow/lint-scaffold.sh
validate:        bash scripts/validate-config.sh
```

---

### 修复 5：resume.sh 改名为 status.sh

**问题**：`resume` 暗示会自动恢复上下文，但实际只显示状态。

**方案**：
1. `mv scripts/workflow/resume.sh scripts/workflow/status.sh`
2. CLAUDE.md 命令表改 `resume` → `status`
3. Makefile 改 `make resume` → `make status`

**或者**：保留 `resume.sh` 名字，但增加实际恢复逻辑：

```bash
# 在输出状态后，给出具体建议
case "$PHASE" in
    explore)  echo "→ 继续: make explore FILES='...' MSG='...'" ;;
    plan)     echo "→ 继续: 编辑 .planning/tasks/$TASK_ID/plan.md" ;;
    execute)  echo "→ 继续: 按 plan.md 执行，完成后 make gate-quality" ;;
    verify)   echo "→ 继续: make gate --all" ;;
esac
```

**推荐**：保留 `resume.sh` 名字，加上具体恢复建议。

---

### 修复 6：CLAUDE.md §4.2 更新

**问题**：§4.2 还引用 `plan.sh`，但这个脚本要被删除。

**当前**：
```markdown
### 4.2 规划
bash scripts/workflow/plan.sh "task-slug"
bash scripts/gates/G2-verify.sh
```

**改为**：
```markdown
### 4.2 规划

编辑 `new-task` 创建的 `plan.md`，必须包含 Scope/Boundary/Acceptance/Risks/Rollback：

bash scripts/gates/G2-verify.sh
```

---

## 三、执行顺序

| 优先级 | 修复项 | 工作量 | 改动文件 |
|--------|--------|--------|---------|
| **P0** | 修复 1：合并 plan.sh → new-task.sh | 10min | 删除 plan.sh，改 CLAUDE.md §4.2 |
| **P0** | 修复 4：Makefile 补齐 | 10min | Makefile |
| **P1** | 修复 3：G6 检查内容 | 5min | G6-verify.sh |
| **P1** | 修复 5：resume.sh 加恢复建议 | 10min | resume.sh |
| **P2** | 修复 2：verify.ps1 改名 | 10min | 新建 lint-scaffold.sh，改 Makefile |
| **P2** | 修复 6：CLAUDE.md §4.2 | 5min | CLAUDE.md |

**总工作量**：~50 分钟

---

## 四、修复后的理想状态

```
make new-task NAME=auth LEVEL=M     # 创建任务 + 初始化状态
make explore FILES='...' MSG='...'  # 记录探索产物
make gate-workflow                  # 验证 G1-G2（工作流门控）
# 编辑 plan.md
make gate-workflow                  # 再次验证 G2
# 写代码（TDD）
make gate-quality                   # 验证 G3-G7（质量门控）
make checkpoint PHASE=done          # 保存完成状态
make resume                         # 查看状态 + 恢复建议
```

所有操作通过 `make xxx` 完成，不需要记脚本路径。
