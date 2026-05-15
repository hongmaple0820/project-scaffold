# Git 工作流规范

**版本**: v2.2
**适用范围**: 所有由本脚手架派生的项目

本规范定义分支命名、提交、验证、推送、dev 集成和 master/main 保护策略。默认目标是：每一次推送都可追溯、可验证、可回滚。

## 1. 维护策略

| 分支 | 定位 | 操作权限 |
| --- | --- | --- |
| `dev` | 远程开发集成分支，承载已验证改动 | 验证通过后才允许推送或合并 |
| `feature/*` | 日常功能开发分支 | 默认工作分支 |
| `fix/*` | 普通缺陷修复分支 | 默认修复分支 |
| `docs/*` | 文档、规范、流程调整 | 文档类任务使用 |
| `chore/*` | 构建、脚本、依赖、配置维护 | 工程维护使用 |
| `release/*` | 发布准备分支 | 需要发布计划和确认 |
| `hotfix/*` | 线上紧急修复分支 | 必须人工确认 |
| `master` / `main` | 稳定主干或生产分支 | Agent 禁止自主提交、合并、推送、重置 |

### 1.1 主干保护

- `master` / `main` 不能自主操作。
- 未收到明确指令时，不得对 `master` / `main` 执行 commit、merge、rebase、reset、tag、push。
- 若用户明确要求操作 `master` / `main`，必须先完成验证、说明风险、确认回滚方式，再执行。
- `dev` 是日常集成目标，但不是随手推送目标；只有验证没有问题才允许推到远程 `dev`。

## 2. 分支命名

### 2.0 人类与 Agent 协同分支

分支名必须能看出“谁负责、哪个 Agent 平台参与、做哪个模块、做什么、何时创建”。人类主导和 Agent 辅助都必须保持可追溯。

| 场景 | 推荐格式 | 示例 |
| --- | --- | --- |
| 功能 | `feature/<human-author>/<agent-platform>-<scope>-<task>-<MMDD>` | `feature/maple/codex-lms-course-0515` |
| 修复 | `fix/<human-author>/<agent-platform>-<scope>-<task>-<MMDD>` | `fix/maple/claude-auth-token-refresh-0515` |
| 文档或规范 | `docs/<human-author>/<agent-platform>-<scope>-<task>-<MMDD>` | `docs/maple/codex-scaffold-doc-governance-0515` |
| 工程维护 | `chore/<human-author>/<agent-platform>-<scope>-<task>-<MMDD>` | `chore/maple/codex-workflow-gates-0515` |

协同规则：

- 人类已有未提交改动默认归人类所有，Agent 不得覆盖、格式化或顺手清理。
- Agent 开始前必须查看 `git status --short` 和当前分支；若存在无关脏改，必须隔离到新分支或独立 worktree。
- 同一分支只承载一个交付目标。功能、修复、文档、格式化和依赖升级不得混在一个提交里。
- PR/MR 或最终报告必须写清人类负责人、Agent 平台、验证命令、未验证项、冲突处理和回滚方式。

### 2.1 标准格式

```text
<type>/<human-author>/<agent-platform>-<scope>-<task>-<MMDD>
```

| 字段 | 说明 | 示例 |
| --- | --- | --- |
| `type` | 分支类型 | `feature`、`fix`、`docs`、`chore`、`release`、`hotfix` |
| `human-author` | 人类负责人短名 | `maple` |
| `agent-platform` | Agent 平台或执行者 | `codex`、`claude`、`gemini`、`human` |
| `scope` | 项目、模块或业务域 | `lms`、`platform-tool`、`scaffold` |
| `task` | 任务描述，英文或拼音小写短横线 | `kercheng`、`user-tool-release`、`git-workflow` |
| `MMDD` | 创建日期 | `0514`、`0515` |

### 2.2 示例

```bash
# 不推荐：缺少作者和日期
feature/platform-tool-user-tool-release

# 推荐：带人类负责人、Agent 平台、范围、任务和日期
feature/maple/codex-platform-tool-user-tool-release-0515
feature/maple/claude-lms-kercheng-0514
docs/maple/codex-scaffold-git-workflow-0515
fix/maple/codex-auth-token-refresh-0515
```

### 2.3 命名规则

- 全部小写。
- 使用短横线 `-`，不使用空格、下划线或中文标点。
- 人类负责人和 Agent 平台必须出现在分支名中。
- 任务名要能看出目标，不使用 `test`、`tmp`、`update` 这类空泛词。
- 一个分支只做一类交付，不混合功能、格式化和无关清理。

## 3. 标准开发流程

```text
确认任务 -> 创建作者分支 -> 开发 -> 本地验证 -> 提交 -> 推 feature -> 合并/推 dev -> dev 部署 -> 冒烟验证
```

### 3.1 创建分支

```bash
git status --short
git fetch origin
git switch -c feature/maple/codex-scaffold-git-workflow-0515
```

如果已有远程 `dev`，新分支应从最新 `origin/dev` 派生：

```bash
git fetch origin dev
git switch -c feature/maple/codex-scaffold-git-workflow-0515 origin/dev
```

如果当前工作区已有未提交改动，先判断这些改动是否属于本任务。无关改动不得混入本次提交。

### 3.2 开发前检查

```bash
git branch --show-current
git status --short
bash scripts/gates/all.sh --workflow
```

### 3.3 提交前验证

按项目实际技术栈运行最小验证。脚手架默认命令：

```bash
bash scripts/gates/all.sh --dry-run
bash scripts/gates/all.sh --workflow
bash scripts/gates/all.sh --quality
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/workflow/verify.ps1
bash scripts/workflow/verify.sh --profile scaffold
git diff --check
```

派生项目可以替换为自己的命令，例如：

```bash
npm run lint
npm test
npm run build
go test ./... -race
mvn test
```

未运行的验证必须写成“未验证”，不能写成“通过”。

## 4. 提交规范

### 4.1 Commit 格式

```text
<type>(<scope>): <summary>
```

| 类型 | 说明 |
| --- | --- |
| `feat` | 新功能 |
| `fix` | Bug 修复 |
| `docs` | 文档和规范 |
| `refactor` | 不改变行为的重构 |
| `test` | 测试 |
| `chore` | 构建、依赖、脚本、配置 |
| `ci` | CI/CD |
| `perf` | 性能优化 |

示例：

```bash
git commit -m "docs(git): add dev push and branch policy"
git commit -m "feat(auth): add token refresh workflow"
```

### 4.2 提交边界

- 暂存区只放本次目标相关文件。
- 不提交 `.env`、密钥、证书、token、临时日志。
- 不把格式化全仓、依赖升级和业务改动混在一个提交里。

提交前检查：

```bash
git status --short
git diff --check
git diff --name-only --cached
```

## 5. 推送规则

### 5.1 推送 feature 分支

feature 分支可以在本地最小验证通过后推送：

```bash
git push -u origin feature/maple/codex-scaffold-git-workflow-0515
```

推荐通过 PR/MR 合并到 `dev`。PR/MR 描述必须写清：

- 变更内容。
- 验证命令和结果。
- 未验证项。
- 风险和回滚方案。

### 5.2 推送到远程 dev

只有满足以下条件，才允许推送到 `origin/dev`：

1. 用户明确要求或项目流程允许推 `dev`。
2. 当前分支不是 `master` / `main`。
3. 工作区只包含本次目标相关改动。
4. 已运行必要验证，且没有阻断级失败。
5. 当前提交包含最新 `origin/dev`，避免覆盖他人改动。

推荐流程：

```bash
git fetch origin dev
git branch --show-current
git status --short

# 确认当前分支包含最新 origin/dev
git merge-base --is-ancestor origin/dev HEAD

# 运行验证
bash scripts/gates/all.sh --workflow
bash scripts/gates/all.sh --quality
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/workflow/verify.ps1
bash scripts/workflow/verify.sh --profile scaffold
git diff --check

# 验证通过后，将当前 HEAD 推到远程 dev
git push origin HEAD:dev
```

如果 `git merge-base --is-ancestor origin/dev HEAD` 失败，先同步 `origin/dev`：

```bash
git fetch origin dev
git rebase origin/dev
# 或按团队要求使用 merge
```

同步后必须重新运行验证。

### 5.3 禁止事项

```bash
# 禁止：未验证直接推 dev
git push origin HEAD:dev

# 禁止：Agent 自主推 master/main
git push origin master
git push origin main

# 禁止：强推共享分支
git push --force origin dev
git push --force origin master
git push --force origin main
```

共享分支禁止强推。确需修复历史，必须人工确认并说明影响范围。

## 6. dev 部署流程

`dev` 代表已通过基础验证的开发集成态。推送到 `origin/dev` 后，按项目方式部署 dev 环境。

通用流程：

```text
feature 分支开发
  -> 本地验证通过
  -> 推 feature 或推当前 HEAD 到 origin/dev
  -> CI/CD 或手动脚本部署 dev
  -> 冒烟验证
  -> 记录验证结果
```

如果项目没有 CI/CD，必须在文档中写清手动部署命令，例如：

```bash
# 示例，占位命令，派生项目必须替换
bash scripts/deploy/dev.sh
bash scripts/smoke/dev.sh
```

部署后至少验证：

- 服务能启动。
- 核心健康检查通过。
- 本次改动影响的主路径可用。
- 回滚方式已确认。

## 7. 发布和 master/main

发布流程必须由明确指令触发。Agent 不得自动把 `dev` 合并到 `master` / `main`。

发布前检查：

```bash
git fetch origin
git switch dev
git pull --ff-only origin dev

# 运行完整验证
bash scripts/gates/all.sh --all

# 仅在用户明确要求后继续
```

发布到 `master` / `main` 的动作包括但不限于：

- 合并 `dev` 到 `master` / `main`。
- 创建 release 分支。
- 打 tag。
- 推送 tag。
- 推送 `master` / `main`。

这些动作都必须等待用户明确指令。

## 8. 回滚策略

| 场景 | 回滚方式 |
| --- | --- |
| feature 分支错误 | 修正后重新提交，或删除分支 |
| dev 推送错误 | revert 对应提交，再重新推 `origin/dev` |
| dev 部署错误 | 回滚到上一稳定构建或 revert 后重新部署 |
| master/main 错误 | 必须人工确认，优先 revert，不默认 reset |

推荐命令：

```bash
git revert <commit>
git push origin HEAD:dev
```

`reset --hard`、`push --force`、删除远程分支属于高风险操作，必须人工确认。

## 9. 冲突解决规范

### 9.1 冲突预防

- 开发前先 `git fetch origin`，从最新集成分支创建工作分支。
- 修改共享文件前先确认最近变更：`git log --oneline -- <file>`。
- 大文档按模块拆分，避免多人同时编辑一个长文件。
- Agent 发现同一文件有人类未提交改动时，只能追加必要内容，不能重排全文件或统一格式化。

### 9.2 冲突处理

```bash
git status --short
git fetch origin
git merge origin/dev
# 或按团队要求使用 rebase
```

出现冲突时：

- 先读冲突两侧意图，不得直接使用 `--ours` 或 `--theirs` 覆盖。
- 代码冲突要保留正确行为并补充/重跑相关测试。
- 文档冲突要同时维护正文、索引、链接、版本号和变更记录。
- 解决后必须运行本次任务相关验证，并在提交说明或 PR 中注明冲突文件和处理原则。
- 若冲突涉及业务取舍、权限、生产配置、数据库迁移或无法判断的人类改动，停止并请负责人确认。

### 9.3 禁止操作

```bash
git checkout -- <human-owned-file>
git reset --hard
git push --force origin dev
```

以上操作会丢失或重写他人工作，必须有明确人工指令和回滚说明才允许执行。

## 10. 快速检查清单

推 feature 前：

- 当前分支名符合 `<type>/<human-author>/<agent-platform>-<scope>-<task>-<MMDD>`。
- `git status --short` 无无关文件。
- 最小验证通过。

推 `origin/dev` 前：

- 用户允许或流程允许。
- 当前提交包含最新 `origin/dev`。
- 工作流门禁和质量门禁通过。
- 已记录验证结果。

操作 `master` / `main` 前：

- 用户明确指令。
- 完整验证通过。
- 风险和回滚方案已说明。
