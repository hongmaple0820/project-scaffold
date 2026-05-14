# CLAUDE.md

**agent**: claude-code | **format_version**: "2.0" | **type**: machine_executable

---

## 1. 预检（首次启动）

```bash
bash scripts/preflight/all.sh
```

**预检内容**: Go版本、必需工具、MCP服务器、技能安装状态
**失败处理**: 脚本输出安装命令，按提示修复后重试

---

## 2. 命令

```yaml
dev:       { cmd: go run ., timeout: 30s }
build:     { cmd: go build -o bin/app ., timeout: 120s }
test:      { cmd: go test ./... -race, timeout: 300s }
lint:      { cmd: golangci-lint run, timeout: 60s }
coverage:  { cmd: go test -coverprofile=.agent/logs/coverage.out ./..., timeout: 120s }
gate:      { cmd: bash scripts/gates/all.sh, timeout: 600s }
plan:      { cmd: bash scripts/init-plan.sh, env: [NAME] }
checkpoint:{ cmd: bash scripts/workflow/checkpoint.sh, env: [PHASE] }
resume:    { cmd: bash scripts/workflow/resume.sh }
graphify:  { cmd: graphify ., timeout: 300s }
```

---

## 3. 机器可验证门控

| 门控 | 验证脚本 | 自动检查 | 产物 | 失败处理 |
|------|----------|----------|------|---------|
| G1 探索 | `bash scripts/gates/G1-verify.sh` | 否 | `.agent/state/explore.json` | 补充探索 |
| G2 规划 | `bash scripts/gates/G2-verify.sh` | 否 | `docs/plans/YYYY-MM-DD-*/` | 重写规划 |
| G3 TDD | `bash scripts/gates/G3-verify.sh` | 是 | `*_test.go` mtime | 补充测试 |
| G4 Lint | `bash scripts/gates/G4-verify.sh` | 是 | lint exit 0 | 自动修复 |
| G5 Test | `bash scripts/gates/G5-verify.sh` | 是 | test exit 0 | 修复代码 |
| G6 Coverage | `bash scripts/gates/G6-verify.sh` | 是 | ≥80% | 补充测试 |
| G7 Security | `bash scripts/gates/G7-verify.sh` | 条件 | gosec 无 HIGH | 修复漏洞 |

**门控检查真实产物，不检查 AI 声称。** 每个 Gate 验证对应脚本的输出文件是否存在且有效。

### 3.1 技术栈适配

门控 G4-G7 从 `.agent/project.json` 读取命令，不硬编码：

```json
{
  "stack": "auto",
  "coverage_threshold": 80,
  "stacks": {
    "go": {
      "detect": ["go.mod"],
      "commands": {
        "lint": "golangci-lint run",
        "test": "go test ./... -race",
        "coverage": "go test -coverprofile=.agent/logs/coverage.out ./...",
        "security": "gosec ./..."
      }
    }
  }
}
```

生成真实项目后，先检查 `.agent/project.json` 是否匹配当前技术栈；不匹配时先修配置。

---

## 4. 代码规则（正则可验证）

```yaml
R2_no_empty_error:
  severity: enforced
  language: go
  pattern: 'if\s+err\s*!=\s*nil\s*\{\s*(//[^\n]*)?\s*\}'
  message: "禁止空的 error 处理块"
  fix: "添加日志或返回错误"
  auto_check: go vet ./...

R3_no_hardcoded_secret:
  severity: enforced
  language: go
  pattern: '(?i)(password|secret|token|api_key)\s*[=:]\s*["\'][^${}]'
  message: "禁止硬编码密钥"
  fix: "使用 os.Getenv() 或配置中心"
  auto_check: grep -rE '(password|secret|token)\s*=\s*"[^"]+"' --include="*.go" .

R4_context_timeout:
  severity: recommended
  language: go
  pattern: 'http\.(Get|Post|Do)\('
  message: "外部调用需设置 context 超时"
  fix: "使用 http.NewRequestWithContext"
```

---

## 5. 认知工作流（M/L 级必须遵循）

```
探索 → 规划(🛑L级确认) → 执行(TDD) → 验证(工具) → 沉淀(泛化)
```

### 5.1 任务分级

- **S级**（≤30行/typo）：直接做
- **M级**（30-200行/2-5文件）：走工作流
- **L级**（≥200行/跨模块/架构）：完整流程 + **人工确认后再执行**

**模式**: SANDBOX(原型) → STANDARD(默认) → CRITICAL(生产)
**自动升级**: auth/payment→STANDARD | DROP/ALTER→CRITICAL | .env/secret→阻断

### 5.2 Step 1: 探索

**禁止上来就写代码。必须先摸清上下文。**

```
1. 读 CLAUDE.md → 了解项目约定
2. 读知识图谱 → 了解架构骨架（若有 graphify-out/GRAPH_REPORT.md）
3. 扫相关代码 → 理解现有实现
4. 矛盾分析 → 识别主要矛盾
```

**完成探索后，运行自动化脚本记录产物：**
```bash
# 记录探索结果（自动写入 .agent/state/explore.json）
bash scripts/workflow/explore.sh "file1.go" "file2.go" "main contradiction"
```

### 5.3 Step 2: 规划

**基于探索结果制定方案，不可凭空规划。**

```
1. 影响面推理 → 此变更影响哪些模块？依赖方有哪些？
2. 契约定义 → 功能边界 + 异常契约（至少3种）+ 回滚方案
3. M级: 输出 Mini-Spec（需求+边界+验收标准）
4. L级: 采用 SDD 三层产物（spec.md + plan.md + tasks.md）
```

**完成规划后，运行自动化脚本创建产物：**
```bash
# 创建计划目录（自动创建 docs/plans/YYYY-MM-DD-{name}/）
bash scripts/workflow/plan.sh "feature-name"
```

**⚠️ L级任务必须在此暂停！输出方案，询问"是否确认？"，未经确认禁止进入 Step 3。**

### 5.4 Step 3: 执行

**契约确认后，严格按方案编码。**

```
1. TDD 闭环（CRITICAL必须，STANDARD推荐）
   RED: 先写测试 → GREEN: 写主逻辑 → REFACTOR: 重构
2. 防御性编码 → 所有外部调用必须包裹错误处理
3. 安全自检 → SQL注入？XSS？越权？敏感数据泄露？
```

**每个阶段切换时，保存检查点：**
```bash
# 保存当前状态（自动写入 .agent/state/current.json）
bash scripts/workflow/checkpoint.sh execute
```

### 5.5 Step 4: 验证

**验证只能由工具完成，不可脑补。**

```
1. 声称完成前，必须过 5 步门控：
   ① 确定验证命令 ② 实际运行 ③ 完整阅读输出 ④ 确认结果 ⑤ 此时才能声称完成
2. 代码修改后立即运行 lint + 类型检查
3. 运行单元测试，覆盖 Happy Path 和异常路径
```

**运行门控验证：**
```bash
# 运行全部门控（G3-G7）
bash scripts/gates/all.sh
```

### 5.6 Step 5: 沉淀

**代码写完不等于交付，必须闭环。**

```
1. 泛化检查 → 修了一个 bug？同模块有没有同类问题？
2. 文档更新 → 踩坑经验追加到项目知识文档
3. 图谱更新 → 若使用 graphify，运行 graphify . --update
4. 经验提取 → 将可复用的调试知识提取为技能文件
```

### 5.7 状态机

```yaml
workflow_states:
  idle:
    entry: []
    exit: [checkpoint]
    next: [explore]

  explore:
    entry: [load_graphify, read_claude_md]
    exit: [bash scripts/workflow/explore.sh]
    gate: G1
    next: [plan]

  plan:
    entry: [load_requirements]
    exit: [bash scripts/workflow/plan.sh]
    gate: G2
    human_confirm: true  # L级必须暂停确认
    next: [execute]

  execute:
    entry: [load_tdd_state]
    exit: [bash scripts/workflow/checkpoint.sh execute]
    gate: G3
    next: [verify]

  verify:
    entry: [run_lint, run_test]
    exit: [bash scripts/gates/all.sh]
    gates: [G4, G5, G6]
    next: [consolidate]

  consolidate:
    entry: [generalize_check]
    exit: [update_docs, update_graphify]
    next: [idle]
```

---

## 6. 状态管理与断点恢复

```bash
# 保存当前状态
bash scripts/workflow/checkpoint.sh {phase}

# 恢复上次状态
bash scripts/workflow/resume.sh

# 查看状态
cat .agent/state/current.json
```

状态格式：
```json
{
  "timestamp": "ISO8601",
  "phase": "execute",
  "completed_gates": ["G1", "G2", "G3"],
  "open_tasks": ["实现Login接口"],
  "files_modified": ["internal/auth/login.go"]
}
```

**断点恢复**：会话中断时，运行 `resume.sh` 自动检测上次状态，询问继续/重置/审查。

---

## 7. 技能清单

### 7.1 必需技能

```yaml
superpowers:
  version: "2.1.0"
  install: |
    git clone --depth 1 --branch v2.1.0 \
      https://github.com/obra/superpowers.git \
      ~/.claude/skills/superpowers 2>/dev/null || true
  verify: test -f ~/.claude/skills/superpowers/installed.flag
  provides: brainstorming, writing-plans, tdd-guide, systematic-debugging

graphify:
  version: "latest"
  install: pip install graphifyy && graphify install
  verify: command -v graphify >/dev/null 2>&1
  provides: 知识图谱构建、依赖分析、架构可视化
```

### 7.2 推荐技能

```yaml
oh-my-claudecode:
  install: npm install -g oh-my-claude-sisyphus && omc setup
  provides: 多Agent编排、任务并行、自动规划
```

### 7.3 内置 Agent

```yaml
go-reviewer:       { trigger: after_file_write *.go }
security-reviewer:  { trigger: before_commit }
doc-updater:        { trigger: on_demand }
```

---

## 8. MCP 服务器

```json
{
  "memory":            { "command": "npx", "args": ["-y", "@modelcontextprotocol/server-memory"] },
  "filesystem":        { "command": "npx", "args": ["-y", "@anthropic/mcp-filesystem", "."] },
  "context7":          { "command": "npx", "args": ["-y", "@upstash/context7-mcp"] },
  "fetch":             { "command": "npx", "args": ["-y", "@modelcontextprotocol/server-fetch"] },
  "sequential-thinking":{ "command": "npx", "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"] }
}
```

---

## 9. Hooks

**PreToolUse**:
- 危险文件拦截（.env/secret/credential）→ 阻断
- TDD 合规提醒（实现缺少测试时警告）→ 提醒
- 工作流前置检查（写 .go 前自动检查探索产物）→ 阻断或通过

**PostToolUse**:
- gofmt 自动格式化

**Stop**:
- 检查未提交的 .go 改动，提醒 git commit

---

## 10. 红线

| 红线 | 检测 | 级别 |
|------|------|------|
| R1 零数据丢失 | `bash scripts/redlines/R1-check.sh` | block |
| R2 零静默失败 | `bash scripts/redlines/R2-check.sh` | block |
| R3 零硬编码密钥 | `bash scripts/redlines/R3-check.sh` | block |
| R4 零幻觉 | 标注 `[UNCERTAIN]` | review |
| R5 零甩锅 | 归因前必须验证 | review |
| R6 零未审操作 | Hook 拦截 | confirm |

---

## 11. 规范索引

| 文档 | 路径 |
|------|------|
| 通用规范 | [docs/standards/common/](docs/standards/common/) |
| 项目规范 | [docs/standards/projects/PROJECT_SPEC.md](docs/standards/projects/PROJECT_SPEC.md) |
| 架构 | [docs/architecture/OVERVIEW.md](docs/architecture/OVERVIEW.md) |
| 开发流程 | [docs/guides/DEVELOPMENT_WORKFLOW.md](docs/guides/DEVELOPMENT_WORKFLOW.md) |
| 技能安装 | [docs/skills/INSTALL.md](docs/skills/INSTALL.md) |

---

**验证**: `bash scripts/validate-config.sh` | **状态**: `cat .agent/state/current.json`

<!-- MACHINE_EXECUTABLE: true -->
