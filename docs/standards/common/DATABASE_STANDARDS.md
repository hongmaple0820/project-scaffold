# 通用数据库规范

**版本**: v1.1  
**适用范围**: 所有项目（MySQL + 多数据源）
**更新**: 2026-05-07（添加多数据源规范，参考 gfast 分组模式）

---

## 1. 建表规范

### 1.1 字符集和引擎

**强制**:
```sql
ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='表中文说明'
```

- `InnoDB`：支持事务、行级锁、外键
- `utf8mb4`：完整支持Unicode（包括emoji）

### 1.2 建表模板

#### 后台业务表模板

```sql
CREATE TABLE `netdisk_xxx` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  
  -- 业务字段在此添加
  
  `create_by` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '创建人ID',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_by` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '修改人ID',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `del_flag` TINYINT NOT NULL DEFAULT 0 COMMENT '删除标记：0-未删除 1-已删除',
  
  PRIMARY KEY (`id`),
  KEY `idx_netdisk_xxx_del_flag` (`del_flag`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='表中文说明';
```

#### 系统/日志/中间表模板

```sql
CREATE TABLE `netdisk_xxx_log` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  
  -- 业务字段在此添加
  
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `del_flag` TINYINT NOT NULL DEFAULT 0 COMMENT '删除标记：0-未删除 1-已删除',
  
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='日志表说明';
```

---

## 2. 字段设计规范

### 2.1 主键设计

**强制**: 使用自增ID
```sql
`id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键ID'
```

**禁止**: UUID、复合主键、业务字段作为主键

### 2.2 数据类型选择

| 场景 | 推荐类型 | 说明 |
|------|----------|------|
| 主键 | BIGINT UNSIGNED | 自增 |
| 用户ID | BIGINT UNSIGNED | 与主键一致 |
| 状态/标记 | TINYINT | 0/1/2等枚举值 |
| 布尔值 | TINYINT(1) | 0=false, 1=true |
| 小整数 | SMALLINT | -32768 ~ 32767 |
| 整数 | INT | 一般计数 |
| 大整数 | BIGINT | 金额计算（以分为单位） |
| 定长字符串 | CHAR(n) | 固定长度，如手机号 |
| 短字符串 | VARCHAR(20-100) | 有明确长度限制 |
| 中字符串 | VARCHAR(255) | 一般名称 |
| 长字符串 | VARCHAR(500-2000) | 路径、URL等 |
| 大文本 | TEXT | JSON、描述等 |
| 日期时间 | DATETIME | 无时区问题 |
| 时间戳 | TIMESTAMP | 需要时区转换 |
| 浮点数 | DECIMAL(m,d) | 精确计算 |
| JSON | JSON | MySQL 5.7+ |

### 2.3 字段约束

**强制默认值**:
- 所有字段尽量设置默认值
- 禁止NULL（特殊情况除外）
- 字符串默认`''`或`NULL`
- 数值默认`0`

**示例**:
```sql
`status` TINYINT NOT NULL DEFAULT 1 COMMENT '状态'
`name` VARCHAR(100) NOT NULL DEFAULT '' COMMENT '名称'
`description` VARCHAR(500) DEFAULT NULL COMMENT '描述（可为空）'
```

### 2.4 常用字段定义

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `id` | BIGINT UNSIGNED | AUTO_INCREMENT | 主键 |
| `create_by` | BIGINT UNSIGNED | 0 | 创建人 |
| `create_time` | DATETIME | CURRENT_TIMESTAMP | 创建时间 |
| `update_by` | BIGINT UNSIGNED | 0 | 修改人 |
| `update_time` | DATETIME | ON UPDATE | 更新时间 |
| `del_flag` | TINYINT | 0 | 删除标记 |
| `remark` | VARCHAR(500) | NULL | 备注 |
| `sort_order` | INT | 0 | 排序号 |

---

## 3. 索引设计规范

### 3.1 索引命名

| 类型 | 前缀 | 示例 |
|------|------|------|
| 主键 | `PRIMARY` | PRIMARY KEY (`id`) |
| 唯一索引 | `uk_<表名>_<字段>` | `uk_netdisk_account_user_name` |
| 普通索引 | `idx_<表名>_<字段>` | `idx_netdisk_task_user_status` |
| 全文索引 | `ft_<表名>_<字段>` | `ft_netdisk_file_name` |

### 3.2 必须创建索引的场景

1. **主键**：自动创建聚簇索引
2. **外键**：必须创建索引（InnoDB建议）
3. **WHERE条件字段**：高频查询条件
4. **ORDER BY字段**：排序字段
5. **GROUP BY字段**：分组字段
6. **JOIN关联字段**：关联查询字段
7. **唯一约束**：业务唯一性字段

### 3.3 联合索引设计

**字段顺序原则**（从左到右）：
1. 等值查询字段（区分度高的在前）
2. 范围查询字段
3. 排序字段
4. 查询但不排序的字段

**示例**:
```sql
-- 查询条件：WHERE user_id = ? AND status = ? ORDER BY create_time DESC
-- 正确：把区分度高的user_id放前面
KEY `idx_netdisk_task_user_status_time` (`user_id`, `status`, `create_time`)

-- 错误：把区分度低的status放前面
KEY `idx_netdisk_task_status_user_time` (`status`, `user_id`, `create_time`)
```

### 3.4 索引数量控制

- 单表索引不超过5个
- 单个索引字段数不超过3个
- 单表字段数不超过30个

### 3.5 索引优化提示

**适合索引**:
- 区分度高的字段（如user_id）
- 查询频繁的字段
- 有明确业务唯一性要求的字段

**不适合索引**:
- 区分度低的字段（如status只有0/1）
- 频繁更新的字段
- 大文本字段（使用全文索引）
- 很少查询的字段

---

## 4. 查询规范

### 4.1 SELECT语句

**禁止**:
```sql
SELECT * FROM table  -- 查询所有字段
```

**推荐**:
```sql
SELECT id, name, status FROM table WHERE id = 1
```

### 4.2 WHERE条件

**强制索引使用**:
```sql
-- 确保能使用索引
WHERE user_id = 1 AND del_flag = 0

-- 避免索引失效
WHERE YEAR(create_time) = 2024  -- 函数导致索引失效
-- 改为：
WHERE create_time >= '2024-01-01' AND create_time < '2025-01-01'
```

### 4.3 分页查询

**深分页优化**:
```sql
-- 低效（偏移量大时）
SELECT * FROM table LIMIT 100000, 10

-- 优化（使用覆盖索引）
SELECT t.* FROM table t
INNER JOIN (
    SELECT id FROM table ORDER BY id LIMIT 100000, 10
) tmp ON t.id = tmp.id
```

### 4.4 批量操作

**批量插入**:
```sql
INSERT INTO table (col1, col2) VALUES (1, 2), (3, 4), (5, 6)
-- 每批不超过1000条
```

**批量更新**:
```sql
-- 使用CASE WHEN
UPDATE table SET 
    status = CASE id 
        WHEN 1 THEN 2 
        WHEN 2 THEN 3 
    END
WHERE id IN (1, 2)
```

---

## 5. 表结构变更规范

### 5.1 变更类型

| 类型 | 风险 | 说明 |
|------|------|------|
| 添加字段 | 低 | 对现有数据无影响 |
| 添加索引 | 中 | 大表会锁表 |
| 修改字段类型 | 高 | 可能导致数据截断 |
| 删除字段 | 高 | 可能导致业务异常 |
| 删除表 | 极高 | 数据丢失 |

### 5.2 变更流程

1. **评估影响**：数据量、并发量、业务影响
2. **编写脚本**：包含回滚方案
3. **测试验证**：在测试环境验证
4. **灰度执行**：先在小表/低峰期执行
5. **监控观察**：观察业务指标

### 5.3 DDL脚本模板

```sql
-- ============================================
-- 变更描述：添加xxx字段
-- 执行人：xxx
-- 执行时间：2025-04-28
-- 回滚方案：ALTER TABLE xxx DROP COLUMN xxx
-- ============================================

-- 检查是否存在
SET @exist := (SELECT COUNT(*) FROM information_schema.columns 
               WHERE table_name = 'netdisk_xxx' AND column_name = 'new_column');

-- 条件执行
SET @sql := IF(@exist = 0, 
    'ALTER TABLE netdisk_xxx ADD COLUMN new_column VARCHAR(100) DEFAULT NULL COMMENT "新字段"',
    'SELECT "Column already exists"');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 添加索引（如需要）
-- CREATE INDEX idx_netdisk_xxx_new_column ON netdisk_xxx(new_column);
```

---

## 6. 安全规范

### 6.1 敏感数据加密

| 数据类型 | 存储方式 | 示例 |
|----------|----------|------|
| 密码 | bcrypt哈希 | 不可逆 |
| Token | AES加密 | 可解密使用 |
| 身份证号 | AES加密或脱敏 | 展示时脱敏 |
| 手机号 | 中间四位脱敏 | 138****8888 |

### 6.2 SQL注入防护

**禁止字符串拼接SQL**:
```go
// 错误
query := "SELECT * FROM user WHERE name = '" + name + "'"

// 正确
query := "SELECT * FROM user WHERE name = ?"
db.Query(query, name)
```

### 6.3 数据备份

- 每日全量备份
- Binlog保留7天
- 定期恢复演练

---

## 7. 性能优化规范

### 7.1 慢查询处理

1. 开启慢查询日志（>1秒）
2. 定期分析慢查询
3. 添加索引或优化SQL
4. 验证优化效果

### 7.2 大表处理

| 表大小 | 处理方式 |
|--------|----------|
| < 100万 | 正常处理 |
| 100万-1000万 | 注意索引优化 |
| > 1000万 | 考虑分表或归档 |

### 7.3 连接数管理

- 应用层使用连接池
- 最大连接数根据服务器配置调整
- 及时释放空闲连接

---

## 8. 多数据源规范（参考 gfast 分组模式）

> **适用场景**: 需要读写分离、分库分表、Redis 缓存分离的项目  
> **参考项目**: gfast (`F:\project\netdisk-project\gfast`)

### 8.1 多数据库设计

**分组模式**（参考 gfast `database.default/user/log` 分组）:

```yaml
Database:
  # 主库（必须，写操作）
  Default:
    Type: "mysql"
    MySQL:
      DataSource: "user:pass@tcp(host:port)/db?charset=utf8mb4&parseTime=true"
    Enabled: true
  
  # 只读副本（可选，读操作）
  ReadReplica:
    Enabled: true
    Type: "mysql"
    MySQL:
      DataSource: "user:pass@tcp(read-replica:port)/db?charset=utf8mb4"
  
  # 日志库（可选，分离日志存储）
  Log:
    Enabled: false
    Type: "mysql"
    MySQL:
      DataSource: "user:pass@tcp(host:port)/db_log?charset=utf8mb4"
  
  # 用户库（可选，分库）
  User:
    Enabled: false
    Type: "mysql"
    MySQL:
      DataSource: "user:pass@tcp(host:port)/db_user?charset=utf8mb4"
```

**DatabaseManager 结构**:

```go
type DatabaseManager struct {
    Primary sqlx.SqlConn  // 主库（Default，写操作）
    Replica sqlx.SqlConn  // 副本（ReadReplica，读操作）
    Log     sqlx.SqlConn  // 日志库（Log，可选）
    User    sqlx.SqlConn  // 用户库（User，可选）
}
```

### 8.2 多 Redis 设计

**分组模式**（参考 gfast `redis.default` 分组）:

```yaml
Redis:
  # 业务 Redis（默认）
  Business:
    Host: redis-host
    Port: 6379
    Password: ""
    DB: 0        # 业务数据
    Timeout: "10s"
  
  # 认证 Redis（与 Gateway 共享）
  Auth:
    Host: redis-host
    Port: 6379
    Password: ""
    DB: 0        # 认证会话上下文，与 Java Auth/平台会话服务保持一致
    KeyPrefix: "amdox:auth:user:token:"
  
  # 缓存 Redis（可选，分离缓存层）
  Cache:
    Host: redis-host
    Port: 6379
    Password: ""
    DB: 2        # 通用缓存
  
  # 会话 Redis（可选）
  Session:
    Host: redis-host
    Port: 6379
    Password: ""
    DB: 3        # 用户会话
```

**RedisManager 结构**:

```go
type RedisManager struct {
    Business *redis.Redis  // 业务缓存（DB 0）
    Auth     *redis.Redis  // 认证缓存（DB 0）
    Cache    *redis.Redis  // 通用缓存（DB 2）
    Session  *redis.Redis  // 用户会话（DB 3，可选）
}
```

### 8.3 读写分离规范

**原则**:
- **写操作** → 主库（`Primary`）
- **读操作** → 副本（`Replica`，如果有）
- **副本不可用** → fallback 到主库

**使用方式**:

```go
// 1. 写操作 → 主库
err := svc.DBMgr.Primary.TransactFn(ctx, func(ctx context.Context, tx sqlx.SqlConn) error {
    // INSERT/UPDATE/DELETE
    _, err := tx.ExecCtx(ctx, "INSERT INTO table ...")
    return err
})

// 2. 读操作 → 副本（如果有）
var results []*Model
if svc.DBMgr.Replica != nil {
    // 使用副本库
    err = svc.DBMgr.Replica.QueryRowsCtx(ctx, &results, "SELECT ...")
} else {
    // fallback 到主库
    err = svc.DBMgr.Primary.QueryRowsCtx(ctx, &results, "SELECT ...")
}

// 3. 读失败 → fallback（副本可能延迟或故障）
if err != nil && svc.DBMgr.Replica != nil {
    logx.Warnf("副本库查询失败，fallback 到主库: %v", err)
    err = svc.DBMgr.Primary.QueryRowsCtx(ctx, &results, "SELECT ...")
}
```

### 8.4 Redis 分离规范

**用途分配**:

| Redis 分组 | DB | 用途 | 示例 Key |
|-----------|----|----|---------|
| Business | 0 | 业务数据缓存 | `amdox:netdisk:cloud_accounts:{userId}` |
| Auth | 0 | 认证会话上下文（与 Java Auth/Gateway/Go Netdisk 共享） | `amdox:auth:user:token:{sha256(token)}` |
| Cache | 2 | 通用缓存（临时计算结果） | `amdox:netdisk:stats:{userId}` |
| Session | 3 | 用户会话数据（可选） | `amdox:session:{sessionId}` |

**使用方式**:

```go
// 1. 认证缓存 → Auth Redis
tokenKey := svc.AuthRedisKey + sha256Token(token)
userData, err := svc.RedisMgr.Auth.Get(tokenKey)

// 2. 业务缓存 → Business Redis
cacheKey := "amdox:netdisk:cloud_accounts:" + userId
accountData, err := svc.RedisMgr.Business.Get(cacheKey)
if err != nil {
    // 缓存未命中 → 从数据库读取 → 写入缓存
    accounts, _ := svc.NetdiskCloudAccountModel.FindByUserId(ctx, userId)
    _ = svc.RedisMgr.Business.Setex(cacheKey, marshal(accounts), 600) // 10分钟
}

// 3. 通用缓存 → Cache Redis（如果有独立缓存层）
if svc.RedisMgr.Cache != nil {
    svc.RedisMgr.Cache.Setex("amdox:netdisk:stats:"+userId, "100", 300)
} else {
    // 复用 Business Redis
    svc.RedisMgr.Business.Setex("amdox:netdisk:stats:"+userId, "100", 300)
}
```

### 8.5 向下兼容规范

**保留旧字段**（ServiceContext）:

```go
type ServiceContext struct {
    // 多数据源管理器（新代码使用）
    DBMgr    *DatabaseManager
    RedisMgr *RedisManager
    
    // 兼容旧代码（指向 Primary 和 Business）
    SqlConn     sqlx.SqlConn  // → DBMgr.Primary
    RedisClient *redis.Redis  // → RedisMgr.Business
}
```

**兼容性保证**:
- 现有代码无需修改（继续使用 `SqlConn` 和 `RedisClient`）
- 新代码使用 `DBMgr` 和 `RedisMgr` 实现读写分离

### 8.6 配置加载规范

**Nacos 配置分层**:

| 配置项 | 位置 | 说明 |
|-------|------|------|
| Nacos 连接信息 | 本地 YAML | 基础设施配置（不变化） |
| Database 分组 | Nacos | 业务配置（可热更新） |
| Redis 分组 | Nacos | 业务配置（可热更新） |

**示例**（`amdox-go-netdisk.yml` on Nacos）:

```yaml
# 多数据库配置
Database:
  Default: { Type: "sqlite", SQLite: { Path: "./data/netdisk.db" } }
  ReadReplica: { Enabled: false }
  Log: { Enabled: false }

# 多 Redis 配置
Redis:
  Business: { Host: campusmgmt-redis, Port: 6379, DB: 0 }
  Auth: { Host: campusmgmt-redis, Port: 6379, DB: 0, KeyPrefix: "amdox:auth:user:token:" }
  Cache: { Host: campusmgmt-redis, Port: 6379, DB: 2 }
```

### 8.7 扩展规范

**新增数据库分组**:

```yaml
# 配置层（Nacos）
Database:
  Order:
    Enabled: true
    Type: "mysql"
    MySQL: { DataSource: "..." }
```

```go
// Config 结构体
type Config struct {
    Database struct {
        Order DatabaseGroup `json:"order,optional"`
    }
}

// ServiceContext 初始化
if c.Database.Order.Enabled {
    dbMgr.Order = initDatabaseGroup(c.Database.Order, "order")
}
```

**新增 Redis 分组**:

同理，在 Config 和 RedisManager 中添加对应字段。

---

## 9. 数据库类型切换规范

### 9.1 MySQL → SQLite 切换

**适用场景**: 开发环境、小型部署、单元测试

**配置方式**:

```yaml
Database:
  Default:
    Type: "sqlite"  # 切换为 sqlite
    SQLite:
      Path: "./data/netdisk.db"
    MySQL:
      DataSource: "..."  # 保留 MySQL 配置（备选）
```

**代码适配**:

```go
func initDatabaseGroup(group DatabaseGroup) sqlx.SqlConn {
    switch group.Type {
    case "mysql":
        return sqlx.NewMysql(group.MySQL.DataSource)
    case "sqlite":
        return initSQLite(group.SQLite.Path)
    default:
        return initSQLite("./data/default.db")
    }
}
```

### 9.2 SQLite 限制

| 特性 | MySQL | SQLite |
|------|-------|--------|
| 并发写入 | 支持 | 单写进程 |
| 外键约束 | 默认启用 | 需显式开启 |
| 事务隔离 | 多级别 | SERIALIZABLE |
| 索引类型 | B-Tree/Hash | B-Tree |
| 存储限制 | TB级 | GB级 |

**建议**:
- 开发环境：SQLite（快速启动）
- 生产环境：MySQL（高并发、大数据量）

---
