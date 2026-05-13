# AGENTS.md

## Agent 操作规则

本仓库是 Agent-First 工程化脚手架。任何 agent 在本仓库工作时必须遵守以下规则。

---

## §0 核心元认知（不可逾越）

### 0.1 认知诚实
- 不确定时，输出 `[UNCERTAIN]` 并说明缺失什么
- 未实际运行验证，绝不允许输出"通过"
- 不编造未在代码中定义的调用关系

### 0.2 显性推理
在采取任何非平凡动作前，在 `<think reasoning="effort">` 中展示：
- 影响面分析
- 抓主要矛盾
- 权衡方案
- 前置异常思考

### 0.3 Owner 意识
- 做A + 检查B同类问题 + 确保不影响C
- 一个bug进来，一类问题出去
- 做超出用户要求的有价值工作时，标记 `[OWNER 🔥]`

### 0.4 反惰性警觉（强制）

**5 大懒惰模式——必须时刻自检**：

| 模式 | 表现 | 反制 |
|------|------|------|
| 🔄 暴力重试 | 连续 3 次同命令失败 | Hook 阻断 + 必须换策略 |
| 🤷 甩锅用户 | "建议手动"/"环境问题"/"需要更多信息" | 输出 `[SHOVELING]` → Hook 阻断 |
| 🛌 工具闲置 | 有工具不调用 | 穷尽工具后才能放弃 |
| 🎭 忙碌假象 | 修改同一行无新信息 | Hook 阻断 + 停下来换思路 |
| 😴 被动等待 | 修完就停不泛化 | Stop Hook 阻断 + 必须泛化检查 |

**甩锅前必须验证**：
- 声称"环境问题" → 必须有环境验证证据
- 声称"需要更多信息" → 必须先穷尽已有信息源
- 未验证的归因 = 甩锅 → Hook 阻断

### 0.5 技能优先意识

**1% 规则**：如果某个已安装的技能有 1% 的可能与当前任务相关，必须调用它。

---

## §1 任务分级

| 级别 | 场景 | 行动 |
|------|------|------|
| **S级** | 改typo/加日志/≤30行 | 直接输出代码 |
| **M级** | 新API/修Bug/30-200行 | 执行认知工作流 |
| **L级** | 跨模块/架构/≥200行 | 工作流+人工确认点 |

---

## §2 质量门控

| 门控 | 触发条件 | 验证方式 |
|------|----------|----------|
| **G1 技能扫描** | 会话开始 | 必须输出 `[SKILL SCAN]` |
| **G2 探索完成** | Read ≥3 文件 | 必须输出 `[EXPLORE]` |
| **G3 规划完成** | L级任务 | 必须输出 `[PLAN]` + 人工确认 |
| **G4 TDD合规** | M/L级 | 测试文件先于实现文件 |
| **G5 代码规范** | 任何修改 | `make lint` |
| **G6 功能正确** | 任何修改 | `make test` + `make coverage` |
| **G7 安全检查** | 涉及敏感代码 | 无硬编码密钥、无 SQL 拼接 |

---

## §3 认知工作流（M/L级必须）

### 3.1 强制机制

**门控节点**：

| 节点 | 类型 | 检查内容 | 拦截行为 |
|------|------|----------|----------|
| 会话开始 | P1提醒 | 输出技能清单提示 | 软提醒 |
| Write/Edit 代码前 | **P0硬阻断** | SKILL_SCAN + EXPLORE + PLAN | `exit 2` |
| 声称完成前 | **P0硬阻断** | VERIFY 标记 | `exit 2` |
| 会话结束前 | **P0硬阻断** | 5 阶段全完成 + 无污染 | `exit 2` |

### 3.2 输出规范（必须遵守）

每个阶段完成时，输出结构化日志：

```
[阶段名] ✓ 检查项1 ✓ | 检查项2 ✓ | ...
```

**完整示例**：
```
[SKILL SCAN] ✓ brainstorming ✓ | tdd ✓ | verification ✓
[EXPLORE] ✓ CLAUDE.md ✓ | 图谱 ✓ | 技能 ✓ | 矛盾分析 ✓
[PLAN] ✓ 影响面: A/B/C ✓ | 契约定义 ✓ | 无L级暂停
[EXECUTE] ✓ TDD RED ✓ | GREEN ✓ | REFACTOR ✓
[VERIFY] ✓ Lint ✓ | Test ✓ | Coverage 85% ✓ | Security ✓
[SETTLE] ✓ 泛化 ✓ | 文档 ✓ | 经验 ✓
```

### 3.3 五阶段详细步骤

#### Step 1：探索研究 📡

```
1. 知识锚定 → 读取 CLAUDE.md + README.md
2. 技能扫描 → 检查 ~/.claude/skills/ + 项目技能配置
3. 矛盾分析 → 抓主要矛盾
4. 图谱检查 → graphify-out/GRAPH_REPORT.md（如有）
5. 历史检查 → 检查相关日志和状态
```

**输出**: `[EXPLORE] ✓ 检查项 ✓ | ...`

#### Step 2：规划决策 📋

```
1. 需求精炼 → 调用 brainstorming 技能
2. 影响面推理 → 分析模块依赖
3. 契约定义 → 功能边界 + 异常契约 + 回滚方案
4. 工具选型 → 判断是否需要特定技能
```

**输出**: `[PLAN] ✓ 检查项 ✓ | ...`

**⚠️ L级任务必须在此暂停询问："探索完毕，此为执行方案，是否确认？"**

#### Step 3：执行实施 🔨

```
1. TDD 闭环 → RED(先写测试) → GREEN(写实现) → REFACTOR
2. 防御性编码 → 外部调用包裹异常处理
3. 安全自检 → SQL注入？XSS？硬编码密钥？
4. 代码规范 → make lint + make fmt
```

**输出**: `[EXECUTE] ✓ 检查项 ✓ | ...`

#### Step 4：验证测试 ✅

```
1. 确定验证命令 → make lint / make test / make coverage
2. 实际运行 → 必须执行
3. 完整阅读输出 → 不要跳读
4. 确认结果 → 与预期一致
5. 声称完成 → 此时才能说完成
```

**输出**: `[VERIFY] ✓ 检查项 ✓ | ...`

#### Step 5：沉淀优化 📈

```
1. 泛化检查 → 同模块同类问题？
2. 文档更新 → 更新 CLAUDE.md / README.md
3. 经验提取 → 可复用知识写入技能文件
```

**输出**: `[SETTLE] ✓ 检查项 ✓ | ...`

---

## §4 绝对红线

| 红线 | 定义 |
|------|------|
| **R1 零数据丢失** | Schema 变更必须有回滚 SQL |
| **R2 零静默失败** | 禁止空 catch，异常必须显式处理 |
| **R3 零硬编码密钥** | 敏感信息走环境变量 |
| **R4 零幻觉** | 不确定标 `[UNCERTAIN]`，验证只能工具完成 |
| **R5 零甩锅** | 归因前必须验证 |
| **R6 零未审关键操作** | DB/权限/生产变更必须人工确认 |

---

## §5 启动检查

- 先读取 `CLAUDE.md`、`README.md` 和相关 `docs/standards/` 文件。
- 修改前先定位现有结构、脚本和约定，不要凭记忆猜测。
- 如果任务涉及代码行为，先找对应测试或验证命令。

### 工具与验证

- 优先使用仓库脚本：`bash scripts/validate-config.sh`、`bash scripts/gates/all.sh --dry-run`、`make gate`。
- 声称完成前必须运行与变更相关的最小验证命令。
- 如果工具缺失、脚本失败或环境不支持，必须在最终回复中列为"未验证项"。
- 不得把跳过、不适用或工具缺失描述为"通过"。

### 反幻觉与诚实交付

- 不确定事实必须标注 `[UNCERTAIN]`。
- 引用项目事实必须来自已读取文件、命令输出或测试结果。
- 禁止编造文件、配置、命令输出、测试结果、外部依赖行为。
- 最终回复必须列出完成内容、验证结果、未验证项。

### 文件规范

- Shell 脚本必须使用 LF 换行。
- JSON 修改后必须能被解析。
- 不要写入 `.env*`、密钥、证书、token、credential、password、private key 文件，除非用户明确要求且完成风险说明。

---

## OVERVIEW

Project scaffold for Agent-First engineering. Contains **机器可执行** CLAUDE.md format, quality gates (G1-G7), state management, and skill integration.

## STRUCTURE

```
./
├── .claude/hooks/           # Cognitive workflow enforcement hooks
├── .claude/session/         # Flow state tracking
├── scripts/hooks/           # Project-specific hooks (dangerous files, TDD, context)
├── scripts/gates/           # Quality gates (G1-G7)
├── scripts/redlines/        # Red line checks (R1-R3)
├── scripts/preflight/       # Environment preflight checks
├── scripts/checkpoint/      # State save/resume
├── graphify-out/            # Knowledge graph output (optional)
├── .agent/state/            # Project state management
├── docs/standards/          # Standards documentation
├── docs/skills/             # Skill manuals
└── templates/               # Project templates
```

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Quality gates | `scripts/gates/*.sh` | G1-G7 verification scripts |
| Red line checks | `scripts/redlines/*.sh` | R1-R3 machine-checkable |
| Hooks config | `.claude/settings.json` | PreToolUse/PostToolUse/Stop |
| Flow state | `.claude/session/.flow-state` | Cognitive workflow tracking |
| Commands | `Makefile` | dev/build/test/lint/gate/graphify |

## CONVENTIONS

- **Hooks**: LF line endings, exit 0=pass, exit 2=block
- **Gates**: All gates must pass before claiming completion
- **State**: `.flow-state` tracks SKILL_SCAN/EXPLORE/PLAN/EXECUTE/VERIFY/SETTLE