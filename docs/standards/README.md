# 规范体系

**定位**: 项目的"法律"，定义必须遵守的约定

---

## 规范分层

```
standards/
├── common/         # 通用规范（所有项目复用）
│   ├── NAMING.md
│   ├── API_STANDARDS.md
│   ├── DATABASE_STANDARDS.md
│   ├── GIT_STANDARDS.md
│   ├── TEAM_COLLABORATION.md
│   └── DOCUMENT_STANDARDS.md
└── projects/       # 项目特定规范
    └── <project-name>/
        └── PROJECT_SPEC.md
```

---

## 快速导航

### 第一层：强制规范

在 [CLAUDE.md](../CLAUDE.md) 中定义：
- 六条绝对红线
- 任务分级标准
- 门控要求

### 第二层：通用规范

| 规范 | 说明 | 查看 |
|------|------|------|
| **命名规范** | 代码、数据库、Git 命名约定 | [common/NAMING.md](common/NAMING.md) |
| **API规范** | RESTful API 设计、错误码、响应格式 | [common/API_STANDARDS.md](common/API_STANDARDS.md) |
| **数据库规范** | 表设计、索引、查询、迁移 | [common/DATABASE_STANDARDS.md](common/DATABASE_STANDARDS.md) |
| **Git规范** | 分支模型、提交信息、PR流程 | [common/GIT_STANDARDS.md](common/GIT_STANDARDS.md) |
| **协作规范** | 角色职责、沟通渠道、会议 | [common/TEAM_COLLABORATION.md](common/TEAM_COLLABORATION.md) |
| **文档规范** | 文档编写、维护、评审 | [common/DOCUMENT_STANDARDS.md](common/DOCUMENT_STANDARDS.md) |

### 第三层：项目特定

- [projects/](projects/) - 当前项目的特定约定

---

## 规范级别

| 级别 | 说明 | 违反后果 |
|------|------|----------|
| **MUST** | 必须遵守 | 阻断提交 |
| **SHOULD** | 默认遵守 | PR评论 |
| **MAY** | 可选 | 建议 |

---

## 规范变更流程

```
提案 → 评审 → 影响评估 → 更新 → 通知
```

1. **提案**: 提交变更说明
2. **评审**: 架构组/技术负责人评审
3. **影响评估**: 哪些项目受影响
4. **更新**: 修改文档并记录变更历史
5. **通知**: 同步团队

---

## 新项目接入

1. 直接使用 `common/` 下的通用规范
2. 在 `projects/<name>/` 创建项目特定规范
3. 只记录与通用规范的**差异**

---

**[← 返回文档中心](../README.md)**
