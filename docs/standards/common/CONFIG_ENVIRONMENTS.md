# Configuration and Environment Isolation Standard

**Version**: v1.1
**Date**: 2026-05-19
**Scope**: SyncNest Hub (netdisk-project) 全部产品服务 — 后端、网关、前端、Nacos、Redis、DB、第三方服务

---

## 1. Environment Set

| Environment | Purpose | 启动方式 |
| --- | --- | --- |
| `local` | 本地开发，零外部依赖 | `./netdisk.ps1 start` 或 `./netdisk.ps1 start local` |
| `dev` | 连接 TEST Nacos/Redis 的本地联调，不启动 Docker | `./netdisk.ps1 start dev` |
| `full` | 本地 Docker 基础设施全栈联调 | `./netdisk.ps1 start full` |
| `test` | 共享测试环境 | CI/CD 部署 |
| `prod` | 生产环境 | CI/CD 部署 |
| `sg-test` | 海外测试 | CI/CD 部署 |
| `sg-prod` | 海外生产 | CI/CD 部署 |

本地运行环境分为 `local`、`dev` 和 `full` 三种模式：

| | 轻量开发 | TEST 联调 | 本地全栈 |
|---|---|---|---|
| 配置后缀 | `*-local.yaml` | `*-dev.yaml` | `*-full.yaml` |
| 数据库 | SQLite | TEST Nacos 管理 | 本地 Nacos 管理 |
| 缓存 | 无 | TEST Redis | 本地 Docker Redis |
| 服务发现 | 无 | TEST Nacos | 本地 Docker Nacos |
| 认证 | 测试 Token (`AUTH_MODE=dev`) | Redis 会话上下文链路；本地脚本启动兼容 Go Auth，生产以 Java Auth 为准 | 本地 Redis 会话上下文链路 |
| 基础设施 | 无 | 不启动 Docker | `docker-compose.infra.yaml` |

---

## 2. Config File Naming Convention

```
etc/
├── netdisk-api-local.yaml    # Netdisk 轻量开发
├── netdisk-api-dev.yaml      # Netdisk TEST 联调
├── netdisk-api-full.yaml     # Netdisk 本地 Docker 全栈联调
├── netdisk-api.yaml          # Netdisk 生产（Nacos 或运维注入）
├── gateway-local.yaml        # Gateway 轻量开发
├── gateway-dev.yaml          # Gateway TEST 联调
├── gateway-full.yaml         # Gateway 本地 Docker 全栈联调
├── gateway.yaml              # Gateway 生产
├── auth-api-dev.yaml         # Auth TEST 联调
├── auth-api-full.yaml        # Auth 本地 Docker 全栈联调
└── auth-api.yaml             # Auth 生产
```

| 后缀 | 用途 | 外部依赖 | 敏感信息 |
|------|------|---------|---------|
| `*-local.yaml` | 轻量开发 | 无 | 无 |
| `*-dev.yaml` | TEST 联调 | TEST Nacos/Redis/Auth | 不写真实密码，敏感配置从 Nacos/环境注入 |
| `*-full.yaml` | 本地全栈联调 | Docker Nacos/Redis/Auth (localhost) | 仅 localhost 默认密码 |
| `*-api.yaml` / `*.yaml` | 生产 | 生产基础设施 | 由环境变量/Secret 注入 |

---

## 3. Isolation Requirements

Each environment must isolate:

| Resource | Isolation rule |
| --- | --- |
| Nacos namespace | Separate namespace per environment |
| Nacos group | Separate group per environment |
| Database | Separate database or cluster per environment |
| Redis | Separate instance, logical DB, or key prefix per environment |
| OSS/resource bucket | Separate bucket/container per environment |
| CDN/domain | Separate domain per environment |
| Third-party provider accounts | Separate OAuth/app credentials per environment |
| Secrets | Stored in Nacos/env/secret system, not in Git |
| Frontend build variables | Separate `.env.*` file per build target |

Production and SG production must not share mutable data stores with test environments.

Version is not an environment dimension. Product version is managed by root `VERSION` and `release/version.json`; environment names only describe where that version is deployed. See [VERSIONING.md](VERSIONING.md).

---

## 4. Nacos Naming

当前仓库脚本和 `nacos-config/{env}` 模板使用以下命名（dev/full/test/prod/sg-* 使用 Nacos）:

| Item | Pattern | Example |
| --- | --- | --- |
| Namespace | `TEST` / `PROD` / `SG_TEST` / `SG_PROD` | `TEST` |
| Group | `TEST_GROUP` / `PROD_GROUP` / `SG_TEST_GROUP` / `SG_PROD_GROUP` | `TEST_GROUP` |
| Netdisk DataId | `amdox-go-netdisk.yml` | `amdox-go-netdisk.yml` |
| Java Auth DataId | Java 平台 Auth 配置 | 由 `campusmgmt-auth` 所属 Nacos 配置确定 |
| Java Gateway DataId | Java 平台 Gateway 配置 | 由 `campusmgmt-gateway` 所属 Nacos 配置确定 |
| Legacy Go Auth DataId | `amdox-go-auth.yml` | 仅迁移期兼容 |
| Legacy Go Gateway DataId | `amdox-go-gateway.yml` | 仅迁移期兼容 |

环境变量覆盖：

| 环境变量 | 说明 | 默认值 |
|----------|------|--------|
| `NACOS_NAMESPACE` | 命名空间 | `TEST` |
| `NACOS_GROUP` | 配置分组 | `TEST_GROUP` |
| `NACOS_HOST` | 服务地址 | `localhost` |
| `NACOS_PORT` | 服务端口 | `8848` |
| `AUTH_MODE` | 认证模式 | `dev` (本地) / `redis` (生产) |
| `GATEWAY_STATIC_TARGETS_FIRST` | Gateway 是否优先使用静态 Targets | `true` (本地脚本 dev/full) / unset (部署环境) |

---

## 5. Local YAML Boundary

Local `etc/*.yaml` files may contain:

- Service name, host, port.
- Nacos connection location for local/test development.
- Non-sensitive local defaults.
- Placeholder values that cannot connect to production.

Local `etc/*.yaml` files must not contain:

- Production usernames or passwords.
- Provider client secrets.
- Private keys.
- Production DB/Redis/OSS credentials.
- Real production tokens.

### 5.1 轻量开发配置 (`*-local.yaml`)

特点：零外部依赖，SQLite 数据库，无 Redis/Nacos。

```yaml
# etc/netdisk-api-local.yaml
Name: netdisk-api
Host: 0.0.0.0
Port: 9000
DB:
  DataSource: data/netdisk.db   # SQLite
# 无 Redis、无 Nacos、无 AuthCenter
```

```yaml
# etc/gateway-local.yaml
Name: gateway
Host: 0.0.0.0
Port: 9090
Upstreams:
  - Name: netdisk
    Targets: ["127.0.0.1:9000"]   # 静态地址，无 Nacos
# 无 Auth 节（跳过认证中间件）
```

### 5.2 TEST 联调配置 (`*-dev.yaml`)

特点：不启动本地 Docker，连接 TEST 环境 Nacos/Redis。

注意：`./netdisk.ps1 start dev` 是本仓库的 Go 兼容联调模式，依赖 TEST Nacos 中已发布的业务配置和 Redis 连接信息。LMS/生产链路仍必须使用 Java Auth + Java Gateway 写入 Redis `UserSessionContext`，Go Netdisk 只通过 `PlatformAuthAdapter` 读取。

本机启动的 Gateway 会设置 `GATEWAY_STATIC_TARGETS_FIRST=true`。因此即使 `gateway-dev.yaml` 或 TEST Nacos 配置了 `NacosServiceName`，本机浏览器和 LMS `/files` 流量仍优先进入当前工作区启动的 `localhost:9000` Netdisk，避免服务发现选中测试环境旧实例造成 `/api/v1/netdisk/file-spaces` 等新接口 404。

```yaml
# etc/netdisk-api-dev.yaml
Name: netdisk-api
Host: 0.0.0.0
Port: 9000
Mysql:
  DataSource: "root:root@tcp(localhost:3306)/netdisk"
Cache:
  - Host: localhost:6379
    Pass: "Amdox@rd_2024"
Nacos:
  IpAddr: campusmgmt-register
  Port: 8848
```

### 5.3 本地全栈配置 (`*-full.yaml`)

特点：启动本地 Docker 基础设施，适合没有 TEST 网络或需要离线验证时使用。

```powershell
./netdisk.ps1 start full
./netdisk.ps1 smoke full
```

---

## 6. Auth Mode

Netdisk 通过 `AUTH_MODE` 环境变量控制认证行为：

| AUTH_MODE | 行为 | 依赖 | 场景 |
|-----------|------|------|------|
| `dev` | 接受 `test-token-user-123`，无需 Redis/Auth | 无 | 本地开发 |
| `header` | 显式兼容模式，读取 `X-User-Id` 头 | Gateway | 仅迁移/调试 |
| `redis` | Java Auth 写 Redis `UserSessionContext`，Go `PlatformAuthAdapter` 读取 | Java Auth + Java Gateway + Redis | 生产环境 |

Gateway 认证：`*-local.yaml` 不配置 `Auth` 节时，认证中间件自动跳过。

---

## 7. Frontend Environment Variables

Frontend environment files:

```text
.env.development
.env.test
.env.production
.env.sg-test
.env.sg-prod
```

Required variables:

| Variable | Rule |
| --- | --- |
| `VITE_APP_STAGE` | One of the canonical environment names |
| `VITE_API_BASE_URL` | Gateway or same-origin API prefix only |
| `VITE_WS_BASE_URL` | Gateway or same-origin WebSocket prefix only |
| `VITE_OSS_PUBLIC_BASE_URL` | Public CDN/resource base URL for the environment |
| `VITE_USE_LOCAL_MOCK` | Boolean local/mock switch |
| `VITE_BUILD_VERSION` | Must come from root `VERSION` |
| `VITE_BUILD_COMMIT` | Short Git commit for deployment traceability |
| `VITE_BUILD_TIME` | Build timestamp in UTC |

Frontend must not contain backend service IPs, service ports, provider secrets, or internal Nacos addresses.

---

## 8. Secret Handling

Secrets belong in one of these stores:

1. Nacos secure configuration.
2. Environment variables injected by deployment.
3. Secret management system approved by the platform.

Rules:

- Production secret values are not documented in Git.
- Example values must be visibly fake.
- Logs must mask loaded secret values.
- Secret rotation must be handled as an operations task with rollback notes.
- If a committed secret is discovered, remove it from code and escalate to the owner for rotation assessment.

---

## 9. Environment Registry

Each environment should maintain a registry outside code for real values. The standard registry fields are:

| Field | Description |
| --- | --- |
| Environment | Canonical environment name |
| Gateway domain | Public API domain |
| WebSocket domain | Public WebSocket domain |
| Nacos namespace/group | Config and discovery isolation |
| DB identifier | Database instance or schema |
| Redis identifier | Redis instance/logical DB/key prefix |
| OSS bucket/container | Resource storage |
| CDN domain | Public resource domain |
| Provider account | Third-party account identifier |
| Owner | Responsible person/team |

Real production values are treated as environment assets and are not stored in this repository.

---

## 10. Review Checklist

- [ ] Does the change specify the target environment?
- [ ] Are production values excluded from Git?
- [ ] Does Nacos namespace/group follow the environment convention?
- [ ] Does frontend call the gateway only?
- [ ] Are DB, Redis, OSS, CDN, and provider accounts isolated?
- [ ] Does the rollback path avoid cross-environment data impact?
- [ ] `*-local.yaml` 是否零外部依赖？
- [ ] `*-dev.yaml` 是否仅使用 localhost 地址？
- [ ] `AUTH_MODE` 是否与目标环境匹配？
