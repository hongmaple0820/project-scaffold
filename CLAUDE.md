# CLAUDE.md

**agent**: claude-code  
**format_version**: "2.0"  
**type**: machine_executable  
**project**: project-scaffold  

---

## 1. 预检要求（首次启动必执行）

```bash
# 运行预检脚本验证环境
bash scripts/preflight/all.sh
```

**预检内容**: Go版本、必需工具、MCP服务器、技能安装状态  
**失败处理**: 脚本输出安装命令，按提示修复后重试

---

## 2. 机器可执行命令

### 2.1 开发命令

```yaml
dev:
  cmd: go run .
  verify: bash -c 'sleep 2 && curl -s http://localhost:8080/health | grep -q "ok"'
  timeout: 30s
  retry: 3
  
build:
  cmd: go build -o bin/app .
  verify: test -x bin/app && ./bin/app --version 2>/dev/null | grep -q "v"
  timeout: 120s
  
test:
  cmd: go test ./... -race -json > .agent/logs/test.json 2>&1
  verify: bash scripts/gates/G5-verify.sh
  timeout: 300s
  
lint:
  cmd: golangci-lint run --out-format=json > .agent/logs/lint.json 2>&1
  verify: bash scripts/gates/G4-verify.sh
  timeout: 60s
  
coverage:
  cmd: go test -coverprofile=.agent/logs/coverage.out ./...
  verify: bash scripts/gates/G6-verify.sh
  timeout: 120s
```

### 2.2 知识图谱命令

```yaml
graphify:
  cmd: graphify .
  verify: test -d graphify-out/
  timeout: 300s
  description: "构建代码知识图谱，用于架构分析"
  
graph-query:
  cmd: graphify query
  verify: true
  description: "查询代码依赖关系"
```

### 2.3 项目管理命令

```yaml
gate:
  cmd: bash scripts/gates/all.sh
  verify: test $? -eq 0
  timeout: 600s
  
plan:
  cmd: bash scripts/init-plan.sh
  verify: test -d "docs/plans/$(date +%Y-%m-%d)-${NAME}"
  required_env: [NAME]
  
checkpoint:
  cmd: bash scripts/checkpoint/save.sh
  verify: test -f .agent/state/current.json
  
resume:
  cmd: bash scripts/checkpoint/resume.sh
  verify: jq -e '.current_phase' .agent/state/current.json
```

---

## 3. 机器可验证门控

| 门控 | 验证脚本 | 自动检查 | 失败回滚 |
|------|----------|----------|----------|
| **G1_explore** | `scripts/gates/G1-verify.sh` | 否 | 补充探索 |
| **G2_plan** | `scripts/gates/G2-verify.sh` | 否 | 重写规划 |
| **G3_tdd** | `scripts/gates/G3-verify.sh` | 是 | 补充测试 |
| **G4_lint** | `scripts/gates/G4-verify.sh` | 是 | 自动修复 |
| **G5_test** | `scripts/gates/G5-verify.sh` | 是 | 修复代码 |
| **G6_coverage** | `scripts/gates/G6-verify.sh` | 是 | 补充测试 |
| **G7_security** | `scripts/gates/G7-verify.sh` | 条件触发 | 修复安全问题 |

---

## 3.1 技术栈适配配置

门控 G4-G7 从 `.agent/project.json` 读取技术栈和命令，不应在脚本中硬编码项目命令。

```json
{
  "stack": "auto",
  "coverage_threshold": 80,
  "stacks": {
    "go": {
      "detect": ["go.mod"],
      "commands": {
        "lint": "golangci-lint run --out-format=json > .agent/logs/lint.json",
        "test": "go test ./... -race -json > .agent/logs/test.json",
        "coverage": "go test -coverprofile=.agent/logs/coverage.out ./...",
        "security": "gosec -fmt json -out .agent/logs/gosec.json ./... >/dev/null"
      }
    }
  }
}
```

生成真实项目后，Agent 必须先检查 `.agent/project.json` 是否匹配当前技术栈；不匹配时先修配置，再运行门控。

---

## 4. 技能清单（命令+验证+版本）

### 4.1 必需技能

```yaml
superpowers:
  version: "2.1.0"
  install: |
    git clone --depth 1 --branch v2.1.0 \
      https://github.com/obra/superpowers.git \
      ~/.claude/skills/superpowers 2>/dev/null || true
    touch ~/.claude/skills/superpowers/installed.flag
  verify: test -f ~/.claude/skills/superpowers/installed.flag
  rollback: rm -rf ~/.claude/skills/superpowers
  
graphify:
  version: "latest"
  install: |
    pip install graphifyy 2>/dev/null || pip3 install graphifyy
    graphify install
  verify: command -v graphify >/dev/null 2>&1
  rollback: pip uninstall -y graphifyy
  description: "代码知识图谱，用于架构理解和依赖分析"
```

### 4.2 推荐技能

```yaml
oh-my-claudecode:
  version: "latest"
  install: |
    npm install -g oh-my-claude-sisyphus 2>/dev/null || true
    omc setup
  verify: command -v omc >/dev/null 2>&1
  rollback: npm uninstall -g oh-my-claude-sisyphus
```

### 4.3 内置Agent

```yaml
go-reviewer:
  type: builtin
  trigger: after_file_write *.go
  
security-reviewer:
  type: builtin
  trigger: before_commit
  
doc-updater:
  type: builtin
  trigger: on_demand
```

---

## 5. MCP服务器（完整配置）

```json
{
  "memory": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-memory"],
    "verify": "test -S /tmp/mcp-memory.sock || true"
  },
  "filesystem": {
    "command": "npx",
    "args": ["-y", "@anthropic/mcp-filesystem", "."],
    "verify": "true"
  },
  "context7": {
    "command": "npx",
    "args": ["-y", "@upstash/context7-mcp"],
    "verify": "curl -s http://localhost:3000/health 2>/dev/null | grep -q ok || true"
  },
  "fetch": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-fetch"],
    "verify": "true"
  },
  "sequential-thinking": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"],
    "verify": "true"
  }
}
```

---

## 6. 代码规则（正则可验证）

### 6.1 Go语言规则

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

## 7. 状态管理与断点恢复

### 7.1 自动保存点

```yaml
checkpoint:
  dir: .agent/state/
  auto_save: true
  triggers:
    - phase_change
    - gate_pass
    - every_10_minutes
    
  fields:
    - current_phase: string
    - completed_gates: []string
    - open_tasks: []string
    - last_action: string
    - timestamp: iso8601
    - files_modified: []string
```

### 7.2 恢复流程

```bash
# 检测状态
if [ -f .agent/state/current.json ]; then
  PHASE=$(jq -r '.current_phase' .agent/state/current.json)
  echo "[RESUME] 检测到之前的状态: $PHASE"
  
  # 显示上下文
  jq '.open_tasks | join(", ")' .agent/state/current.json
  
  # 询问继续方式
  # Agent根据上下文决定：继续/重置/审查
fi
```

### 7.3 状态机定义

```yaml
workflow_states:
  idle:
    entry: []
    exit: [checkpoint]
    next: [explore]
    
  explore:
    entry: [load_graphify]
    exit: [save_explored_files]
    gate: G1
    next: [plan]
    
  plan:
    entry: [load_requirements]
    exit: [save_plan]
    gate: G2
    human_confirm: true
    next: [execute]
    
  execute:
    entry: [load_tdd_state]
    exit: [save_test_results]
    gate: G3
    next: [verify]
    
  verify:
    entry: [run_lint, run_test]
    exit: [save_coverage]
    gates: [G4, G5, G6]
    next: [consolidate]
    
  consolidate:
    entry: [generalize_check]
    exit: [update_skills, update_docs]
    next: [idle]
```

---

## 8. Hooks（自动化触发）

### 8.1 PreToolUse

```yaml
block_dangerous_files:
  trigger: Write|Edit
  condition: bash scripts/hooks/check-dangerous-file.sh
  action: block
  message: "危险文件修改需人工确认"
  
check_tdd_compliance:
  trigger: Write *.go
  condition: bash scripts/hooks/check-tdd.sh
  action: warn
  message: "实现文件缺少对应测试"
  
verify_context_usage:
  trigger: Write *.go
  condition: bash scripts/hooks/check-context.sh
  action: warn
  message: "外部调用建议添加 context"
```

### 8.2 PostToolUse

```yaml
auto_format:
  trigger: Write|Edit *.go
  action: gofmt -w "$FILEPATH"
  
auto_vet:
  trigger: Write|Edit *.go
  action: go vet "$FILEPATH" 2>&1
  
update_graphify:
  trigger: Write|Edit *.go
  condition: file_count_changed 10
  action: graphify . --incremental
```

### 8.3 Stop

```yaml
final_gate_check:
  trigger: session_end
  action: bash scripts/gates/all.sh
  fail_action: warn "门控未完全通过，不可声称完成"
```

---

## 9. 知识图谱集成

### 9.1 构建图谱

```bash
# 项目初始化时
graphify .

# 增量更新（文件变更时）
graphify . --update
```

### 9.2 使用场景

| 场景 | 命令 | 用途 |
|------|------|------|
| 探索阶段 | `graphify query "依赖关系"` | 理解模块依赖 |
| 规划阶段 | `graphify query "影响分析"` | 评估变更影响 |
| 重构阶段 | `graphify query "循环依赖"` | 识别架构问题 |
| 审查阶段 | `graphify visual` | 生成架构图 |

### 9.3 图谱缓存

```yaml
graphify:
  output_dir: graphify-out/
  cache_ttl: 3600  # 秒
  incremental: true
  auto_update: true
```

---

## 10. 绝对红线（机器可检测）

| 红线 | 检测命令 | 阻断级别 |
|------|----------|----------|
| **R1** 零数据丢失 | `bash scripts/redlines/R1-check.sh` | block_commit |
| **R2** 零静默失败 | `bash scripts/redlines/R2-check.sh` | block_commit |
| **R3** 零硬编码密钥 | `bash scripts/redlines/R3-check.sh` | block_commit |
| **R4** 零幻觉 | 人工标注 `[UNCERTAIN]` | review_required |
| **R5** 零甩锅 | 代码审查 | review_required |

---

## 11. 分层规范索引

### 第一层（强制）
- 本文件的命令、门控、红线
- 验证只能工具完成

### 第二层（推荐）
- [docs/standards/common/](docs/standards/common/)

### 第三层（项目特定）
- [docs/standards/projects/PROJECT_SPEC.md](docs/standards/projects/PROJECT_SPEC.md)

### 第四层（技能参考）
- [docs/skills/](docs/skills/)

---

## 12. Agent 诚实交付协议

Agent 在最终回复中必须明确区分事实、推断和未验证项，禁止把未执行的检查描述为已完成。

### 12.1 反幻觉规则

- 不确定的事实必须标注 `[UNCERTAIN]`，并说明需要哪个工具或来源验证。
- 外部版本、API、依赖行为、线上状态必须通过工具确认；无法确认时不得给确定结论。
- 引用项目事实时必须来自已读取文件、命令输出或测试结果。
- 不得编造文件、函数、配置、测试结果、命令输出。

### 12.2 反懒惰规则

- 修改代码前必须先定位相关文件和现有约定。
- 声称完成前必须运行与变更相关的最小验证命令。
- 验证失败不得降级为“建议用户自行验证”，除非明确说明失败原因和剩余风险。
- 连续两次同类失败后必须重新探索上下文，而不是继续猜测修补。

### 12.3 交付格式

最终回复必须包含以下信息：

```markdown
**完成内容**
- ...

**验证结果**
- `命令`: 结果

**未验证项**
- 无，或说明原因与风险
```

### 12.4 禁止表述

- 未运行测试时禁止说“测试通过”。
- 门控失败时禁止说“已完成”。
- 工具缺失导致跳过时禁止说“检查通过”。
- 只修改文档时禁止暗示代码行为已验证。

---

## 13. 快速启动检查清单

首次使用本项目时，Agent 必须执行：

```bash
# 1. 预检环境
bash scripts/preflight/all.sh

# 2. 构建知识图谱
graphify .

# 3. 检查门控系统
bash scripts/gates/all.sh --dry-run

# 4. 运行脚手架自测
bash scripts/tests/run.sh

# 5. 验证状态管理
touch .agent/state/test.json && rm .agent/state/test.json

# 6. 确认技能安装
command -v graphify >/dev/null && echo "✅ graphify 已安装"
test -f ~/.claude/skills/superpowers/installed.flag && echo "✅ superpowers 已安装"
```

全部通过后方可开始任务。

---

**配置验证**: `bash scripts/validate-config.sh`  
**状态查看**: `cat .agent/state/current.json`  
**帮助**: `make help`

<!-- MACHINE_EXECUTABLE: true -->
<!-- VALIDATED: false -->
