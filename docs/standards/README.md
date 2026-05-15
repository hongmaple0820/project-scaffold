# 规范体系

本目录是脚手架的规范入口。规范只写跨项目可复用的工程约束；业务项目的差异写入 `docs/standards/projects/`。

## 分层

```text
docs/standards/
├── README.md
├── common/
│   ├── NAMING.md
│   ├── API_STANDARDS.md
│   ├── DATABASE_STANDARDS.md
│   ├── GIT_STANDARDS.md
│   ├── TEAM_COLLABORATION.md
│   └── DOCUMENT_STANDARDS.md
└── projects/
    └── PROJECT_SPEC.md
```

## 使用顺序

1. 先读根目录 `AGENTS.md` 和 `CLAUDE.md`，确认任务等级、红线和门禁。
2. 再读本目录的通用规范。
3. 最后读目标项目的 `projects/<name>/PROJECT_SPEC.md` 或当前 `projects/PROJECT_SPEC.md`。
4. 若项目约定和通用规范冲突，记录原因、影响和退出条件。

## 通用规范

| 规范 | 说明 |
| --- | --- |
| [命名规范](common/NAMING.md) | 代码、数据库、Git 命名约定 |
| [API 规范](common/API_STANDARDS.md) | REST API、错误码、响应格式 |
| [数据库规范](common/DATABASE_STANDARDS.md) | 表设计、索引、查询、迁移 |
| [Git 规范](common/GIT_STANDARDS.md) | 作者分支、dev 推送、master/main 保护、提交和发布流程 |
| [协作规范](common/TEAM_COLLABORATION.md) | 角色职责、沟通、评审、人机协同边界 |
| [文档规范](common/DOCUMENT_STANDARDS.md) | 模块化文档资产、关联关系、版本、冲突和更新维护 |

## 规范级别

| 级别 | 含义 | 处理方式 |
| --- | --- | --- |
| MUST | 必须遵守 | 不满足则阻断 |
| SHOULD | 默认遵守 | 偏离必须说明理由 |
| MAY | 可选 | 按项目需要采用 |

## 新项目接入

1. 复制脚手架。
2. 修改 `.agent/project.json` 适配技术栈。
3. 在 `docs/standards/projects/` 写项目差异。
4. 运行 `make preflight` 和 `make verify`。

## 变更原则

- 通用规范变更要考虑所有派生项目。
- 项目规范只记录差异，不复制整套通用规范。
- 规范变更要同步更新 README、工作流文档或模板中受影响的引用。
