# 快速开始

**目标**: 5 分钟上手项目

---

## 1. 环境检查

### 必需工具

- [ ] Git
- [ ] Make
- [ ] 技术栈特定工具（如 Go/Node/Python）

### 推荐工具

```bash
# 通用
brew install gh jq ripgrep fd bat

# GitHub CLI 认证
gh auth login
```

---

## 2. 项目初始化

```bash
# 1. 克隆项目
git clone <repo> my-project
cd my-project

# 2. 预检脚手架
make preflight

# 3. 安装依赖（技术栈特定）
# 示例: go mod download
# 示例: npm install
```

---

## 3. 配置 Claude Code

### 检查配置

```bash
# 检查 .claude/settings.json 存在
cat .claude/settings.json

# 检查 MCP 服务器
# 在 Claude Code 中运行: /mcp
```

### 安装技能

```bash
# 核心技能
plugin install superpowers

# 检查技能
# 在 Claude Code 中运行: /skill list
```

---

## 4. 首次开发

```bash
# 启动开发环境
make dev

# 运行测试
make test

# 代码检查
make lint
```

---

## 5. 创建第一个功能

```bash
# 1. 创建任务产物
make new-task NAME=my-first-feature LEVEL=M

# 2. 编辑文档
# docs/worklog/tasks/YYYY-MM-DD-my-first-feature/
#   ├── explore.md
#   ├── mini-prd.md
#   ├── plan.md
#   ├── verification.md
#   ├── review.md
#   └── summary.md

# 3. 记录探索并运行工作流门控
make explore FILES='AGENTS.md CLAUDE.md README.md' MSG='主要矛盾'
make gate-workflow

# 4. 检查门控
make gate
```

---

## 6. 提交代码

```bash
# 1. 检查变更
git status
git diff

# 2. 提交（遵循提交规范）
git add .
git commit -m "feat: add my first feature"

# 3. 推送
git push origin feature/maple/codex-my-first-feature-0515

# 4. 创建 PR
gh pr create --title "[feat] My first feature" --body "..."
```

---

## 下一步

- 阅读 [CLAUDE.md](../../CLAUDE.md) 了解 AI 协作规范
- 阅读 [DEVELOPMENT_WORKFLOW.md](DEVELOPMENT_WORKFLOW.md) 了解完整流程
- 阅读 [docs/standards/](../standards/README.md) 了解编码规范

---

**[← 返回文档中心](../README.md)**
