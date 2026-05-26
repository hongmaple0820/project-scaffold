# 通用 Git 工作流规范

**版本**: v2.1
**适用范围**: `netdisk-project` 全仓库，包括 Go 服务、前端、配置、脚本和文档资产

本规范处理人类与 Agent 协同开发时的分支命名、开发流程、冲突解决、验证、推送 `dev`、发布到 `main/master` 等问题。默认目标是：每个提交都可追溯、可验证、可回滚。

---

## 1. 分支模型

| 分支 | 定位 | 规则 |
|------|------|------|
| `main` / `master` | 稳定主干或生产基线 | 受保护，Agent 不能自主 commit、merge、tag、push、reset |
| `dev` | 远程开发集成分支 | 只接收已验证变更 |
| `develop` | 旧项目开发分支别名 | 若仓库实际使用它，按 `dev` 同级保护 |
| `feature/*` | 功能开发 | 默认功能分支 |
| `fix/*` | Bug 修复 | 默认修复分支 |
| `docs/*` | 文档、规范、流程 | 文档类任务使用 |
| `chore/*` | 构建、脚本、依赖、配置维护 | 工程维护使用 |
| `release/*` | 发布准备 | 需要发布计划和人工确认 |
| `hotfix/*` | 线上紧急修复 | 必须人工确认 |
| `codex/*` | Agent 独立任务分支 | Agent 隔离开发使用 |

`main/master` 只有在用户明确指令下才能操作。即使用户授权，也必须先完成验证、说明风险和回滚方式。

### 1.1 GitLab Flow 闭环

本仓库采用 GitLab Flow 变体，机器可读策略见 `.scale/workspace.json`：

```text
feature/* / fix/* / docs/* / chore/* / codex/*
  -> dev
  -> main
  -> tag / production deploy
```

闭环规则：

- 常规开发从最新 `dev` 派生短分支，验证通过后合并或推送到 `dev`。
- `dev` 用于集成和测试，不直接作为未隔离开发分支。
- `main` 是生产基线；`master` 只作为受保护兼容名。
- 如果 `dev` 只包含本次要上线的内容，发布时从 `dev` 合入 `main`，再 tag 和部署。
- 如果 `dev` 已混入本次不上线内容，从 `main` 创建 `release/vX.Y.Z`，只 cherry-pick 本次发布提交，验证后再合入 `main`。
- hotfix 先修 `dev`；紧急生产修复再 cherry-pick 到 `main`、tag、部署，并确认 `dev` 已包含同一修复。
- release/hotfix 结束后删除临时分支，保留 tag、提交、验证记录和回滚说明。

---

## 2. 分支命名

### 2.1 人类主导分支

```text
<type>/<author>-<module>-<requirement>-<MMDD>
```

示例：

```bash
feature/maple-lms-kercheng-0514
feature/maple-platform-tool-user-tool-release-0515
fix/maple-auth-token-refresh-0515
docs/maple-netdisk-doc-governance-0515
```

字段说明：

| 字段 | 说明 |
|------|------|
| `type` | `feature`、`fix`、`docs`、`chore`、`release`、`hotfix` |
| `author` | 人类负责人短名，例如 `maple` |
| `module` | 模块或业务域，例如 `netdisk`、`auth`、`gateway`、`ui`、`lms` |
| `requirement` | 需求或问题，英文/拼音小写短横线 |
| `MMDD` | 创建日期 |

### 2.2 Agent 主导分支

Agent 独立完成、且不以某个人类正在开发的分支为主时，使用：

```text
codex/<module>-<requirement>-<MMDD>
```

示例：

```bash
codex/netdisk-doc-governance-0515
codex/gateway-route-smoke-0515
```

如果 Agent 在人类分支上协助开发，分支名保留人类作者名，提交或 PR 中注明 Agent 平台和工作范围。

### 2.3 命名硬规则

- 全部小写。
- 使用短横线 `-`，不使用空格、下划线或中文标点。
- 人类主导分支必须带作者名。
- Agent 独立分支必须带 `codex/` 前缀。
- 一个分支只做一个交付目标，不混入无关清理、格式化或依赖升级。

---

## 3. 开发流程

### 3.1 开始前

```bash
git status --short
git branch --show-current
git fetch origin
```

规则：

- 看到未提交改动时，先判断是否属于本任务。
- 人类已有改动默认归人类所有，不得覆盖、重排、格式化或顺手清理。
- 大脏工作区中做独立任务时，优先使用新分支或 `git worktree` 隔离。

### 3.2 创建功能或修复分支

优先从最新 `origin/dev` 派生：

```bash
git fetch origin dev
git switch -c feature/maple-netdisk-account-bind-0515 origin/dev
```

如果仓库暂时没有 `dev`，从最新 `origin/main` 派生，并在提交说明中写清原因：

```bash
git fetch origin main
git switch -c codex/netdisk-doc-governance-0515 origin/main
```

### 3.3 执行

```text
探索 -> 规划 -> 执行 -> 验证 -> 提交 -> 推 feature/codex -> 合并或推 dev -> dev 部署 -> 冒烟验证
```

开发中保持小步提交。生成代码必须说明生成命令，例如 `goctl api go ...`。

---

## 4. 提交规范

```text
<type>(<scope>): <summary>
```

常用类型：

| 类型 | 用途 |
|------|------|
| `feat` | 新功能 |
| `fix` | Bug 修复 |
| `docs` | 文档和规范 |
| `refactor` | 不改行为的重构 |
| `test` | 测试 |
| `chore` | 构建、脚本、依赖、配置 |
| `ci` | CI/CD |
| `revert` | 回滚 |

示例：

```bash
git commit -m "docs(git): add human agent branch policy"
git commit -m "fix(auth): handle expired token refresh"
```

提交边界：

- 暂存区只包含本次目标相关文件。
- 不提交 `.env`、密钥、证书、token、临时日志。
- 不把业务代码、生成代码、格式化和规范更新混在一个提交里。

---

## 5. 验证门禁

提交和推送前，必须运行与变更范围匹配的验证。未运行就写“未验证”，不能写“通过”。

| 变更范围 | 最小验证 |
|----------|----------|
| 文档/规范 | `git diff --check`，必要时检查链接 |
| Go 服务 | `go test ./... -race`，必要时 `golangci-lint run` |
| API 生成 | 重新运行 `goctl` 后执行服务测试 |
| 前端 | `npm run lint`、`npm test`、`npm run build` 中与项目匹配的命令 |
| 配置/部署 | 配置检查、服务启动、健康检查、冒烟验证 |
| CRITICAL | 安全检查、回滚验证、人工确认记录 |

常用检查：

```bash
git status --short
git diff --check
git diff --name-only --cached
```

---

## 6. 推送规则

### 6.1 推送功能分支

功能分支或 Agent 分支可以在最小验证通过后推送：

```bash
git push -u origin codex/netdisk-doc-governance-0515
```

PR/MR 必须说明：

- 变更范围。
- 验证命令和结果。
- 未验证项。
- 文档更新。
- 风险和回滚方式。

### 6.2 推送到远程 dev

只有满足全部条件，才允许推送到 `origin/dev`：

1. 用户明确要求，或项目流程明确允许。
2. 当前分支不是 `main` / `master`。
3. 工作区只包含本次目标相关变更。
4. 必要验证已运行，且没有阻断级失败。
5. 当前提交包含最新 `origin/dev`。

推荐命令：

```bash
git fetch origin dev
git merge-base --is-ancestor origin/dev HEAD
git diff --check

# 运行项目验证后
git push origin HEAD:dev
```

如果 `merge-base` 失败，先同步 `origin/dev`，解决冲突后重新验证。

### 6.3 main/master 保护

禁止 Agent 自主执行：

```bash
git push origin main
git push origin master
git merge dev
git tag -a v1.0.0 -m "release"
git reset --hard
```

用户明确要求操作 `main/master` 时，仍需：

- 确认当前提交和目标分支。
- 运行完整或合理的验证。
- 说明未验证项。
- 确认回滚方式。

---

## 7. 冲突解决

### 7.1 预防冲突

- 开始前拉取最新远程分支。
- 修改共享文件前查看最近提交：`git log --oneline -- <file>`。
- 大文档按模块拆分，减少多人同时编辑入口文件。
- Agent 不得对人类正在编辑的文件做全量格式化。

### 7.2 处理冲突

出现冲突时：

- 先读两侧意图，不直接用 `--ours` 或 `--theirs` 覆盖。
- 代码冲突要保留正确行为，并运行相关测试。
- 文档冲突要同时处理正文、索引、相对链接、版本号和变更记录。
- 解决后运行验证，并在提交或 PR 中说明冲突文件和处理原则。
- 涉及业务取舍、权限、生产配置、数据库迁移或无法判断的人类改动时，停止并请负责人确认。

禁止在未确认情况下执行：

```bash
git checkout -- <human-owned-file>
git reset --hard
git push --force origin dev
```

---

## 8. dev 测试与部署

推送到 `dev` 后，按项目部署方式进入 dev 环境验证。

最低要求：

- 服务能启动。
- 健康检查通过。
- 本次变更影响的主路径可用。
- 回滚方案明确。
- 验证结果记录到 PR、worklog 或发布说明。

---

## 9. 发布与回滚

发布到 `main/master`、打 tag、生产部署都必须由明确指令触发。

回滚优先使用：

```bash
git revert <commit>
```

共享分支禁止默认使用 `reset` 或强推。确需重写历史时，必须有人类负责人确认影响范围。

---

## 10. 快速检查清单

推功能分支前：

- 分支名符合规范。
- 工作区没有无关文件。
- 最小验证已运行。

推 `origin/dev` 前：

- 用户允许或流程允许。
- 当前提交包含最新 `origin/dev`。
- 验证结果已记录。

操作 `main/master` 前：

- 用户明确指令。
- 验证已运行。
- 风险、未验证项和回滚方式已说明。
