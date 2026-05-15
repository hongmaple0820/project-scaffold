# 通用命名规范

**版本**: v1.0  
**适用范围**: 所有项目

---

## 1. 代码命名

### 1.1 通用原则

| 原则 | 说明 |
|------|------|
| 清晰 > 简短 | `getUserByID` 优于 `gubi` |
| 动词开头 | 函数/方法用动词：`get`, `create`, `update`, `delete` |
| 名词结尾 | 变量/类用名词：`userList`, `orderService` |
| 避免缩写 | `configuration` 优于 `cfg`（常用缩写除外） |

### 1.2 语言特定

| 语言 | 变量/函数 | 类/接口 | 常量 |
|------|-----------|---------|------|
| Go | `camelCase` | `PascalCase` | `UPPER_SNAKE_CASE` |
| TypeScript | `camelCase` | `PascalCase` | `UPPER_SNAKE_CASE` |
| Python | `snake_case` | `PascalCase` | `UPPER_SNAKE_CASE` |
| Java | `camelCase` | `PascalCase` | `UPPER_SNAKE_CASE` |

### 1.3 布尔命名

使用前缀：`is`, `has`, `should`, `can`

```go
// Good
isActive, hasPermission, shouldRetry, canDelete

// Bad
active, permission, retry, delete
```

---

## 2. 数据库命名

### 2.1 表名

- 小写 + 下划线
- 复数形式
- 项目前缀（可选）

```sql
-- Good
users, user_profiles, orders, order_items

-- With prefix
netdisk_files, netdisk_accounts

-- Bad
user, UserProfiles, orderItems
```

### 2.2 字段名

- 小写 + 下划线
- 主键：`id`
- 外键：`表名_id`
- 时间戳：`created_at`, `updated_at`, `deleted_at`

```sql
-- Good
id, user_id, file_name, file_size, created_at

-- Bad
ID, userID, fileName, FileSize, createTime
```

### 2.3 索引名

```sql
-- 格式: idx_表名_字段名
idx_users_email
idx_orders_user_id_status

-- 唯一索引: uk_表名_字段名
uk_users_email
```

---

## 3. Git 命名

### 3.1 分支名

```
<type>/<human-author>/<agent-platform>-<scope>-<task>-<MMDD>

feature/maple/codex-user-auth-0515
fix/maple/claude-login-timeout-0515
hotfix/maple/codex-security-patch-0515
release/maple/human-v1-2-0-0515
```

详细规则见 [Git 工作流规范](GIT_STANDARDS.md)。

### 3.2 提交信息

```
类型(范围): 描述

[可选正文]

[可选脚注]
```

**类型**:
- `feat`: 新功能
- `fix`: 修复
- `docs`: 文档
- `style`: 格式
- `refactor`: 重构
- `perf`: 性能
- `test`: 测试
- `chore`: 构建/工具

```
feat(auth): add OAuth2 login

- Support Google and GitHub
- Add token refresh mechanism

Closes #123
```

---

## 4. 文件/目录命名

- 小写
- 连字符或下划线分隔（保持一致）
- 无空格
- 无特殊字符

```
# Good
user-service/
get-user-by-id.go
api-standards.md

# Bad
User Service/
getUserById.go
API Standards.md
```

---

## 5. API 命名

### 5.1 路径

```
/资源/动作（可选）

GET    /users           # 列表
GET    /users/{id}      # 详情
POST   /users           # 创建
PUT    /users/{id}      # 全量更新
PATCH  /users/{id}      # 部分更新
DELETE /users/{id}      # 删除

GET    /users/{id}/orders  # 子资源
POST   /users/{id}/avatar   # 特定动作
```

### 5.2 查询参数

- 过滤: `?status=active&role=admin`
- 排序: `?sort=created_at&order=desc`
- 分页: `?page=1&size=20`
- 搜索: `?q=keyword`

---

**[← 返回规范体系](../README.md)**
