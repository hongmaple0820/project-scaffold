# 工程化配置网站优化建议

> 基于构建 Agent-First 脚手架的实践经验

---

## 1. 核心范式转变：从"描述"到"可执行"

### 1.1 问题与优化对照表

| 当前问题 | 优化方案 | 示例 |
|---------|---------|------|
| "参照文档安装" | 提供可执行命令 | `git clone --depth 1 --branch v2.1.0 https://github.com/obra/superpowers ~/.claude/skills/superpowers` |
| "已读3个文件" | 脚本验证状态 | `jq '.files \| length >= 3'` |
| "测试先于实现" | 文件mtime比较 | 比较 `*_test.go` 与实现文件修改时间 |
| "禁止空catch" | 正则检测 | `if\s+err\s*!=\s*nil\s*\{\s*(//.*)?\s*\}` |

### 1.2 命令结构标准化

每个生成的命令应包含四个字段：

```yaml
dev:
  cmd: "go run ."
  verify: "bash -c 'sleep 2 && curl -s http://localhost:8080/health'"
  timeout: "30s"
  retry: 3
```

---

## 2. 门控系统：从"人工检查"到"自动验证"

### 2.1 门控配置结构

```yaml
gates:
  G1_explore:
    description: "探索完成：已读≥3文件，识别主要矛盾"
    verification: "bash scripts/gates/G1-verify.sh"
    autoCheck: false
    rollback: "补充探索"
    
  G2_plan:
    description: "规划完成：plan.md含边界+异常+回滚"
    verification: "bash scripts/gates/G2-verify.sh"
    autoCheck: false
    rollback: "重写规划"
    
  G3_tdd:
    description: "TDD合规：测试先于实现"
    verification: "bash scripts/gates/G3-verify.sh"
    autoCheck: true
    rollback: "补充测试"
    
  G4_lint:
    description: "代码规范：lint通过"
    verification: "bash scripts/gates/G4-verify.sh"
    autoCheck: true
    rollback: "自动修复"
    
  G5_test:
    description: "功能正确：所有测试通过"
    verification: "bash scripts/gates/G5-verify.sh"
    autoCheck: true
    rollback: "修复代码"
    
  G6_coverage:
    description: "覆盖率：≥80%"
    verification: "bash scripts/gates/G6-verify.sh"
    autoCheck: true
    rollback: "补充测试"
    
  G7_security:
    description: "安全检查：无高危漏洞"
    verification: "bash scripts/gates/G7-verify.sh"
    autoCheck: false
    rollback: "修复安全问题"
```

### 2.2 验证脚本生成模板（G3-TDD检查示例）

```bash
#!/bin/bash
# scripts/gates/G3-verify.sh
# TDD合规检查：测试文件修改时间早于实现文件

set -e

# 查找最近修改的实现文件（非测试文件）
RECENT_IMPL=$(find . -name "*.go" -not -name "*_test.go" -type f -mtime -0.1 2>/dev/null | head -5)

for file in $RECENT_IMPL; do
    test_file="${file%.go}_test.go"
    if [ -f "$test_file" ]; then
        # 比较修改时间
        if [ "$file" -nt "$test_file" ]; then
            echo "[FAIL] $file 比测试文件更新，违反TDD原则"
            exit 1
        fi
    fi
done

echo "[PASS] TDD合规"
exit 0
```

---

## 3. 术语准确性：避免跨语言混淆

### 3.1 术语对照表

| 问题描述 | 错误术语 | 正确术语（按语言） |
|---------|---------|-------------------|
| Go项目 | "禁止空 catch 块" | "禁止空的 error 处理块" |
| Go项目 | "禁止空 catch" | `if\s+err\s*!=\s*nil\s*\{\s*\}` |
| Rust项目 | "空 catch" | "空的 match 分支" |
| Python项目 | "空 catch" | "空的 except 块" |
| JavaScript | "空 catch" | "空的 catch 或 .catch()" |

### 3.2 按技术栈生成的代码规则模板

**Go版本：**
```yaml
code_rules:
  empty_error:
    pattern: 'if\s+err\s*!=\s*nil\s*\{\s*(//[^\n]*)?\s*\}'
    message: "禁止空的 error 处理块"
    fix: "添加日志或返回错误"
    
  hardcoded_secret:
    pattern: '(?i)(password|secret|token|api_key)\s*[=:]\s*["\'][^${}]'
    message: "禁止硬编码密钥"
    fix: "使用 os.Getenv() 或配置中心"
```

**Node.js版本：**
```yaml
code_rules:
  empty_catch:
    pattern: 'catch\s*\([^)]*\)\s*\{\s*\}'
    message: "禁止空的 catch 块"
    fix: "添加错误处理或移除 catch"
    
  hardcoded_secret:
    pattern: '(?i)(password|secret|token)\s*[=:]\s*["\'][^${}]'
    message: "禁止硬编码密钥"
    fix: "使用 process.env.XXX"
```

---

## 4. 状态管理：新增断点恢复能力

### 4.1 workflow.json 状态追踪结构

```json
{
  "version": "2.0",
  "project": "project-name",
  "currentPhase": "idle",
  "currentTier": "standard",
  "phaseHistory": [],
  "gates": {
    "G1_explore": {
      "status": "pending",
      "description": "探索完成：已读≥3文件",
      "verification": "bash scripts/gates/G1-verify.sh",
      "autoCheck": false,
      "verifiedAt": null
    }
  },
  "metrics": {
    "tasksCompleted": 0,
    "gatesPassed": 0,
    "gatesFailed": 0,
    "avgPhaseDuration": {}
  }
}
```

### 4.2 场景模式（Tier）配置

```json
{
  "tierConfig": {
    "sandbox": {
      "flow": ["execute", "verify"],
      "gates": ["G4", "G5"],
      "description": "原型验证"
    },
    "standard": {
      "flow": ["explore", "plan", "execute", "verify", "consolidate"],
      "gates": ["G1", "G2", "G3", "G4", "G5", "G6"],
      "description": "标准开发"
    },
    "critical": {
      "flow": ["explore", "plan", "review", "execute", "verify", "security", "consolidate"],
      "gates": ["G1", "G2", "G3", "G4", "G5", "G6", "G7"],
      "description": "关键变更"
    }
  },
  "autoEscalation": {
    "enabled": true,
    "rules": [
      {
        "pattern": "auth|security|password|credential|token|jwt|oauth",
        "escalateTo": "critical",
        "reason": "安全敏感"
      },
      {
        "pattern": "migration|schema|database|table|DROP|ALTER",
        "escalateTo": "critical",
        "reason": "数据变更"
      }
    ]
  }
}
```

### 4.3 生成的检查点脚本（save.sh）

```bash
#!/bin/bash
# scripts/checkpoint/save.sh
# 保存状态检查点

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
STATE_DIR="$PROJECT_ROOT/.agent/state"
CHECKPOINT_DIR="$PROJECT_ROOT/.agent/checkpoints"

mkdir -p "$STATE_DIR" "$CHECKPOINT_DIR"

PHASE="${1:-unknown}"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# 构建状态JSON
cat > "$STATE_DIR/current.json" << EOF
{
  "timestamp": "$TIMESTAMP",
  "phase": "$PHASE",
  "completed_gates": [],
  "open_tasks": [],
  "files_modified": []
}
EOF

# 同时保存到历史检查点
cp "$STATE_DIR/current.json" "$CHECKPOINT_DIR/$TIMESTAMP.json"

echo "[CHECKPOINT] 状态已保存: $PHASE @ $TIMESTAMP"
```

### 4.4 生成的恢复脚本（resume.sh）

```bash
#!/bin/bash
# scripts/checkpoint/resume.sh
# 恢复之前状态

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
STATE_FILE="$PROJECT_ROOT/.agent/state/current.json"

if [ ! -f "$STATE_FILE" ]; then
    echo "[RESUME] 无状态文件，从 idle 开始"
    exit 0
fi

PHASE=$(jq -r '.phase' "$STATE_FILE")
COMPLETED=$(jq -r '.completed_gates | join(", ")' "$STATE_FILE")
TASKS=$(jq -r '.open_tasks | join(", ")' "$STATE_FILE")

echo "========================================"
echo "[RESUME] 检测到之前的状态"
echo "========================================"
echo "当前阶段: $PHASE"
echo "已完成门控: $COMPLETED"
echo "未完成任务: $TASKS"
echo ""
echo "选项:"
echo "  1. 继续 $PHASE 阶段"
echo "  2. 重置到 idle 阶段"
echo "  3. 查看详细状态"
echo "========================================"
```

---

## 5. 知识图谱：集成 graphify

### 5.1 skills 配置结构

```json
{
  "skills": {
    "required": [
      {
        "name": "superpowers",
        "version": "2.1.0",
        "install": "git clone --depth 1 --branch v2.1.0 https://github.com/obra/superpowers ~/.claude/skills/superpowers && touch ~/.claude/skills/superpowers/installed.flag",
        "verify": "test -f ~/.claude/skills/superpowers/installed.flag",
        "rollback": "rm -rf ~/.claude/skills/superpowers"
      },
      {
        "name": "graphify",
        "version": "latest",
        "install": "pip install graphifyy && graphify install",
        "verify": "command -v graphify",
        "rollback": "pip uninstall -y graphifyy"
      }
    ],
    "optional": []
  }
}
```

### 5.2 Makefile 中的 graphify 命令

```makefile
## graphify: 构建知识图谱
graphify:
	@echo "$(BLUE)[MAKE] 构建知识图谱...$(NC)"
	@if command -v graphify >/dev/null 2>&1; then \
		graphify .; \
		echo "$(GREEN)[OK] 知识图谱已构建$(NC)"; \
	else \
		echo "$(YELLOW)[WARN] graphify 未安装$(NC)"; \
		echo "$(YELLOW)[HINT] 运行: pip install graphifyy$(NC)"; \
	fi
```

### 5.3 graphify 使用场景表

| 场景 | 命令 | 用途 |
|------|------|------|
| 探索阶段 | `graphify query "依赖关系"` | 理解模块依赖 |
| 规划阶段 | `graphify query "影响分析"` | 评估变更影响 |
| 重构阶段 | `graphify query "循环依赖"` | 识别架构问题 |
| 审查阶段 | `graphify visual` | 生成架构图 |

---

## 6. 配置分层：渐进式披露

### 6.1 四层配置架构

```
第一层（强制）- 机器可执行
├── 命令（cmd/verify/timeout/rollback）
├── 门控（G1-G7 + 验证脚本）
└── 红线（R1-R6 + 检测命令）

第二层（推荐）- 工作流规范
├── 认知工作流（探索→规划→执行→验证→沉淀）
├── 状态管理（checkpoint/resume）
└── 技能清单（superpowers/graphify）

第三层（项目特定）- 技术栈相关
├── 代码规则（按语言生成正确正则）
├── 工具配置（golangci-lint/eslint等）
└── 目录结构

第四层（参考）- 最佳实践
├── 设计模式
├── 安全指南
└── 性能优化
```

### 6.2 CLAUDE.md 渐进式结构

```markdown
# CLAUDE.md

<!-- 第一层：核心（始终可见） -->
## 1. 快速命令

```yaml
dev: { cmd: "go run .", verify: "curl localhost:8080/health", timeout: 30s }
build: { cmd: "go build -o bin/app .", verify: "test -x bin/app", timeout: 120s }
test: { cmd: "go test ./...", verify: "grep PASS .agent/logs/test.json", timeout: 300s }
```

## 2. 质量门控速查

| 门控 | 验证命令 | 自动检查 |
|------|----------|----------|
| G1 | `bash scripts/gates/G1-verify.sh` | 否 |
| G4 | `bash scripts/gates/G4-verify.sh` | 是 |

<!-- 第二层：详情（折叠） -->
<details>
<summary><b>7. 状态管理详情</b></summary>
...
</details>

<details>
<summary><b>8. 技能清单详情</b></summary>
...
</details>

<!-- 第三层：参考（按需展开） -->
<details>
<summary><b>11. 完整代码规则</b></summary>
...
</details>
```

---

## 7. Hooks 系统：自动化触发

### 7.1 settings.json hooks 配置

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "command": "bash scripts/hooks/check-dangerous-file.sh",
        "timeout": 5000,
        "description": "拦截危险文件修改"
      },
      {
        "matcher": "Write *.go",
        "command": "bash scripts/hooks/check-tdd.sh",
        "timeout": 3000,
        "description": "TDD合规提醒"
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit *.go",
        "command": "gofmt -w \"${CLAUDE_FILE_PATH}\" 2>/dev/null || true",
        "timeout": 3000,
        "description": "Go自动格式化"
      },
      {
        "matcher": "Write|Edit *.md",
        "command": "prettier --write \"${CLAUDE_FILE_PATH}\" 2>/dev/null || true",
        "timeout": 5000,
        "description": "Markdown格式化"
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "command": "bash scripts/gates/all.sh 2>&1 || echo \"[STOP] 门控未完全通过\"",
        "timeout": 120000,
        "description": "会话结束运行门控"
      }
    ]
  }
}
```

### 7.2 生成的危险文件检查脚本

```bash
#!/bin/bash
# scripts/hooks/check-dangerous-file.sh

DANGEROUS_PATTERNS=(
    "\.env$"
    "\.key$"
    "\.pem$"
    "secret"
    "credential"
    "password"
)

FILE_PATH="${CLAUDE_FILE_PATH:-}"

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
    if echo "$FILE_PATH" | grep -qE "$pattern"; then
        echo "[HOOK-BLOCK] 危险文件: $FILE_PATH"
        echo "[HOOK-BLOCK] 如需修改，请手动确认"
        exit 1
    fi
done

exit 0
```

---

## 8. 绝对红线：机器可检测

### 8.1 红线配置

| 红线 | 检测命令 | 阻断级别 | 说明 |
|------|----------|----------|------|
| R1 零数据丢失 | `bash scripts/redlines/R1-check.sh` | block | migration必须有down方法 |
| R2 零静默失败 | `bash scripts/redlines/R2-check.sh` | block | 禁止空error处理 |
| R3 零硬编码密钥 | `bash scripts/redlines/R3-check.sh` | block | 敏感信息走环境变量 |
| R4 零幻觉 | 人工标注 `[UNCERTAIN]` | review | 不确定时标注 |
| R5 零甩锅 | 代码审查 | review | 归因前必须验证 |
| R6 零未审操作 | Hook拦截 | confirm | DB变更需确认 |

### 8.2 R3-硬编码密钥检查脚本模板

```bash
#!/bin/bash
# scripts/redlines/R3-check.sh

set -e

echo "[REDLINE] R3: 零硬编码密钥检查"

# 检查模式
PATTERNS=(
    '(?i)(password|secret|token|api_key)\s*[=:]\s*["\'][^${}]'
    '(?i)const\s+\w*(key|secret|token)\w*\s*=\s*["\']'
    'sk-[a-zA-Z0-9]{24,}'
    'AKIA[0-9A-Z]{16}'
)

VIOLATIONS=0
for pattern in "${PATTERNS[@]}"; do
    if grep -rE "$pattern" --include="*.go" --include="*.yaml" --include="*.json" . 2>/dev/null; then
        echo "[VIOLATION] 发现硬编码密钥匹配: $pattern"
        VIOLATIONS=$((VIOLATIONS+1))
    fi
done

if [ $VIOLATIONS -gt 0 ]; then
    echo "[REDLINE] ❌ R3 违反: 发现 $VIOLATIONS 个硬编码密钥"
    exit 1
fi

echo "[REDLINE] ✅ R3 通过"
exit 0
```

---

## 9. MCP 服务器配置模板

```json
{
  "mcpServers": {
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
}
```

---

## 10. 网站输出格式建议

### 10.1 两种导出模式

**模式A：完整包**（用于新项目）
```
project-scaffold/
├── CLAUDE.md              # 核心配置（< 200行）+ 折叠详情
├── .claude/
│   ├── settings.json      # MCP + Hooks + Permissions
│   └── workflow.json      # 状态追踪
├── Makefile               # 命令入口
├── scripts/
│   ├── preflight/         # 环境检查
│   ├── gates/             # 7个门控验证脚本
│   ├── checkpoint/        # 状态管理
│   ├── hooks/             # 自动化钩子
│   └── redlines/          # 红线检查
└── docs/                  # 分层规范文档
```

**模式B：增量更新**（用于现有项目）
- 只导出 `.claude/workflow.json` 更新片段
- 只导出新增的 gate 脚本
- 提供 `validate-config.sh` 检查兼容性

### 10.2 配置验证脚本模板

```bash
#!/bin/bash
# scripts/validate-config.sh

set -e

ERRORS=0

echo "[VALIDATE] 配置验证"

# 检查必需文件
REQUIRED_FILES=("CLAUDE.md" ".claude/settings.json" ".claude/workflow.json")
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "[OK] $file"
    else
        echo "[ERROR] 缺少: $file"
        ERRORS=$((ERRORS+1))
    fi
done

# 检查JSON有效性
if command -v jq &>/dev/null; then
    for json in .claude/*.json; do
        if jq empty "$json" 2>/dev/null; then
            echo "[OK] JSON有效: $json"
        else
            echo "[ERROR] 无效JSON: $json"
            ERRORS=$((ERRORS+1))
        fi
    done
fi

# 检查脚本可执行
REQUIRED_SCRIPTS=(
    "scripts/preflight/all.sh"
    "scripts/gates/all.sh"
    "scripts/checkpoint/save.sh"
)
for script in "${REQUIRED_SCRIPTS[@]}"; do
    if [ -x "$script" ]; then
        echo "[OK] 可执行: $script"
    else
        echo "[ERROR] 不可执行: $script"
        ERRORS=$((ERRORS+1))
    fi
done

if [ $ERRORS -eq 0 ]; then
    echo "[VALIDATE] ✅ 通过"
    exit 0
else
    echo "[VALIDATE] ❌ 失败: $ERRORS 个错误"
    exit 1
fi
```

---

## 11. 优先级排序

| 优先级 | 改进项 | 影响 | 实现难度 |
|--------|--------|------|----------|
| **P0** | 命令添加 verify 字段 | 机器可执行 | 低 |
| **P0** | 门控生成验证脚本 | 自动检查 | 中 |
| **P0** | 修正技术术语 | 专业准确 | 低 |
| **P1** | 添加状态管理 | 断点恢复 | 中 |
| **P1** | 集成 graphify | 知识图谱 | 低 |
| **P1** | 配置四层分层 | 渐进披露 | 中 |
| **P2** | 添加 Hooks 系统 | 自动化 | 中 |
| **P2** | 场景模式（Tier） | 灵活适配 | 低 |
| **P2** | 配置验证脚本 | 质量保证 | 低 |

---

## 12. 关键设计原则总结

1. **机器可执行**：每个指令都附带验证命令，不是描述而是代码
2. **可验证门控**：每个门控都有独立脚本，返回 0/1
3. **状态可恢复**：自动 checkpoint，中断后可 resume
4. **术语准确**：按技术栈生成正确的代码规则
5. **渐进披露**：核心 < 200 行，详情折叠
6. **技术无关**：底层结构通用，表层适配语言
7. **版本锁定**：技能固定版本，可重现

---

*文档生成时间: 2026-04-28*
*基于项目: f:/project/project-scaffold*
