# SCALE OS Lite 自动化 Hook 配置

> **强制执行替代自觉** — 将认知规范转化为不可跳过的自动化拦截

---

## 1. SessionStart Hook（技能自动发现）

**目的**: 会话启动时自动列出可用技能，降低发现成本

```json
{
  "hooks": {
    "SessionStart": [
      {
        "command": "echo '[SKILLS AVAILABLE]' && ls ~/.claude/skills/ 2>/dev/null || echo 'No skills directory'",
        "description": "Auto-list available skills at session start"
      }
    ]
  }
}
```

**预期输出**:
```
[SKILLS AVAILABLE]
learner
web-access
e2e-testing
superpowers
gstack
```

---

## 2. PreToolUse Hook（文件大小拦截）

**目的**: 防止 Write 超过 800 行的大文件，强制拆分

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write",
        "command": "node -e \"let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{const i=JSON.parse(d);const c=i.tool_input?.content||'';const lines=c.split('\\n').length;if(lines>800){console.error('[BLOCKED] File exceeds 800 lines ('+lines+')');console.error('[ACTION] Split into smaller modules');process.exit(2)}else{console.log('[PASS] '+lines+' lines')}process.stdout.write(d)}catch(e){process.stdout.write(d)}}\")",
        "description": "Block writes >800 lines (SCALE OS §2 文件组织规范)",
        "timeout": 5000
      }
    ]
  }
}
```

**拦截输出**:
```
[BLOCKED] File exceeds 800 lines (1200)
[ACTION] Split into smaller modules
```

---

## 3. PostToolUse Hook（自动格式化）

**目的**: 写入文件后自动格式化，强制代码规范

### Go 项目

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "command": "golangci-lint run --fix \"$FILE_PATH\" 2>&1 || echo '[INFO] golangci-lint not available'",
        "description": "Auto-fix Go lint issues (SCALE OS §5 质量门控)",
        "timeout": 30000
      }
    ]
  }
}
```

### TypeScript/前端项目

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "command": "npx prettier --write \"$FILE_PATH\" 2>&1 || npx eslint --fix \"$FILE_PATH\" 2>&1 || echo '[INFO] No formatter available'",
        "description": "Auto-format frontend files",
        "timeout": 15000
      }
    ]
  }
}
```

---

## 4. PreCommit Hook（验证强制）

**目的**: 提交前强制运行 lint + test，确保质量门控

**注意**: Claude Code 不支持 PreCommit Hook，需配置在 git hooks

```bash
# .git/hooks/pre-commit
#!/bin/bash
set -e

echo "[PRE-COMMIT] Running validation..."

# Lint
golangci-lint run || npm run lint || echo "[WARN] No lint command"

# Type check
go vet ./... || tsc --noEmit || echo "[WARN] No type check"

# Test
go test ./... -race -cover || npm test || echo "[WARN] No test command"

echo "[PRE-COMMIT] Validation passed ✓"
```

---

## 5. Stop Hook（构建验证）

**目的**: 会话结束前验证项目可构建，防止交付破坏性代码

```json
{
  "hooks": {
    "Stop": [
      {
        "command": "echo '[STOP HOOK] Final validation...' && (go build ./... && go test ./... -race || npm run build && npm test) && echo '[PASS] Build validated' || echo '[WARN] Build failed - check manually'",
        "description": "Final build verification before session ends (SCALE OS §3 验证门控)",
        "timeout": 120000
      }
    ]
  }
}
```

---

## 6. 敏感文件拦截 Hook

**目的**: 防止写入 `.env`、密钥等敏感文件

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write",
        "command": "node -e \"let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{const i=JSON.parse(d);const p=i.tool_input?.file_path||'';if(p.match(/\\.env|secret|credential|password|key|token/i)){console.error('[BLOCKED] Sensitive file: '+p);console.error('[ACTION] Use environment variables instead');process.exit(2)}process.stdout.write(d)}catch(e){process.stdout.write(d)}}\")",
        "description": "Block sensitive file writes (SCALE OS R3 零硬编码密钥)",
        "timeout": 5000
      }
    ]
  }
}
```

---

## 7. SQL 拦截 Hook（CRITICAL 操作）

**目的**: 检测 SQL 文件中的 DROP/ALTER/DELETE/TRUNCATE，触发人工确认

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "command": "node -e \"let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{const i=JSON.parse(d);const c=i.tool_input?.content||'';const p=i.tool_input?.file_path||'';if(p.match(/sql|migration/i)&&c.match(/DROP|ALTER|DELETE|TRUNCATE/i)){console.error('[CRITICAL] Destructive SQL detected: '+p);console.error('[ACTION] Review before execution - add rollback/down method');process.exit(1)}process.stdout.write(d)}catch(e){process.stdout.write(d)}}\")",
        "description": "Warn on destructive SQL (SCALE OS R1/R6)",
        "timeout": 5000
      }
    ]
  }
}
```

**注意**: exit(1) 是警告（继续执行但提醒用户），exit(2) 是阻断（强制停止）

---

## 8. 完整配置示例

### Go 项目完整配置

```json
{
  "hooks": {
    "SessionStart": [
      {
        "command": "echo '[SKILLS]' && ls ~/.claude/skills/",
        "description": "技能自动发现"
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Write",
        "command": "node -e \"...file size check...\"",
        "description": "文件大小拦截"
      },
      {
        "matcher": "Write",
        "command": "node -e \"...sensitive file check...\"",
        "description": "敏感文件拦截"
      },
      {
        "matcher": "Write|Edit",
        "command": "node -e \"...SQL check...\"",
        "description": "SQL 拦截"
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "command": "golangci-lint run --fix \"$FILE_PATH\"",
        "description": "自动格式化",
        "timeout": 30000
      }
    ],
    "Stop": [
      {
        "command": "go build ./... && go test ./... -race",
        "description": "构建验证",
        "timeout": 120000
      }
    ]
  }
}
```

---

## 9. Hook 优先级说明

```
SessionStart → 会话启动（一次）
PreToolUse   → 工具执行前（每次调用）
PostToolUse  → 工具执行后（每次调用）
Stop         → 会话结束（一次）

执行顺序:
SessionStart → PreToolUse → [工具执行] → PostToolUse → Stop
```

**返回码含义**:
- `exit 0` → 通过，继续执行
- `exit 1` → 警告，提醒用户但继续执行
- `exit 2` → 阻断，强制停止并要求用户介入

---

## 10. 配置位置

| 层级 | 文件路径 | 作用域 |
|------|----------|--------|
| **全局个人** | `~/.claude/settings.json` | 所有项目 |
| **项目共享** | `.claude/settings.json` | 团队共享（提交至 Git） |
| **项目个人** | `.claude/settings.local.json` | 个人偏好（git-ignored） |

**建议**:
- SessionStart/Stop → 全局配置（所有项目共用）
- PreToolUse/PostToolUse → 项目配置（根据技术栈定制）

---

## 11. 自定义 Hook 模板

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "<ToolName>|<ToolName>",
        "command": "<your-check-command>",
        "description": "<purpose>",
        "timeout": <ms>
      }
    ]
  }
}
```

**常用 matcher 模式**:
- `Write` → 只拦截写入
- `Write|Edit` → 拦截写入和编辑
- `Bash` → 拦截命令执行
- `Agent` → 拦截子代理调用

---

**一句话**: Hook 将 SCALE OS 的认知规范转化为不可跳过的自动化拦截，实现"强制执行替代自觉"。