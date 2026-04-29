# 项目脚手架 v2.0

> **Agent-First** 的工程化配置，完全机器可执行，零模糊指令

**核心理念**: 认知脚手架 + 质量门控 + 知识图谱 + 断点恢复

---

## 快速开始

### 1. 环境预检（首次使用）

```bash
# 运行预检脚本
make preflight

# 或直接使用
bash scripts/preflight/all.sh

# 验证脚手架自身约束
make test-scaffold
```

预检内容:
- ✅ 工具链完整性
- ✅ MCP服务器配置
- ✅ 技能安装状态
- ✅ 目录结构
- ✅ 状态管理系统

### 2. 构建知识图谱（推荐）

```bash
# 安装 graphify
pip install graphifyy
graphify install

# 构建图谱
make graphify

# 查询依赖
graphify query "模块依赖关系"
```

### 技术栈适配

脚手架通过 `.agent/project.json` 声明或自动检测技术栈，并为 G4-G7 读取对应的 lint、test、coverage、security 命令。

```json
{
  "stack": "auto",
  "coverage_threshold": 80
}
```

支持默认适配：Go、Node、Python。生成真实项目后，应把 `.agent/project.json` 中的命令替换为项目实际命令。

### 3. 创建第一个功能

```bash
# 1. 创建计划
make plan NAME=user-auth

# 2. 按照认知工作流开发...
#    探索 → 规划 → 执行 → 验证 → 沉淀

# 3. 检查门控
make gate
```

---

## 核心特性

### ✨ 机器可执行配置

| 特性 | 传统配置 | 本脚手架 |
|------|---------|---------|
| 技能安装 | "参照文档安装" ❌ | `git clone --branch v2.1.0 ...` ✅ |
| 门控验证 | "已读3个文件" ❌ | `jq '.files | length >= 3'` ✅ |
| TDD检查 | "测试先于实现" ❌ | 比较文件mtime + git log ✅ |
| 代码规则 | "禁止空catch" ❌ | `grep -E 'if\s+err.*\{\s*\}'` ✅ |

### 🎯 7个质量门控 (G1-G7)

```
G1 [探索] ──┐
G2 [规划] ──┤──→ 执行 ──→ G4 [Lint] ──┐
G3 [TDD] ───┘                           ├──→ 完成
                    G5 [Test] ─────────┤
                    G6 [Coverage ≥80%] ─┤
                    G7 [Security] ──────┘
```

每个门控都有**独立的验证脚本**，可单独执行:

```bash
bash scripts/gates/G1-verify.sh  # 探索完成
bash scripts/gates/G4-verify.sh  # Lint通过
bash scripts/gates/all.sh        # 全部检查
```

### 💾 状态管理与断点恢复

```bash
# 自动保存（在关键阶段）
make checkpoint PHASE=plan

# 查看当前状态
cat .agent/state/current.json

# 恢复之前状态
make resume

# 查看历史检查点
ls -la .agent/checkpoints/
```

状态结构:
```json
{
  "timestamp": "2026-04-28T10:30:00+08:00",
  "phase": "execute",
  "completed_gates": ["G1", "G2", "G3"],
  "open_tasks": ["实现Login接口"],
  "files_modified": ["internal/auth/login.go"]
}
```

### 🔒 6条绝对红线

| 红线 | 检测命令 | 阻断级别 |
|------|----------|----------|
| R1 零数据丢失 | `bash scripts/redlines/R1-check.sh` | block |
| R2 零静默失败 | `bash scripts/redlines/R2-check.sh` | block |
| R3 零硬编码密钥 | `bash scripts/redlines/R3-check.sh` | block |
| R4 零幻觉 | 人工标注 `[UNCERTAIN]` | review |
| R5 零甩锅 | 代码审查 | review |
| R6 零未审操作 | Hook拦截 | confirm |

### 🤖 自动化 Hooks

**PreToolUse**:
- 危险文件拦截 (`.env`, `secret`, `credential`)
- TDD合规提醒 (实现先于测试时警告)
- 外部调用检查 (建议使用context)

**PostToolUse**:
- 自动格式化 (Go: gofmt, Markdown: prettier)
- 自动静态检查 (go vet)
- 增量图谱更新 (graphify)

**Stop**:
- 自动门控检查
- 失败阻断提交

---

## 文档体系

```
docs/
├── standards/          # 规范 (必须遵守)
│   ├── common/         # 通用规范
│   │   ├── NAMING.md
│   │   ├── API_STANDARDS.md
│   │   ├── DATABASE_STANDARDS.md
│   │   ├── GIT_STANDARDS.md
│   │   ├── TEAM_COLLABORATION.md
│   │   └── DOCUMENT_STANDARDS.md
│   └── projects/       # 项目特定规范
│       └── PROJECT_SPEC.md
│
├── guides/             # 指南 (推荐遵循)
│   ├── DEVELOPMENT_WORKFLOW.md
│   ├── GETTING_STARTED.md
│   └── CODE_REVIEW_GUIDE.md
│
├── skills/             # 技能 (参考学习)
│   ├── patterns/
│   ├── frontend/
│   ├── backend/
│   └── devops/
│
├── architecture/       # 架构 (关键决策)
│   ├── OVERVIEW.md
│   └── decisions/
│
└── plans/              # 计划 (运行时创建)
    └── YYYY-MM-DD-feature/
        ├── spec.md
        ├── plan.md
        └── tasks.md
```

---

## 认知工作流

```
探索 → 规划 → 执行 → 验证 → 沉淀
   ↑                      ↓
   └── 失败2次后 /clear ──┘
```

| 阶段 | 关键动作 | 门控 | 检查点 |
|------|---------|------|--------|
| **探索** | 读文档、扫代码、知识图谱 | G1 | `bash scripts/gates/G1-verify.sh` |
| **规划** | 需求精炼、影响分析 | G2 | `bash scripts/gates/G2-verify.sh` |
| **执行** | TDD、防御编码 | G3 | `bash scripts/gates/G3-verify.sh` |
| **验证** | Lint、Test、Coverage | G4-G7 | `make gate` |
| **沉淀** | 泛化检查、文档更新 | - | 人工确认 |

### 断点恢复

如果会话中断，恢复时自动检测:

```bash
# 检测到之前的状态: execute
# 已完成门控: ["G1", "G2", "G3"]
# 未完成任务: ["实现Login接口"]
#
# 选项:
#   1. 继续 execute 阶段
#   2. 重置到 idle 阶段
#   3. 查看详细状态
```

---

## 技术栈适配

本脚手架是**技术无关**的，支持任何语言/框架。

### 适配方法

1. **修改 `Makefile`**
   ```makefile
   dev:
       npm run dev        # Node.js
       # 或
       python manage.py   # Python
       # 或
       cargo run          # Rust
   ```

2. **修改门控脚本**
   ```bash
   # scripts/gates/G4-verify.sh
   # 从 golangci-lint 改为 eslint/ruff/flake8
   ```

3. **修改代码规则**
   ```yaml
   # CLAUDE.md 中的 code_rules
   # 从 Go 正则改为目标语言
   ```

### 快速模板

```bash
# Go项目
cp -r project-scaffold my-go-project
cd my-go-project
# 编辑 Makefile 使用 go 命令

# Node项目
cp -r project-scaffold my-node-project
cd my-node-project
# 编辑 Makefile 使用 npm 命令

# Python项目
cp -r project-scaffold my-python-project
cd my-python-project
# 编辑 Makefile 使用 python 命令
```

---

## 配置验证

```bash
# 验证配置有效性
make validate

# 检查输出:
# [OK] CLAUDE.md
# [OK] settings.json
# [OK] 脚本可执行
# [OK] JSON格式有效
```

---

## 最佳实践

### 1. 首次使用

```bash
make preflight      # 环境检查
make graphify       # 构建知识图谱
make validate       # 验证配置
```

### 2. 日常开发

```bash
make plan NAME=xxx  # 创建计划
# 编辑 docs/plans/...
make checkpoint     # 保存状态
# 开发...
make gate           # 检查门控
```

### 3. 中断恢复

```bash
make resume         # 恢复状态
# 或查看手动状态
cat .agent/state/current.json
```

### 4. 红线检查

```bash
# 提交前运行
bash scripts/redlines/R1-check.sh  # 数据安全
bash scripts/redlines/R2-check.sh  # 错误处理
bash scripts/redlines/R3-check.sh  # 密钥安全
```

---

## 目录结构

```
project-scaffold/
├── CLAUDE.md                    # AI指导文档 (机器可执行)
├── README.md                    # 本文件
├── Makefile                     # 常用命令
├── .gitignore                   # 忽略规则
│
├── .claude/                     # Claude配置
│   ├── settings.json            # 权限+MCP+Hooks
│   └── workflow.json            # 工作流状态
│
├── .agent/                      # 状态管理
│   ├── state/                   # 当前状态
│   ├── checkpoints/             # 历史检查点
│   └── logs/                    # 运行日志
│
├── docs/                        # 文档中心
│   ├── standards/               # 规范
│   ├── guides/                  # 指南
│   ├── skills/                  # 技能
│   ├── architecture/            # 架构
│   └── plans/                   # 计划
│
├── templates/                   # 快速模板
│   ├── plan/
│   │   ├── spec.md
│   │   ├── plan.md
│   │   └── tasks.md
│   └── adr/
│       └── adr-template.md
│
└── scripts/                     # 可执行脚本
    ├── preflight/               # 环境预检
    ├── gates/                   # 质量门控
    ├── checkpoint/              # 状态管理
    ├── hooks/                   # 自动化钩子
    ├── redlines/                # 红线检查
    ├── init-plan.sh             # 创建计划
    └── validate-config.sh       # 配置验证
```

---

## 对比传统配置

| 维度 | 传统 | 本脚手架 |
|------|------|---------|
| 指令明确性 | 模糊描述 | 可执行命令 |
| 可验证性 | 人工检查 | 脚本自动验证 |
| 可恢复性 | 无状态 | 断点续传 |
| 错误处理 | 失败即停 | 自动回滚 |
| 版本控制 | latest | 固定版本+hash |
| 知识管理 | 文档沉淀 | 图谱+文档 |

---

## 贡献

参见 [CONTRIBUTING.md](CONTRIBUTING.md)

---

## 许可证

MIT

---

**配置验证**: `make validate`  
**脚手架自测**: `make test-scaffold`
**快速开始**: `make preflight && make graphify`  
**状态查看**: `cat .agent/state/current.json`
