# 通用命名规范

**版本**: v1.0  
**适用范围**: 所有项目

---

## 1. 数据库命名规范

### 1.1 表命名

**强制规则**:
- 仅使用小写字母、数字、下划线
- 必须以字母开头
- 使用下划线分隔单词
- 具备明确业务语义

**推荐格式**:
```
<业务前缀>_<模块>_<表名>
```

**示例**:
```
# 好示例
netdisk_cloud_account
netdisk_file_task
mail_message
mail_attachment

# 坏示例
UserCloudAccount    # 大写
camelCaseTable      # 驼峰
tb_user             # 无意义前缀
xxx_info            # 无业务语义
```

**后缀约定**:
| 后缀 | 用途 | 示例 |
|------|------|------|
| `_rel` | 关系表 | `user_role_rel` |
| `_log` | 日志表 | `operation_log` |
| `_stat` | 统计表 | `daily_stat` |
| `_history` | 历史表 | `order_history` |
| `_tmp` | 临时表 | `import_tmp` |

### 1.2 字段命名

**强制规则**:
- 小写 + 下划线
- 语义清晰，避免缩写
- 同类字段保持一致

**命名模式**:
| 场景 | 模式 | 示例 |
|------|------|------|
| 外键 | `<对象>_id` | `user_id`, `account_id` |
| 类型 | `<业务>_type` | `account_type`, `task_type` |
| 状态 | `<业务>_status` | `account_status`, `task_status` |
| 标记 | `<业务>_flag` | `del_flag`, `is_default` |
| 时间 | `<动作>_time` | `create_time`, `complete_time` |
| 数量 | `<业务>_count` | `retry_count`, `file_count` |
| 大小 | `<业务>_size` | `file_size`, `total_space` |
| 金额 | `<业务>_amount` | `order_amount` |

**通用字段（所有业务表必须包含）**:
```sql
`id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键ID'
`create_by` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '创建人ID'
`create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间'
`update_by` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '修改人ID'
`update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间'
`del_flag` TINYINT NOT NULL DEFAULT 0 COMMENT '删除标记：0-未删除 1-已删除'
```

**系统/日志表通用字段**:
```sql
`id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT
`create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
`update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
`del_flag` TINYINT NOT NULL DEFAULT 0
```

### 1.3 索引命名

| 类型 | 前缀 | 格式 | 示例 |
|------|------|------|------|
| 主键 | `PRIMARY` | - | PRIMARY KEY (`id`) |
| 唯一索引 | `uk_` | `uk_<表名>_<字段>` | `uk_netdisk_account_user_type` |
| 普通索引 | `idx_` | `idx_<表名>_<字段>` | `idx_netdisk_task_user_status` |
| 外键 | `fk_` | `fk_<表名>_<字段>` | `fk_netdisk_task_account_id` |

---

## 2. 代码命名规范

### 2.1 Go代码

| 类型 | 规范 | 示例 |
|------|------|------|
| 包名 | 小写，简短 | `netdisk`, `driver`, `cache` |
| 文件名 | 小写，下划线 | `cloud_account.go`, `file_list_logic.go` |
| 结构体 | 大驼峰 | `CloudAccount`, `FileListLogic` |
| 接口 | 大驼峰（简洁） | `Driver`, `Reader`, `Writer` |
| 方法 | 大驼峰 | `GetFileList`, `UploadFile` |
| 函数 | 大驼峰 | `NewServiceContext` |
| 常量 | 全大写下划线 | `MAX_RETRY_COUNT`, `DEFAULT_PAGE_SIZE` |
| 变量 | 小驼峰 | `userID`, `fileName`, `ctx` |
| 私有变量 | 小驼峰 | `mu`, `once` |

**Go特有命名**:
| 场景 | 命名 | 示例 |
|------|------|------|
| 构造函数 | `New<类型>` | `NewDriver`, `NewServiceContext` |
| Getter | `<字段名>` | `Name()`, `Size()` |
| Setter | `Set<字段名>` | `SetName()`, `SetSize()` |
| 接口实现检查 | `_ <接口> = (*<类型>)(nil)` | `var _ Driver = (*LocalDriver)(nil)` |
| Logic文件 | `<动作><资源>logic.go` | `filelistlogic.go` |
| Handler文件 | `<动作><资源>handler.go` | `filelisthandler.go` |

### 2.2 TypeScript/Vue代码

| 类型 | 规范 | 示例 |
|------|------|------|
| 文件名(.ts) | 小驼峰 | `useFile.ts`, `request.ts` |
| 文件名(.vue) | 大驼峰 | `FileList.vue`, `UploadButton.vue` |
| 组件 | 大驼峰 | `<FileList />` |
| 组合函数 | `use` + 大驼峰 | `useFile`, `useUpload` |
| Store | 小驼峰 | `fileStore.ts`, `user.ts` |
| 接口 | `I`前缀 + 大驼峰 | `IFile`, `IUser` |
| 类型别名 | 大驼峰 | `FileType`, `TaskStatus` |
| 枚举 | 大驼峰 | `AccountType`, `TaskStatus` |
| 常量 | 全大写下划线 | `API_BASE_URL`, `MAX_FILE_SIZE` |
| 变量 | 小驼峰 | `userId`, `fileName`, `isLoading` |
| 布尔变量 | `is/has/should/can`前缀 | `isDefault`, `hasError` |
| 事件处理 | `handle` + 动作 | `handleClick`, `handleSubmit` |

### 2.3 API命名

**URL路径**:
```
/api/<版本>/<模块>/<资源>/<动作>
```

| 元素 | 规范 | 示例 |
|------|------|------|
| 版本 | v1, v2 | `/api/v1/` |
| 模块 | 小写复数 | `auth`, `account`, `file` |
| 资源 | 小写复数 | `users`, `files`, `tasks` |
| 动作 | 动词或资源ID | `list`, `upload`, `123` |

**示例**:
```
GET    /api/v1/account/list
POST   /api/v1/file/upload
GET    /api/v1/task/123
DELETE /api/v1/file/delete
```

---

## 3. Git命名规范

### 3.1 分支命名

| 类型 | 格式 | 示例 |
|------|------|------|
| 主分支 | `main` | main |
| 开发分支 | `develop` | develop |
| 功能分支 | `feature/<描述>` | `feature/account-oauth` |
| 修复分支 | `fix/<描述>` | `fix/file-upload-bug` |
| 发布分支 | `release/<版本>` | `release/v1.2.0` |
| 热修复 | `hotfix/<描述>` | `hotfix/security-patch` |

### 3.2 Commit Message

**格式**:
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Type**:
| 类型 | 用途 |
|------|------|
| `feat` | 新功能 |
| `fix` | 修复bug |
| `docs` | 文档更新 |
| `style` | 代码格式（不影响逻辑） |
| `refactor` | 重构 |
| `perf` | 性能优化 |
| `test` | 测试相关 |
| `chore` | 构建/工具/依赖 |

**示例**:
```
feat(account): 添加百度网盘OAuth授权

- 实现OAuth2.0授权流程
- 添加token刷新机制
- 支持多账号绑定

Closes #123
```

---

## 4. 配置命名规范

### 4.1 环境变量

| 场景 | 格式 | 示例 |
|------|------|------|
| 应用配置 | `APP_<名称>` | `APP_PORT`, `APP_ENV` |
| 数据库 | `DB_<名称>` | `DB_HOST`, `DB_PASSWORD` |
| Redis | `REDIS_<名称>` | `REDIS_HOST`, `REDIS_DB` |
| 第三方服务 | `<服务>_<名称>` | `BAIDU_CLIENT_ID`, `JWT_SECRET` |

### 4.2 配置文件

| 类型 | 文件名 | 格式 |
|------|--------|------|
| 开发配置 | `.env.development` | KEY=VALUE |
| 生产配置 | `.env.production` | KEY=VALUE |
| 本地配置 | `.env.local` | KEY=VALUE（git忽略） |
| 示例配置 | `.env.example` | KEY=VALUE（无真实值） |

---

## 5. 文档命名规范

| 类型 | 命名格式 | 示例 |
|------|----------|------|
| 架构文档 | `YYYY-MM-DD-<主题>-design.md` | `2025-04-28-netdisk-architecture-design.md` |
| API文档 | `api-reference.md` | `netdisk-api-reference.md` |
| 部署文档 | `deployment.md` | `k8s-deployment.md` |
| 操作手册 | `operation-manual.md` | `troubleshooting-manual.md` |
| 规范文档 | `<主题>-standards.md` | `database-standards.md` |
