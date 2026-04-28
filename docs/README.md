# 文档中心

**定位**: 项目知识管理，解决"在哪里找什么"的问题

---

## 文档分层

```
docs/
├── standards/      # 规范（必须遵守）
│   ├── common/     # 通用规范（跨项目复用）
│   └── projects/   # 项目特定规范
├── guides/         # 指南（推荐遵循）
├── skills/         # 技能（参考学习）
├── architecture/   # 架构（关键决策）
└── plans/          # 计划（按日期组织）
```

---

## 快速导航

### 规范 Standards

| 文档 | 内容 | 适用 |
|------|------|------|
| [standards/common/NAMING.md](standards/common/NAMING.md) | 命名规范（代码/数据库/Git） | 所有项目 |
| [standards/common/API_STANDARDS.md](standards/common/API_STANDARDS.md) | API设计规范 | RESTful 服务 |
| [standards/common/DATABASE_STANDARDS.md](standards/common/DATABASE_STANDARDS.md) | 数据库设计规范 | 使用数据库 |
| [standards/common/GIT_STANDARDS.md](standards/common/GIT_STANDARDS.md) | Git工作流 | 所有项目 |
| [standards/common/TEAM_COLLABORATION.md](standards/common/TEAM_COLLABORATION.md) | 团队协作规范 | 团队项目 |
| [standards/common/DOCUMENT_STANDARDS.md](standards/common/DOCUMENT_STANDARDS.md) | 文档维护规范 | 所有项目 |
| [standards/projects/](standards/projects/) | 项目特定规范 | 当前项目 |

### 指南 Guides

| 文档 | 内容 |
|------|------|
| [guides/DEVELOPMENT_WORKFLOW.md](guides/DEVELOPMENT_WORKFLOW.md) | 认知工作流完整说明 |
| [guides/GETTING_STARTED.md](guides/GETTING_STARTED.md) | 项目快速开始 |
| [guides/CODE_REVIEW_GUIDE.md](guides/CODE_REVIEW_GUIDE.md) | 代码审查指南 |
| [guides/TROUBLESHOOTING.md](guides/TROUBLESHOOTING.md) | 常见问题排查 |

### 技能 Skills

| 文档 | 内容 |
|------|------|
| [skills/README.md](skills/README.md) | 技能手册导航 |
| [skills/patterns/](skills/patterns/) | 设计模式 |
| [skills/frontend/](skills/frontend/) | 前端技能 |
| [skills/backend/](skills/backend/) | 后端技能 |

### 架构 Architecture

| 文档 | 内容 |
|------|------|
| [architecture/OVERVIEW.md](architecture/OVERVIEW.md) | 架构总览 |
| [architecture/decisions/](architecture/decisions/) | 架构决策记录(ADR) |

---

## 文档规范

### 文件命名

- 通用规范: `COMMON_TOPIC.md`
- 项目规范: `PROJECT_SPEC.md`
- 指南: `DESCRIPTIVE_NAME.md`
- ADR: `ADR-NNN-short-title.md`

### 版本标记

```markdown
**版本**: v1.0  
**日期**: 2026-04-28  
**状态**: 草案/评审中/已发布/已归档
```

### 更新触发

| 变更类型 | 需更新文档 |
|----------|------------|
| 新增功能 | plans/ + CHANGELOG |
| 修改接口 | standards/API + guides/ |
| 重构代码 | skills/ + architecture/ |
| 修复Bug | CHANGELOG + guides/TROUBLESHOOTING |

---

**[← 返回根目录](../CLAUDE.md)**
