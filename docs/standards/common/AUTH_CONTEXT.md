# 用户会话上下文规范

> **2026-05-20 修订**: 生产链路统一采用 Java Auth + Java Gateway + Redis `UserSessionContext` + Go `PlatformAuthAdapter`。Java Auth/平台会话服务负责 token 校验、受限 session 签发/刷新、会话上下文写入和撤销；Java Gateway 负责统一入口、路由和 token relay；下游 Go 服务通过 `PlatformAuthAdapter` 按 token 从 Redis 恢复 `UserSessionContext` 并注入 `context.Context`。`X-User-*` 只能作为兼容或内部调试模式，不是正式鉴权主链路。

> **适用范围**: 所有与 AMDox Java 平台集成的 go-zero 服务
> **关联文档**: [DEPLOYMENT_STANDARDS.md](DEPLOYMENT_STANDARDS.md), [DATABASE_STANDARDS.md §8](DATABASE_STANDARDS.md)（多数据源规范）  
> **更新**: 2026-05-20（统一为 Java 平台身份源和 Go 语言适配）

---

## 0. 统一结论

1. 浏览器、宿主应用、Java Gateway、Go 微服务之间统一使用 `Authorization: Bearer <token>` 传递会话凭证。
2. Java Auth/平台会话服务是唯一身份源，负责 token introspection、受限 session 签发/刷新、Redis `UserSessionContext` 写入和撤销。
3. Java Gateway 负责统一北向入口、路由、跨域、限流、trace 和 token relay，不把 `X-User-*` 注入作为生产主链路。
4. Go 服务不从业务代码里解析 `X-User-*`，也不信任浏览器或调用方传来的用户字段；统一通过 `PlatformAuthAdapter` 从 Redis 恢复会话上下文并写入 `context.Context`。
5. 服务间调用 bypass Java Gateway 时仍必须透传 `Authorization`、`X-Trace-Id`、`Accept-Language`、`X-Time-Zone`、`X-Campus-Id`、`X-Client-Type`，被调服务按同一 Redis 会话上下文规则恢复用户。
6. 受限作用域 session token（历史上也称 Embed Session）不是独立用户体系，必须由 Java Auth/平台会话服务签发或确认，落 Redis 并映射到同一个 `UserSessionContext` 模型。
7. Redis value 必须是稳定 JSON 契约。Go `PlatformAuthAdapter` 不得把解析 Java 序列化对象作为正式方案；历史 Java 序列化 token 只能作为迁移期 fallback。
8. 新实现应使用 token hash/reference 作为 Redis key 后缀，例如 `amdox:auth:user:token:{sha256(token)}`；历史 `{token}` 形式仅作为兼容读取路径，不能在新代码中继续扩散。

目标上下文结构：

```go
type UserSessionContext struct {
    Active      bool     `json:"active"`
    Expired     bool     `json:"expired"`
    Reason      string   `json:"reason,omitempty"`
    TokenRef    string   `json:"tokenRef"`    // token hash/reference, never raw token
    ClientId    string   `json:"clientId,omitempty"`
    UserId      string   `json:"userId"`
    Username    string   `json:"username"`
    TenantId    string   `json:"tenantId"`
    OrgId       string   `json:"orgId,omitempty"`
    CampusId    string   `json:"campusId,omitempty"`
    Roles       []string `json:"roles,omitempty"`
    Permissions []string `json:"permissions,omitempty"`
    Locale      string   `json:"locale,omitempty"`
    TimeZone    string   `json:"timeZone,omitempty"`
    ClientType  string   `json:"clientType,omitempty"`
    HostApp     string   `json:"hostApp,omitempty"`     // lms/cube/mofang
    HostScene   string   `json:"hostScene,omitempty"`   // course/project/business
    ResourceId  string   `json:"resourceId,omitempty"`
    Scopes      []string `json:"scopes,omitempty"`
    ExpiresAt   int64    `json:"expiresAt"`
}
```

## 1. 会话机制概述

### 1.1 架构（统一鉴权 Redis 缓存模式）

```
┌─────────────┐      ┌──────────────────────┐      ┌──────────────────────┐
│   前端       │ ───▶ │ Java campusmgmt       │ ───▶ │ Go amdox-go-netdisk   │
│  (Vue3/LMS) │      │ Gateway               │      │ PlatformAuthAdapter   │
└─────────────┘      └──────────────────────┘      └──────────────────────┘
        │                      │                              │
        │ Authorization        │ Token relay                  │ Redis GET
        │ Bearer <token>       │ (不注入用户 Header)           │ (读取 UserSessionContext)
        │                      ▼                              │
        │             ┌──────────────────────┐                │
        └────────────▶│ Java Auth / Platform │                │
                      │ Session Service      │                │
                      └──────────────────────┘                │
                                  │                           │
                                  ▼                           │
                      ┌──────────────────────┐                │
                      │ Redis                │◀───────────────┘
                      │ UserSessionContext   │
                      └──────────────────────┘
```

### 1.2 流程（Redis 缓存模式）

1. **登录**: 用户在 Java Auth 完成登录，获取平台 token。
2. **Token**: 前端请求携带 `Authorization: Bearer <token>`；URL token 只允许兼容读取并立即清理。
3. **Java Gateway 入口**: Java Gateway 执行统一路由、跨域、限流、trace 和 token relay。
4. **Java Auth 校验**: Java Gateway 调用 Java Auth/平台会话服务完成 token introspection 或受限 session 签发/刷新。
5. **Redis 上下文**: Java Auth/平台会话服务将用户、租户、角色、权限、客户端、宿主上下文写入 Redis `UserSessionContext`。
   - Key: Java 平台 token/session context key，推荐 `{prefix}{sha256(token)}`。
   - Value: 稳定 JSON `UserSessionContext`，只保存 `tokenRef`，不保存明文 token。
   - TTL: 与 token/session 一致。
6. **Token 透传**: Java Gateway 将原始 `Authorization` 透传给 Go Netdisk。
7. **Go 适配读取**: Go `PlatformAuthAdapter` 按 token reference 从 Redis 读取 `UserSessionContext`，必要时调用 Java Auth introspection fallback，并注入 `context.Context`。

### 1.3 鉴权模式对比

| 模式 | 行为 | 推荐 |
|------|------|------|
| **Java 平台 Redis 上下文模式** | Java Auth/平台会话服务写入 → Go `PlatformAuthAdapter` 读取 | ✅ 生产环境 |
| **Header 信任模式** | Gateway 注入 `X-User-*` Header → 下游读取 Header | 仅兼容/调试，不作为生产主链路 |

---

## 2. Redis 缓存规范（多 Redis 分组模式）

### 2.1 Redis 分组设计

> **参考**: [DATABASE_STANDARDS.md §8.2](DATABASE_STANDARDS.md)（多 Redis 设计）

认证 Redis 与业务 Redis 分离，避免 Key 冲突和职责混淆：

| Redis 分组 | DB | 用途 | Key 前缀 |
|-----------|----|----|---------|
| Redis.Auth | 0 | Java Auth/平台会话服务写入的 token/session 上下文（Netdisk 只读取） | `amdox:auth:user:token:` 或 Java 平台配置 |
| Redis.Business | 0 | 业务数据缓存 | `amdox:netdisk:` |
| Redis.Cache | 2 | 通用缓存（可选） | `amdox:netdisk:cache:` |

**配置示例**（Nacos）:

```yaml
Redis:
  # 业务 Redis（默认）
  Business:
    Host: campusmgmt-redis
    Port: 6379
    DB: 0
  
  # 认证 Redis（与 Gateway 共享）
  Auth:
    Host: campusmgmt-redis
    Port: 6379
    DB: 0
    KeyPrefix: "amdox:auth:user:token:"
```

### 2.2 Key 设计

| 配置项 | 值 | 来源 |
|--------|-----|------|
| KeyPrefix | `amdox:auth:user:token:` | Redis.Auth.KeyPrefix |
| Key 格式 | `{KeyPrefix}{sha256(token)}` | 示例: `amdox:auth:user:token:8d7f...`；历史 `{token}` 仅兼容读取 |
| Value | JSON | `UserSessionContext`，只保存 `tokenRef`，不保存明文 token |
| TTL | 300 秒（5 分钟） | Gateway 配置 |

### 2.3 配置职责分离

| 配置类型 | 加载位置 | 示例 |
|----------|----------|------|
| Redis 连接 | 本地 YAML | `Redis.Host/Port/Password` |
| KeyPrefix | Nacos 业务配置 | `Redis.Auth.KeyPrefix` |

**Gateway 配置** (`gateway.yaml`):
```yaml
Auth:
  URL: "http://localhost:9110"
  ServiceName: "amdox.go.auth.api"  # Nacos 发现
  Redis:
    Host: campusmgmt-redis
    Port: 6379
    Password: "Amdox@rd_2024"
    DB: 0  # 使用 Auth Redis（DB 0）
    KeyPrefix: "amdox:auth:user:token:"
    TTL: 300
```

**Netdisk 配置** (Nacos):
```yaml
Redis:
  Auth:
    Host: campusmgmt-redis
    Port: 6379
    DB: 0
    KeyPrefix: "amdox:auth:user:token:"
```

### 2.4 多 Redis 使用示例

```go
// 认证缓存 → Auth Redis（DB 0）
tokenKey := svc.AuthRedisKey + sha256Token(token)
userData, err := svc.RedisMgr.Auth.Get(tokenKey)

// 业务缓存 → Business Redis（DB 0）
cacheKey := "amdox:netdisk:cloud_accounts:" + userId
accountData, err := svc.RedisMgr.Business.Get(cacheKey)
```

---

## 3. Nacos 服务发现配置

### 3.1 Java Gateway 配置 (`campusmgmt-gateway`)

```yaml
server:
  port: 9999

spring:
  application:
    name: campusmgmt-gateway
  cloud:
    nacos:
      discovery:
        server-addr: ${NACOS_HOST:campusmgmt-register}:${NACOS_PORT:8848}
      config:
        server-addr: ${spring.cloud.nacos.discovery.server-addr}
  config:
    import:
      - optional:nacos:application-${spring.profiles.active}.yml
      - optional:nacos:${spring.application.name}-${spring.profiles.active}.yml
```

Java Gateway route、CORS、限流、白名单和 token relay 以 Java 平台 Nacos 配置为准。Netdisk 只登记路由和下游服务，不把 Go Gateway 作为生产主入口。

### 3.2 Java Auth / Platform Session

```yaml
platformSession:
  redisContext:
    keyPrefix: "amdox:auth:user:token:"
    keyMode: "sha256"
    valueFormat: "json"
  introspection:
    responseContract: "CampusmgmtTokenIntrospectionInfo + HostContext"
```

Java Auth 是正式身份源。Go Auth 仅允许作为迁移期兼容适配，不得作为新生产链路的认证中心。

### 3.3 端口规范

| 服务 | 端口范围 | 当前端口 |
|------|----------|----------|
| campusmgmt-gateway | 平台配置 | 9999 |
| campusmgmt-auth | 平台配置 | 以 Java 平台 Nacos/部署配置为准 |
| netdisk-api | 9100-9109 | 9100 |
| go-gateway | 9090-9099 | 9090，迁移期兼容 |
| go-auth | 9110-9119 | 9110，迁移期兼容 |

---

## 4. Nacos 配置中心

### 4.1 配置加载流程

Go Netdisk 必须支持 Nacos 配置中心；Go Gateway/Auth 配置仅作为迁移期兼容链路保留：

```
本地 YAML（基础设施配置）
  → Host/Port（服务监听地址）
  → NacosNaming（服务注册）
  → Nacos（配置中心连接信息）
  
Nacos（业务配置，热更新）
  → Java Gateway: route、CORS、rate limit、token relay
  → Java Auth: token introspection、platform session、Redis UserSessionContext
  → Netdisk: PlatformAuthAdapter、OAuth/driver 配置
```

### 4.2 Go Gateway 兼容配置 (`gateway.yaml`)

本节仅适用于迁移期本地联调或兼容链路。生产主链路使用 Java `campusmgmt-gateway`。

```yaml
# Nacos 配置中心（业务配置热更新）
# 本地 YAML 仅含基础设施配置
# 业务配置从 Nacos DataId 加载
Nacos:
  IpAddr: "campusmgmt-register"
  Port: 8848
  NamespaceId: "TEST"
  Group: "TEST_GROUP"
  DataId: "amdox-go-gateway.yml"
  Username: "nacos"
  Password: "nacos"
```

**迁移期 Nacos 业务配置示例** (`amdox-go-gateway.yml`):
```yaml
# Auth 中间件配置（使用 Redis.Auth 分组）
Auth:
  URL: "http://localhost:9110"  # fallback 地址
  IntrospectPath: "/token/introspect-user"
  Timeout: 5
  ServiceName: "amdox.go.auth.api"  # Nacos 服务发现
  # Redis 配置已迁移到 Redis.Auth 分组（兼容旧配置保留）
  Redis:
    Host: campusmgmt-redis
    Port: 6379
    Password: "Amdox@rd_2024"
    DB: 0
    KeyPrefix: "amdox:auth:user:token:"
    TTL: 300

# 多 Redis 实例配置（分组模式）
Redis:
  Business: { Host: campusmgmt-redis, Port: 6379, Password: "...", DB: 0 }
  Auth: { Host: campusmgmt-redis, Port: 6379, Password: "...", DB: 0, KeyPrefix: "...", TTL: 300 }
  Cache: { Host: campusmgmt-redis, Port: 6379, Password: "...", DB: 2 }

# 后端服务路由（使用 Nacos 服务发现）
Upstreams:
  - Name: auth-host-session
    Prefix: /api/v1/host/session
    NacosServiceName: amdox.go.auth.api
  - Name: netdisk-api
    Prefix: /api/v1/
    NacosServiceName: amdox.go.netdisk.api  # 从 Nacos 发现

# CORS 跨域配置
CORS:
  AllowOrigins: ["*"]
  AllowMethods: [GET, POST, PUT, DELETE, OPTIONS]
  AllowHeaders: [Authorization, Content-Type, X-Request-Id]
```

### 4.3 Go Auth 兼容配置 (`auth-api.yaml`)

本节仅适用于迁移期兼容。正式 token introspection 和平台会话上下文以 Java Auth/平台会话服务为准。

```yaml
# Nacos 配置中心（业务配置热更新）
# TestTokens、Redis 等业务配置从 Nacos 加载
Nacos:
  IpAddr: "campusmgmt-register"
  Port: 8848
  NamespaceId: "TEST"
  Group: "TEST_GROUP"
  DataId: "amdox-go-auth.yml"
  Username: "nacos"
  Password: "nacos"
```

**迁移期 Nacos 业务配置示例** (`amdox-go-auth.yml`):
```yaml
# 测试用 Token 配置（生产环境应使用数据库/Redis）
TestTokens:
  - Token: "test-token-admin"
    UserId: 1
    Username: "admin"
    Name: "管理员"
    Nickname: "超级管理员"
    TenantId: 1
    Roles: ["admin", "user"]
    Permissions: ["*"]
  - Token: "test-token-user"
    UserId: 2
    Username: "testuser"
    Name: "测试用户"
    Nickname: "普通用户"
    TenantId: 1
    Roles: ["user"]
    Permissions: ["file:read", "file:write"]

# 多 Redis 实例配置（分组模式，与 Gateway/Netdisk 保持一致）
Redis:
  # 业务 Redis（Auth 服务可能不需要）
  Business:
    Host: campusmgmt-redis
    Port: 6379
    Password: "Amdox@rd_2024"
    DB: 0

  # 认证 Redis（与 Gateway 共享，用于 Token 缓存）
  Auth:
    Host: campusmgmt-redis
    Port: 6379
    Password: "Amdox@rd_2024"
    DB: 0
    KeyPrefix: "amdox:auth:user:token:"
    TTL: 300

  # 缓存 Redis（可选）
  Cache:
    Host: campusmgmt-redis
    Port: 6379
    Password: "Amdox@rd_2024"
    DB: 2
```

### 4.4 Netdisk 配置 (`netdisk-api.yaml`)

```yaml
# Nacos 配置中心（业务配置热更新）
Nacos:
  IpAddr: "campusmgmt-register"
  Port: 8848
  NamespaceId: "TEST"
  Group: "TEST_GROUP"
  DataId: "amdox-go-netdisk.yml"
  Username: "nacos"
  Password: "nacos"
```

**Nacos 业务配置示例** (`amdox-go-netdisk.yml`):
```yaml
# Auth 缓存 Key 前缀（从 Redis 读取用户信息）
AuthCenter:
  RedisKeyPrefix: "amdox:auth:user:token:"
  Timeout: 5

# OAuth 配置
Netdisk:
  Baidu:
    ClientId: "your-client-id"
    ClientSecret: "your-client-secret"
    RedirectUri: "http://localhost:9100/oauth/baidu/callback"
  Google:
    ClientId: "your-client-id"
    ClientSecret: "your-client-secret"
    RedirectUri: "http://localhost:9100/oauth/google/callback"
```

### 4.5 配置职责分离

| 配置类型 | 加载位置 | 示例 |
|----------|----------|------|
| 基础设施配置 | 本地 YAML | Host/Port、Nacos 连接、服务注册 |
| 业务配置 | Nacos | TestTokens、Auth.Redis、OAuth 配置 |

---

## 5. 用户信息结构（下游服务）

```go
// pkg/context/user.go
package context

type UserInfo struct {
    ID       int64  `json:"id"`
    Username string `json:"username"`
    Name     string `json:"name"`
    Nickname string `json:"nickname"`
    TenantId int64  `json:"tenantId"`
}

type ContextKey string

const UserContextKey ContextKey = "user_info"

func GetUser(ctx context.Context) (*UserInfo, bool) {
    user, ok := ctx.Value(UserContextKey).(*UserInfo)
    return user, ok
}

func SetUser(ctx context.Context, user *UserInfo) context.Context {
    return context.WithValue(ctx, UserContextKey, user)
}
```

---

## 6. PlatformAuthAdapter 实现

### 6.1 Java Gateway / Java Auth 职责

```text
Java Gateway
  1. 接收浏览器/LMS 请求
  2. 保留并透传 Authorization
  3. 调用 Java Auth/平台会话服务做 token introspection 或 session refresh
  4. 确认 Redis UserSessionContext 已写入或刷新
  5. 路由到 Go Netdisk

Java Auth / Platform Session
  1. 校验 token/session
  2. 生成稳定 JSON UserSessionContext
  3. 按 Java 平台 Redis key contract 写入 Redis
  4. 支持 TTL、刷新、撤销、下线和审计
```

### 6.2 Go PlatformAuthAdapter

```go
// netdisk/internal/middleware/platformauth/auth.go
func PlatformAuthAdapter(cfg Config, resolver ContextResolver) func(http.HandlerFunc) http.HandlerFunc {
    return func(next http.HandlerFunc) http.HandlerFunc {
        return func(w http.ResponseWriter, r *http.Request) {
            // 1. Extract token from Authorization.
            token := extractToken(r)
            if token == "" {
                writeUnauthorized(w, "AUTH_MISSING")
                return
            }

            // 2. Resolve Java platform session context from Redis.
            session, err := resolver.Resolve(r.Context(), token)
            if err != nil || !session.Active || session.Expired {
                writeUnauthorized(w, stableAuthCode(err, session))
                return
            }

            // 3. Inject the platform context into Go context.Context.
            ctx := appctx.SetUserSession(r.Context(), session)
            next(w, r.WithContext(ctx))
        }
    }
}
```

`ContextResolver` 的顺序:

1. 使用 Java 平台 key contract 读取 Redis JSON `UserSessionContext`。
2. Redis miss 时，可调用 Java Auth introspection fallback。
3. fallback 成功后由 Java Auth/平台会话服务刷新 Redis；Go 不自行创建平台身份。
4. 只允许迁移期兼容读取旧 Go cache key；兼容路径必须有退出计划。

---

## 7. 在 Logic 中使用

```go
// logic/filelistlogic.go
func (l *FileListLogic) FileList(req *types.FileListRequest) (*types.FileListResponse, error) {
    // 从 context 获取用户信息（Redis 缓存注入）
    user, ok := context.GetUser(l.ctx)
    if !ok {
        return nil, errors.New("unauthorized: user context not set")
    }
    
    // 使用 user.ID 查询该用户的文件
    files, err := l.svcCtx.FileModel.FindByUserId(l.ctx, user.ID, req.Path)
    // ...
}
```

---

## 8. 服务间调用

**原则**: 服务间调用 bypass Gateway，Token 放 HTTP Header。

```
服务 A → 服务 B（直连）
  │
  │ Header: Authorization: Bearer {token}
  │
  └─▶ 服务 B → Redis GET → Context 注入
```

---

## 9. 安全要点

1. **Java Auth 统一校验**: Java Auth/平台会话服务是身份源，下游服务从 Redis 读取稳定上下文
2. **Token 校验**: Redis 缓存中只保存 token hash/reference，下游按当前请求 token hash 恢复并校验上下文
3. **Nacos 服务发现**: 动态发现 Java Gateway、Java Auth 和 Go Netdisk 地址，避免硬编码
4. **Fallback URL**: 仅允许迁移期或故障降级配置，必须有超时和审计
5. **缓存 TTL**: Redis 缓存 5 分钟自动过期
6. **配置分离**: 基础设施配置（本地 YAML）vs 业务配置（Nacos）

---

## 10. 检查清单

- [ ] Java Gateway route、CORS、限流、白名单和 token relay 配置正确
- [ ] Java Auth/平台会话服务 token introspection、session refresh、Redis 写入和撤销配置正确
- [ ] Java 平台 Redis `UserSessionContext` key contract 与 Go `PlatformAuthAdapter` 配置一致
- [ ] Go Gateway/Auth 如仍存在，仅作为迁移期兼容并有退出计划
- [ ] Netdisk `Nacos.DataId` 配置正确（`amdox-go-netdisk.yml`）
- [ ] Netdisk `ServiceName` 配置正确（`amdox.go.netdisk.api`）
- [ ] Redis 连接正常（`Redis.Host/Port/Password`）
- [ ] 下游服务 `PlatformAuthAdapter` key prefix、hash mode、fallback introspection 配置正确
- [ ] 下游服务复用统一 Redis client/manager，不在业务逻辑里新增临时认证 Redis
- [ ] Token 从 `Authorization` header 提取；URL token 仅兼容读取并立即清理
- [ ] Nacos 配置中心配置文件已创建，并明确 Java 平台主链路与 Go 兼容链路边界
