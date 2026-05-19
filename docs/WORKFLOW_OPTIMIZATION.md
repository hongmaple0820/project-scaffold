# 工作流优化方案 — 基于实战测试的改进

> **来源**：将 project-scaffold 应用到 amdox-go-netdisk（245 Go文件微服务项目）的完整实测
> **核心原则**：不是砍内容，是加执行力。内容告诉 AI 该做什么，脚本让步骤真正被执行。

---

## 一、问题诊断

### 实测暴露的 5 个核心问题

| # | 问题 | 实测表现 | 根因 |
|---|------|---------|------|
| 1 | **Gate 检查假状态** | G1 检查 `.agent/state/explore.json`，但 AI 从不写这个文件 | 门控依赖 AI 主动写状态文件，没有自动化脚本帮它写 |
| 2 | **工作流无执行路径** | CLAUDE.md 写了"必须先探索"，但没有 explore.sh 让 AI 运行 | 有规则无工具，规则无法执行 |
| 3 | **Hook 效果弱** | check-context.sh 每次写 .go 都警告，变成噪声 | 告警太多 AI 学会忽略，没有区分 S/M/L 级任务 |
| 4 | **状态机无落脚点** | 状态机 YAML 定义了 idle→explore→plan，但没有对应脚本 | 理论设计无执行路径 |
| 5 | **全局配置噪声** | 350 技能 + 6000 行规则同时加载，大部分与项目无关 | 全局配置未按项目过滤 |

### 一句话总结

**问题不是规则太多，是规则没有执行引擎。** CLAUDE.md 写了"先探索再写代码"，但没有 explore.sh 让 AI 运行，没有 Hook 检查是否运行过，没有 Gate 验证产出。

---

## 二、优化方案

### 核心思路：内容 + 执行 + 检查

```
内容（CLAUDE.md）→ 告诉 AI 该做什么
  ↓
执行（自动化脚本）→ 让 AI 运行脚本产出真实产物
  ↓
检查（Gate + Hook）→ 验证产物存在且有效
```

三者缺一不可：
- 只有内容 → AI 知道但不做（现状）
- 只有脚本 → AI 不知道要运行
- 只有检查 → AI 被阻断但不知道怎么过

---

### 优化 1：工作流自动化脚本（新增）

**问题**：CLAUDE.md 写了"先探索再写代码"，但没有工具让 AI 执行"探索"这个步骤。

**方案**：为工作流每个关键步骤创建自动化脚本，AI 运行脚本产出真实产物。

| 脚本 | 用途 | 产物 |
|------|------|------|
| `scripts/workflow/explore.sh` | 记录探索结果 | `.agent/state/explore.json` |
| `scripts/workflow/plan.sh` | 创建计划目录 | `.planning/tasks/YYYY-MM-DD-{name}/` |
| `scripts/workflow/checkpoint.sh` | 保存工作流状态 | `.agent/state/current.json` |
| `scripts/workflow/resume.sh` | 恢复上次状态 | 读取 current.json |

**explore.sh 用法**：
```bash
# AI 探索完代码后运行，记录读过的文件和主要矛盾
bash scripts/workflow/explore.sh "internal/logic/user.go" "internal/model/user.go" "用户认证与驱动层耦合"
```

**产出**（Gate 检查的真实文件）：
```json
{
  "timestamp": "2026-05-14T10:30:00Z",
  "files": ["internal/logic/user.go", "internal/model/user.go"],
  "file_count": 2,
  "main_contradiction": "用户认证与驱动层耦合",
  "graphify_read": true,
  "graph_nodes": 2161
}
```

**plan.sh 用法**：
```bash
# AI 规划完后运行，创建计划目录和模板文件
bash scripts/workflow/plan.sh "user-auth-refactor"
```

**产出**（Gate 检查的真实目录）：
```
.planning/tasks/2026-05-14-user-auth-refactor/
├── spec.md    ← WHAT（用户故事 + 验收标准）
├── plan.md    ← HOW（技术选型 + 数据模型）
└── tasks.md   ← DO（原子任务列表）
```

---

### 优化 2：Gate 检查脚本产出的真实产物

**问题**：G1 检查 `.agent/state/explore.json`，但这个文件从未被创建。

**方案**：Gate 检查自动化脚本产出的产物，而非 AI 声称的状态。

| Gate | 检查什么 | 产物来源 |
|------|---------|---------|
| G1 探索 | `explore.json` 存在 + ≥3 文件 + 主要矛盾 | `explore.sh` 产出 |
| G2 规划 | `.planning/tasks/YYYY-MM-DD-*/plan.md` 存在 + 含边界/异常/回滚 | `plan.sh` 产出 |
| G3 TDD | `*_test.go` mtime ≤ 实现文件 mtime | Git 记录 |
| G4 Lint | `golangci-lint run` exit 0 | 命令输出 |
| G5 Test | `go test ./... -race` exit 0 | 命令输出 |
| G6 Coverage | 覆盖率 ≥ 80% | 命令输出 |
| G7 Security | `gosec ./...` 无 HIGH/CRITICAL | 命令输出 |

**G1 改写核心逻辑**：
```bash
# 检查 explore.sh 产出的真实文件
if [ ! -f "$EXPLORE_FILE" ]; then
    echo "[G1] ❌ 缺少探索记录"
    echo "运行: bash scripts/workflow/explore.sh file1.go file2.go '矛盾'"
    exit 1
fi
FILE_COUNT=$(jq '.file_count' "$EXPLORE_FILE")
# ... 验证 file_count ≥ 3, main_contradiction 非空
```

**关键区别**：
- 之前：Gate 检查 AI 是否"声称"完成了探索 → 形同虚设
- 现在：Gate 检查 explore.json 文件是否存在且有效 → 真实阻断

---

### 优化 3：Hook 接入自动化脚本

**问题**：AI 不会主动运行 explore.sh——它会直接写代码。

**方案**：PreToolUse Hook 在 AI 写 .go 文件前自动检查探索产物。如果 explore.json 不存在，提醒 AI 先运行 explore.sh。

**check-explore.sh**（新增 Hook）：
```bash
#!/bin/bash
# 写 .go 文件前检查探索产物
EXPLORE_FILE="$PROJECT_ROOT/.agent/state/explore.json"

if [ ! -f "$EXPLORE_FILE" ]; then
    echo "╔══════════════════════════════════════════════╗"
    echo "║  [WORKFLOW] 尚未完成探索阶段                      ║"
    echo "║  运行: bash scripts/workflow/explore.sh ...    ║"
    echo "╚══════════════════════════════════════════════╝"
    exit 0  # 警告不阻断（S级任务可直接做）
fi
```

**Hook 配置**（settings.json）：
```json
{
  "PreToolUse": [
    {
      "matcher": "Write *.go|Edit *.go",
      "command": "bash scripts/hooks/check-explore.sh",
      "description": "写.go前检查探索产物（工作流前置门控）"
    },
    {
      "matcher": "Write|Edit",
      "command": "bash scripts/hooks/check-dangerous-file.sh",
      "description": "拦截危险文件修改"
    },
    {
      "matcher": "Write *.go",
      "command": "bash scripts/hooks/check-tdd.sh",
      "description": "TDD合规提醒"
    }
  ]
}
```

**执行链**：
```
AI 收到任务 → 想写 .go 文件
  → Hook 触发: check-explore.sh
  → explore.json 不存在
  → Hook 输出: "尚未完成探索阶段，运行 explore.sh"
  → AI 运行: bash scripts/workflow/explore.sh file1.go file2.go
  → 产出: .agent/state/explore.json
  → AI 再次写 .go 文件
  → Hook 触发: check-explore.sh
  → explore.json 存在 ✅
  → 代码写入成功
```

---

### 优化 4：状态机 + 自动化脚本绑定

**问题**：状态机 YAML 定义了状态转换，但没有对应的执行脚本。

**方案**：状态机的每个 exit 节点绑定一个自动化脚本。

```yaml
workflow_states:
  explore:
    entry: [load_graphify, read_claude_md]
    exit: [bash scripts/workflow/explore.sh]    # ← 绑定脚本
    gate: G1
    next: [plan]

  plan:
    entry: [load_requirements]
    exit: [bash scripts/workflow/plan.sh]        # ← 绑定脚本
    gate: G2
    human_confirm: true
    next: [execute]

  execute:
    entry: [load_tdd_state]
    exit: [bash scripts/workflow/checkpoint.sh]  # ← 绑定脚本
    gate: G3
    next: [verify]

  verify:
    entry: [run_lint, run_test]
    exit: [bash scripts/gates/all.sh]            # ← 绑定脚本
    gates: [G4, G5, G6]
    next: [consolidate]
```

**关键区别**：
- 之前：状态机是文档，AI 从不引用
- 现在：状态机的每个步骤对应一个可执行脚本，脚本产出 Gate 检查的产物

---

### 优化 5：Hook 消噪

**问题**：Hook 警告太多变成噪声。

**方案**：

| Hook | 之前 | 之后 |
|------|------|------|
| check-context.sh | 每次写 .go 都警告 | **删除**（噪声） |
| check-tdd.sh | 每次写 .go 都警告 | **保留**（有用的真检查） |
| Stop hook | 运行全部门控（120s） | **只检查未提交改动**（5s） |
| session-start | 30 行论文式提醒 | **1 行极简提示** |

**消噪规则**：
1. Hook 每会话最多输出 1 次关键提醒
2. 提醒类用 `exit 0`，阻断类用 `exit 2`
3. 输出不超过 3 行

---

### 优化 6：全局配置精简

**问题**：350 技能 + 6000 行规则同时加载。

**方案**：

| 配置 | 之前 | 之后 | 方法 |
|------|------|------|------|
| `~/.claude/CLAUDE.md` | 959 行 | 113 行 | SCALE OS 详细版 → 精简速查版 |
| `~/.claude/rules/zh/` | 572 行 | 0 | 与 common/ 重复，归档 |
| `~/.claude/rules/{12种语言}` | 4586 行 | 0 | 按项目需要只保留对应语言 |
| `~/.claude/skills/gsd-*` | 81 个 | 0 | OMC 自动安装，归档 |
| `~/.claude/skills/baoyu-*` | 17 个 | 0 | 内容创作，归档 |

**归档而非删除**：`~/.claude/rules-archive/` 和 `~/.claude/skills-archive/`，需要时 mv 回来。

---

## 三、最终状态

### project-scaffold（产品模板）

| 维度 | 优化前 | 优化后 |
|------|--------|--------|
| CLAUDE.md | 523 行 | **365 行**（恢复工作流+状态机+技能+新增自动化脚本调用） |
| 自动化脚本 | 0 | **4 个**（explore/plan/checkpoint/resume） |
| Hooks | 18 个（含 inline node.js） | **5 个**（探索检查+危险文件+TDD+格式化+未提交检查） |
| Gate G1 | 检查假状态文件 | **检查 explore.sh 产出的真实 explore.json** |

### amdox-go-netdisk（实测项目）

| 维度 | 优化前 | 优化后 |
|------|--------|--------|
| CLAUDE.md | 685 行 | **200 行**（+工作流自动化段落） |
| 自动化脚本 | 0 | **4 个** |
| Hooks | 4 个（假状态机） | **5 个**（+探索检查） |
| 全局 CLAUDE.md | 959 行 | **113 行** |
| 全局 rules | 5,962 行 | **804 行** |

---

## 四、验证方法

### 1. Gate 真实阻断测试

```bash
# 故意跳过探索，直接写代码
# 预期：Hook 提醒"尚未完成探索阶段"
# 运行 gate：G1 应报错"缺少探索记录"
```

### 2. 自动化脚本产物验证

```bash
# 运行 explore.sh
bash scripts/workflow/explore.sh "file1.go" "file2.go" "主要矛盾"
# 验证产物
cat .agent/state/explore.json
# 运行 gate
bash scripts/gates/G1-verify.sh
# 预期：✅ 探索阶段验证通过
```

### 3. 完整工作流测试

```bash
# Step 1: 探索
bash scripts/workflow/explore.sh "internal/logic/user.go" "internal/model/user.go" "认证耦合"
# Step 2: 规划
bash scripts/workflow/plan.sh "user-auth"
# Step 3: 检查点
bash scripts/workflow/checkpoint.sh execute
# Step 4: Gate
bash scripts/gates/all.sh
# Step 5: 恢复
bash scripts/workflow/resume.sh
```

---

## 五、关键教训

1. **内容 + 执行 + 检查，三者缺一不可** — 只写规则不加脚本，规则无法执行
2. **自动化脚本 = 工作流的执行引擎** — explore.sh 让"先探索"从口号变成可执行命令
3. **Gate 检查脚本产物，不检查 AI 声称** — explore.json 存在 ≠ AI 声称探索过
4. **Hook 是触发器，不是执行器** — Hook 提醒 AI 运行脚本，不是替代脚本
5. **消噪比加规则更重要** — 删除 check-context.sh（噪声）比加 10 条规则更有效
6. **全局配置按项目过滤** — Go 项目不需要 Dart/Java/Rust 规则
7. **归档而非删除** — `rules-archive/` 和 `skills-archive/` 保留回退能力
