# 数据库规范

**版本**: v1.0  
**适用范围**: 使用数据库的项目

---

## 1. 表设计

### 1.1 必须字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | bigint unsigned | 主键，自增 |
| `created_at` | datetime | 创建时间 |
| `updated_at` | datetime | 更新时间 |
| `deleted_at` | datetime | 软删除时间（可选） |

### 1.2 字段顺序

```sql
id,
业务字段（按重要性）,
created_at,
updated_at,
deleted_at
```

---

## 2. 索引规范

### 2.1 必须索引

- 主键索引
- 外键索引
- 唯一约束字段

### 2.2 推荐索引

- 查询条件字段
- 排序字段
- 联合查询字段（联合索引）

### 2.3 索引原则

- 最左前缀原则
- 避免冗余索引
- 控制索引数量（<5个）

```sql
-- Good: 联合索引最左前缀
INDEX idx_user_status (user_id, status)
-- 可匹配: user_id / user_id+status
-- 不可匹配: status

-- Bad: 冗余索引
INDEX idx_user_id (user_id)
INDEX idx_user_id_status (user_id, status)  -- 包含上面
```

---

## 3. 查询规范

### 3.1 SELECT

```sql
-- Good: 指定字段
SELECT id, name, email FROM users WHERE id = 1;

-- Bad: SELECT *
SELECT * FROM users WHERE id = 1;
```

### 3.2 WHERE

```sql
-- Good: 避免函数
SELECT * FROM users WHERE created_at > '2026-01-01';

-- Bad: 字段用函数
SELECT * FROM users WHERE DATE(created_at) = '2026-01-01';
```

### 3.3 分页

```sql
-- Good: 使用游标分页
SELECT * FROM users WHERE id > 1000 ORDER BY id LIMIT 20;

-- Bad: 大页码OFFSET
SELECT * FROM users ORDER BY id LIMIT 20 OFFSET 10000;
```

---

## 4. 迁移规范

### 4.1 文件命名

```
YYYYMMDDTmmss_description.sql

202604281030_create_users_table.sql
202604281045_add_user_index.sql
```

### 4.2 必须包含

- `UP` 迁移
- `DOWN` 回滚
- 事务包裹

```sql
-- 202604281030_create_users_table.sql

-- UP
BEGIN;

CREATE TABLE users (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email)
);

COMMIT;

-- DOWN
BEGIN;

DROP TABLE IF EXISTS users;

COMMIT;
```

### 4.3 禁止操作

- 直接修改已有字段类型
- 删除有数据的列
- 大表（>100万行）无锁变更

---

## 5. 安全规范

### 5.1 防注入

- 使用参数化查询
- 禁止字符串拼接 SQL

### 5.2 敏感数据

- 密码：bcrypt/scrypt 哈希
- 手机号/身份证：加密存储
- 日志：脱敏处理

---

**[← 返回规范体系](../README.md)**
