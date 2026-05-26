# 通用文档维护规范

**版本**: v2.0
**适用范围**: `netdisk-project` 所有 Markdown、架构、规范、计划、知识库和模块说明

文档是工程资产，不是附属说明。新增模块、接口、表结构、配置、前端页面、工作流、部署方式或重要 Bug 修复时，必须同步维护对应文档。

---

## 1. 文档分层

```text
docs/
├── standards/              # 工程规范
│   ├── common/             # 通用规范
│   └── projects/netdisk/   # netdisk 项目差异
├── architecture/           # 架构与模块关系
├── workflow/               # Agent/人类任务流程
├── operations/             # 运维、部署、排查
├── knowledge/              # 决策、经验、同步规则
├── .planning/tasks/          # 任务证据
└── plans/                  # 阶段计划
```

服务级文档放在对应模块目录：

| 模块 | 文档位置 |
|------|----------|
| 网盘主服务 | `amdox-go-netdisk/README.md`、`amdox-go-netdisk/docs/` |
| 认证中心 | `amdox-go-auth/README.md` |
| API 网关 | `amdox-go-gateway/README.md` |
| 前端 | `amdox-netdisk-ui/README.md` |
| Nacos 配置 | `nacos-config/README.md`、环境配置目录 |
| E2E 测试 | `tests/e2e/README.md` |

---

## 2. 模块化资产规则

一个文档必须有明确归属。入口文档只做导航和红线，细节放到对应模块。

| 资产类型 | 主来源 | 维护重点 |
|----------|--------|----------|
| 项目总览 | `README.md` | 定位、快速启动、核心索引 |
| Agent 规则 | `AGENTS.md`、`CLAUDE.md` | 工作方式、门禁、红线 |
| 通用规范 | `docs/standards/common/` | 跨模块、跨服务规则 |
| 项目差异 | `docs/standards/projects/netdisk/` | Netdisk 特有约束、例外 |
| 架构关系 | `docs/architecture/` | 服务边界、依赖、调用链 |
| 运行部署 | `docs/operations/`、`nacos-config/` | 环境、配置、部署、回滚 |
| 任务证据 | `.planning/tasks/` | 探索、计划、验证、复盘 |
| 知识沉淀 | `docs/knowledge/`、`docs/skills/` | 决策、经验、可复用模式 |

规则：

- 一个事实只保留一个主来源，其他文档用相对链接引用。
- 修改模块边界时，同步更新架构、规范和服务 README。
- 修改跨模块协议时，同步更新调用方、被调用方和测试说明。
- 删除、移动或重命名文档时，必须更新所有入口索引和引用链接。
- 文档不能保存生产密钥、真实 token、私钥或敏感配置值。

---

## 3. 模块关系维护

Netdisk 的主要模块关系必须在文档中可追溯。

| 模块 | 上游/入口 | 下游/依赖 | 必须维护的文档 |
|------|-----------|-----------|----------------|
| 前端 UI | 用户浏览器 | Gateway、Netdisk API | 前端 README、API 调用说明 |
| Gateway | 前端、外部调用 | Auth、Netdisk | 网关 README、路由/域名规范 |
| Auth | Gateway、服务内部校验 | Redis、配置中心 | Auth README、认证上下文规范 |
| Netdisk API | Gateway | DB、Redis、Driver、Nacos | 主服务 README、项目规范 |
| Driver | Netdisk API | 本地/第三方云盘 | Driver 架构、存储规范 |
| Nacos 配置 | 服务启动 | 所有服务 | 配置环境规范、部署文档 |
| 数据库 | Netdisk API | MySQL/SQLite | 数据库规范、迁移和回滚 |
| E2E 测试 | 发布/验收 | UI、Gateway、API | E2E README、验证记录 |

跨模块变更必须写清：

- 影响哪些模块。
- 谁是上游，谁是下游。
- 兼容性和回滚方式。
- 哪些文档和测试已更新。

---

## 4. 更新触发条件

| 变更类型 | 必须更新 |
|----------|----------|
| 新服务/新模块 | 根 README、服务 README、架构文档、项目规范 |
| 新 API 或接口行为变化 | API 契约、调用方说明、测试说明 |
| 数据库结构变化 | 数据库规范、迁移说明、回滚方案 |
| Nacos/环境/部署变化 | 配置规范、部署文档、环境索引 |
| 认证/权限/安全变化 | 认证上下文、安全规范、风险说明 |
| 前端页面/交互变化 | 前端 README、API 调用说明、E2E 场景 |
| 工作流/门禁变化 | AGENTS、CLAUDE、workflow、gates 文档 |
| 非平凡 Bug | worklog、knowledge/experiences 或复盘 |

---

## 5. 编写规范

- 使用 UTF-8 Markdown。
- 标题层级从一个 `#` 开始，不跳级。
- 文件名使用小写和短横线，既有全大写规范文件可保持现状。
- 内部链接使用相对路径。
- 代码块必须标注语言。
- 规范文件必须写清适用范围和约束等级。
- 超过 200 行的长文档优先拆分，入口保留索引。

---

## 6. 版本与状态

规范文档头部建议包含：

```markdown
# 文档标题

**版本**: v1.0
**适用范围**: xxx
**最后更新**: YYYY-MM-DD
**维护者**: xxx
```

版本规则：

| 变化 | 版本 |
|------|------|
| 结构重排、规则口径改变 | MAJOR |
| 新增章节或新规则 | MINOR |
| 修错字、修链接、格式调整 | PATCH |

状态值：

```text
草稿 -> 评审中 -> 已发布 -> 已归档
```

---

## 7. 冲突与一致性

文档冲突解决不能只保留一侧内容。必须同时检查：

- 正文是否合并双方意图。
- 索引是否包含新文档。
- 相对链接是否存在。
- 版本号或变更历史是否更新。
- 与代码、配置、脚本是否一致。

如果文档和代码冲突，以实际代码和验证结果为准，同时修正文档。

---

## 8. 提交前检查

```bash
git status --short
git diff --check
rg -n "TODO|FIXME|待补充|xxx" docs AGENTS.md CLAUDE.md README.md
```

检查清单：

- 入口索引没有断链。
- 新文档有明确归属。
- 不复制已有事实，只链接主来源。
- 没有密钥、token、密码或真实生产配置值。
- 验证结果没有把“未运行”写成“通过”。

---

## 9. 评审要求

| 文档类型 | 评审重点 |
|----------|----------|
| 规范 | 是否可执行、是否与现有规则冲突 |
| 架构 | 模块边界、上下游影响、回滚路径 |
| API | 请求/响应、错误码、兼容性 |
| 部署 | 环境隔离、密钥、回滚和冒烟验证 |
| 工作流 | 人类与 Agent 边界、门禁可执行性 |

评审通过后，必须把长期有效的结论沉淀到规范、架构、知识库或 worklog，而不是只留在聊天记录中。
