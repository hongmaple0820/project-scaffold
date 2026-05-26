# 部署与环境配置规范

> **适用范围**: SyncNest Hub (netdisk-project) 全部产品服务
> **关联文档**: [CONFIG_ENVIRONMENTS.md](CONFIG_ENVIRONMENTS.md), [VERSIONING.md](VERSIONING.md), [GIT_STANDARDS.md](GIT_STANDARDS.md)

---

## 1. 服务清单

| 服务 | 目录 | 端口 | 说明 |
|------|------|------|------|
| Netdisk API | `amdox-go-netdisk` | 9000 | 网盘业务、驱动、文件、上传、分享、回收站 |
| Java Gateway | `F:\project\amdox\java\campusmgmt-gateway` | 9999/按环境 | 生产北向入口、路由和 token relay |
| Java Auth | `F:\project\amdox\java\campusmgmt-auth` | 按环境 | 平台身份源、token introspection、Redis `UserSessionContext` 写入 |
| Legacy Go Gateway | `amdox-go-gateway` | 9090 | 本地/迁移期兼容入口，透传 token 并按 sha256 Redis key 读取会话上下文，不作为生产主入口 |
| Legacy Go Auth API | `amdox-go-auth` | 9110 | 本地/迁移期兼容鉴权和 Host Session 服务，写入 Java 兼容 `UserSessionContext` |
| UI | `amdox-netdisk-ui` | 3000 | 前端 Vue 3 + Vite |

生产请求链路: `浏览器/LMS → Java Gateway → Java Auth/Redis UserSessionContext → Go Netdisk`
本地兼容链路: `浏览器 → UI (3000) → Go Gateway (9090) → Go Auth Host Session/Redis UserSessionContext → Netdisk (9000)`

---

## 2. 两套运行模式

| | 轻量开发 `local` | TEST 联调 `dev` | 本地全栈 `full` |
|---|---|---|---|
| 启动命令 | `./netdisk.ps1 start` 或 `./netdisk.ps1 start local` | `./netdisk.ps1 start dev` | `./netdisk.ps1 start full` |
| 配置文件 | `*-local.yaml` | `*-dev.yaml` | `*-full.yaml` |
| Docker/Nacos/Redis/Auth | 不需要 | 不启动 Docker，连接 TEST Nacos/Redis，启动兼容 Auth | 启动本地 Docker Nacos/Redis/Jaeger/Prometheus 和兼容 Auth |
| 数据库 | SQLite | TEST Nacos 配置中心管理 | 本地 Nacos 配置中心管理 |
| 认证 | 测试 Token `test-token-user-123` | Redis 会话上下文链路；本地脚本启动 Legacy Go Auth，生产以 Java Auth 为准 | 本地 Redis 会话上下文链路 |
| 适用场景 | 前端开发、功能调试 | Go 服务连接线上测试配置联调 | 离线/本机完整基础设施联调 |

### 2.1 轻量开发模式 (local)

零外部依赖，一条命令启动：

```powershell
./netdisk.ps1 start           # 启动全部服务（默认 local 模式）
./netdisk.ps1 start local     # 显式启动 local 模式
./netdisk.ps1 stop            # 停止全部服务
./netdisk.ps1 restart         # 重启全部服务
./netdisk.ps1 status          # 查看全部服务状态
```

技术要点：
- Netdisk 使用 `etc/netdisk-api-local.yaml`（SQLite）+ `AUTH_MODE=dev`（DevAuthMiddleware 接受测试 Token）
- Gateway 使用 `etc/gateway-local.yaml`（静态 Targets，无 Nacos，无 Auth 中间件）
- Auth 服务不启动
- UI 直接 `npm run dev`

### 2.2 TEST 联调模式 (dev)

不启动 Docker，连接 TEST Nacos/Redis + 启动全部本地服务：

```powershell
./netdisk.ps1 start dev       # 连接 TEST Nacos/Redis + 启动全部服务
./netdisk.ps1 stop dev        # 停止全部服务，不停止 Docker
./netdisk.ps1 smoke dev       # 验证 Gateway -> Auth Host Session -> Netdisk 真实链路
```

技术要点：
- 不启动本地 Docker，不依赖本地 Jaeger/Prometheus。
- Nacos 使用 TEST 环境，默认 `campusmgmt-register:8848`、`Namespace=TEST`、`Group=TEST_GROUP`。
- Redis 连接信息必须来自 TEST Nacos 业务配置或运行环境，不能依赖 localhost fallback。
- Netdisk 使用 `etc/netdisk-api-dev.yaml`（TEST Nacos + Redis 会话上下文）
- Gateway 使用 `etc/gateway-dev.yaml`（TEST Nacos 服务发现 + Auth 中间件）
- Auth 使用 `etc/auth-api-dev.yaml`（TEST Redis + Nacos，迁移期兼容）
- 根脚本会给 Gateway 设置 `GATEWAY_STATIC_TARGETS_FIRST=true`，本机联调优先走静态 `localhost:9000/9110`，避免 TEST Nacos 中旧实例或他人实例影响本地 LMS -> Gateway -> Netdisk 链路。
- Go Gateway 必须先将 `/api/v1/host/session/**` 路由到 Go Auth，再将 `/api/v1/**` 路由到 Go Netdisk，避免命中 Netdisk 旧 HostSession 实现。
- Go Auth 新写 Redis key 必须是 `amdox:auth:user:token:{sha256(token)}`，value 为 Java 兼容 `UserSessionContext` JSON；历史 raw token key 只允许读取兼容。
- 根脚本必须给 Netdisk 设置 `AUTH_MODE=redis`

### 2.3 本地全栈模式 (full)

启动 Docker 基础设施 + 全部服务：

```powershell
./netdisk.ps1 start full      # 启动本地 Nacos/Redis/Jaeger/Prometheus + 全部服务
./netdisk.ps1 stop full       # 停止全部服务 + 本地 Docker 基础设施
./netdisk.ps1 smoke full      # 验证 Gateway -> Auth Host Session -> Netdisk 真实链路
```

`full` 模式才启动 `docker-compose.infra.yaml`：

- Nacos：配置中心、服务发现，端口 `8848`
- Redis：用户会话上下文 `UserSessionContext`，端口 `6379`
- Jaeger：链路追踪，端口 `16686`
- Prometheus：指标监控，端口 `9091`

### 2.4 Java 平台联调模式

生产和 LMS 嵌入验证必须以 Java 平台链路为准：

```text
LMS / Browser
  -> Java campusmgmt-gateway
  -> Java campusmgmt-auth 写入 Redis UserSessionContext
  -> Go amdox-go-netdisk PlatformAuthAdapter 读取 Redis
```

本仓库 `./netdisk.ps1 start dev/full` 只负责本地 Go 兼容链路，不会自动启动 `F:\project\amdox\java\campusmgmt-gateway` 或 `F:\project\amdox\java\campusmgmt-auth`。Java 链路部署测试时，需要在 Java 仓库按平台规范启动/发布 Java Gateway/Auth，并确认：

- Java Gateway 将 `/api/v1/host/session/**` 路由到 Java Auth。
- Java Gateway 将 `/api/v1/*` 文件业务路由到 Go Netdisk。
- Java Auth 与 Go Netdisk 使用同一个 Redis、同一个 token hash key prefix。
- 浏览器、LMS、Java Gateway、Go Netdisk 之间透传 `Authorization: Bearer <token>`。

---

## 3. 配置文件分层

### 3.1 文件命名约定

| 后缀 | 用途 | 示例 |
|------|------|------|
| `*-local.yaml` | 轻量开发，零外部依赖 | `netdisk-api-local.yaml`, `gateway-local.yaml` |
| `*-dev.yaml` | TEST 联调，不启动 Docker | `netdisk-api-dev.yaml`, `gateway-dev.yaml`, `auth-api-dev.yaml` |
| `*-full.yaml` | 本地 Docker 全栈联调 | `netdisk-api-full.yaml`, `gateway-full.yaml`, `auth-api-full.yaml` |
| `*-api.yaml` | 生产部署，由 Nacos 或运维注入 | `netdisk-api.yaml` |

### 3.2 配置分层架构

```
Layer 1: 代码默认值 (config.go)
  └── 本地开发兜底，不含敏感信息

Layer 2: 本地配置文件 (etc/*-local.yaml、etc/*-dev.yaml 或 etc/*-full.yaml)
  └── 仅连接信息和非敏感默认值

Layer 3: Nacos 配置中心（dev/full/test/prod/sg-* 模式）
  └── 完整业务配置，按命名空间隔离环境

Layer 4: 环境变量 / Docker Secret / K8s Secret
  └── 覆盖连接信息、敏感配置
```

### 3.3 敏感信息处理

| 信息类型 | 存储方式 | 禁止事项 |
|----------|----------|----------|
| ClientID/ClientSecret | 环境变量 / Docker Secret | ❌ 禁止写入代码仓库 |
| 数据库密码 | 环境变量 / Docker Secret | ❌ 禁止写入配置文件 |
| JWT 密钥 | 环境变量 | ❌ 禁止硬编码 |
| 用户 AccessToken | 数据库 (加密存储) | ❌ 禁止明文存储 |

---

## 4. 统一运维脚本

### 4.1 根目录脚本 `netdisk.ps1`

管理全部服务的统一入口：

```powershell
./netdisk.ps1 start              # 启动（默认 local 模式）
./netdisk.ps1 start local        # 本地轻量模式启动
./netdisk.ps1 start dev          # TEST Nacos/Redis 联调，不启动 Docker
./netdisk.ps1 start full         # 本地 Docker 全栈模式启动
./netdisk.ps1 stop               # 停止
./netdisk.ps1 restart            # 重启
./netdisk.ps1 status             # 查看状态
./netdisk.ps1 build              # 构建
./netdisk.ps1 test               # 测试
./netdisk.ps1 smoke local        # 本地轻量链路冒烟
./netdisk.ps1 smoke dev          # TEST 链路冒烟
./netdisk.ps1 smoke full         # 本地 Docker 全栈链路冒烟
./netdisk.ps1 logs               # 查看日志
```

支持指定目标服务：

```powershell
./netdisk.ps1 start netdisk      # 仅启动 Netdisk
./netdisk.ps1 start gateway      # 仅启动 Gateway
./netdisk.ps1 start ui           # 仅启动 UI
./netdisk.ps1 build netdisk      # 仅构建 Netdisk
```

### 4.2 子模块脚本

每个子模块有独立运维脚本：

```powershell
cd amdox-go-netdisk && ./netdisk.ps1 start|stop|restart|status|build|test
cd amdox-go-gateway  && ./gateway.ps1 start|stop|restart|status|build|test
cd amdox-go-auth     && ./auth.ps1 start|stop|restart|status|build|test
cd amdox-netdisk-ui  && ./ui.ps1 start|stop|restart|status|build|lint
```

---

## 5. Docker 基础设施

### 5.1 基础设施服务 (docker-compose.infra.yaml)

仅 `full` 模式需要：

| 服务 | 用途 | 端口 | UI |
|------|------|------|-----|
| **Nacos** | 配置中心 + 服务发现 | 8848(HTTP), 9848(gRPC) | `http://localhost:8848/nacos` |
| **Redis** | Token 缓存 | 6379 | -- |
| **Jaeger** | 链路追踪 | 4317(gRPC), 16686(UI) | `http://localhost:16686` |
| **Prometheus** | 指标监控 | 9091 | `http://localhost:9091` |

```powershell
# 由 netdisk.ps1 start full 自动启动，也可手动管理
docker compose -f docker-compose.infra.yaml up -d
docker compose -f docker-compose.infra.yaml down
```

### 5.2 Dockerfile 规范

```dockerfile
# 多阶段构建
FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o service .

FROM alpine:3.19
RUN apk --no-cache add ca-certificates tzdata
WORKDIR /app
COPY --from=builder /app/service .
COPY --from=builder /app/etc ./etc

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:9000/health || exit 1

EXPOSE 9000
ENTRYPOINT ["./service", "-f", "etc/service-api.yaml"]
```

---

## 6. 认证模式

Netdisk 支持三种认证模式，通过 `AUTH_MODE` 环境变量控制：

| AUTH_MODE | 说明 | 依赖 | 使用场景 |
|-----------|------|------|---------|
| `dev` | DevAuthMiddleware，接受测试 Token | 无 | 本地开发 |
| `header` | 显式兼容模式，读取 `X-User-Id` 头 | Gateway | 仅迁移/调试 |
| `redis` | Java Auth 写 Redis `UserSessionContext`，Go `PlatformAuthAdapter` 读取 | Java Auth + Java Gateway + Redis | 生产环境 |

Gateway 本地联调变量：

| 环境变量 | 说明 | 使用场景 |
| --- | --- | --- |
| `GATEWAY_STATIC_TARGETS_FIRST=true` | Gateway upstream 同时配置 Nacos 和静态 Targets 时，优先使用静态 Targets，Nacos 仅作为 fallback | `./netdisk.ps1 start dev/full` 本机链路，避免服务发现命中旧实例 |

```powershell
# 本地开发（默认）
AUTH_MODE=dev ./bin/netdisk -f etc/netdisk-api-local.yaml

# 生产部署
./bin/netdisk -f etc/netdisk-api.yaml  # AUTH_MODE 默认为 redis
```

Gateway 认证：当 `gateway-local.yaml` 中不配置 `Auth` 节时，认证中间件自动跳过。

---

## 7. Nacos 配置中心（dev/full/test/prod/sg-*）

与 Java 端共用同一 Nacos Server。

| 服务 | Namespace | Group | DataId |
|------|-----------|-------|--------|
| Netdisk | `TEST` / `PROD` / `SG_TEST` / `SG_PROD` | `TEST_GROUP` / `PROD_GROUP` / `SG_TEST_GROUP` / `SG_PROD_GROUP` | `amdox-go-netdisk.yml` |
| Legacy Go Auth | 同上 | 同上 | `amdox-go-auth.yml` |
| Legacy Go Gateway | 同上 | 同上 | `amdox-go-gateway.yml` |
| Java Auth/Gateway | 以 Java 平台 Nacos 命名为准 | 以 Java 平台 Nacos 分组为准 | 以 Java 平台服务配置为准 |

环境变量覆盖：

| 环境变量 | 说明 | 默认值 |
|----------|------|--------|
| `NACOS_NAMESPACE` | 命名空间 | `TEST` |
| `NACOS_GROUP` | 配置分组 | `TEST_GROUP` |
| `NACOS_HOST` | 服务地址 | `localhost` |
| `NACOS_PORT` | 服务端口 | `8848` |

---

## 8. 微服务功能配置

| 功能 | 配置字段 | 默认值 | 说明 |
|------|----------|--------|------|
| 链路追踪 | `Telemetry` | 关闭 | 配置 Endpoint 后自动启用 |
| 熔断器 | `Middlewares.Breaker` | 开启 | go-zero 内置 |
| 降载 | `CpuThreshold` | 900 (90%) | go-zero 内置 |
| 超时控制 | `Timeout` | 3000ms | go-zero 内置 |
| Prometheus | `Prometheus` | 关闭 | 配置 Port 后自动启用 |
| 服务发现 | `NacosNaming` | 关闭 | IpAddr+ServiceName 配置后自动注册 Nacos |

---

## 9. CI/CD 集成

发布流水线必须先执行统一版本校验：

```powershell
make version-check
```

镜像 tag 必须使用 `VERSION` 和短 commit 组合，例如 `syncnest-netdisk-api:0.1.0-abc1234`；Git tag 使用 `vX.Y.Z`。环境名 `test`、`prod`、`sg-test`、`sg-prod` 只能作为部署目标或发布记录字段，不能替代产品版本。

### 9.1 GitHub Actions 示例

```yaml
name: Deploy
on:
  push:
    tags: ['v*']

jobs:
  deploy-prod:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build and Push
        run: |
          docker build -t $REGISTRY/netdisk-api:${GITHUB_REF#refs/tags/} ./amdox-go-netdisk
          docker push $REGISTRY/netdisk-api:${GITHUB_REF#refs/tags/}
        env:
          REGISTRY: ${{ secrets.REGISTRY }}
```

---

## 10. 检查清单

### 10.1 提交前检查

- [ ] 没有提交任何 `.env*` 文件（除模板外）
- [ ] 配置文件中使用 `${ENV_VAR}` 占位符
- [ ] `*-local.yaml` 和 `*-dev.yaml` 不含生产凭据
- [ ] Dockerfile 使用多阶段构建

### 10.2 部署前检查

- [ ] 环境变量已正确设置
- [ ] 敏感信息已使用 Docker Secret 或环境变量注入
- [ ] 健康检查端点可用
- [ ] 日志目录已挂载到宿主机

### 10.3 运行时检查

- [ ] 容器能正确读取环境变量
- [ ] 日志正常输出
- [ ] 健康检查通过
- [ ] `/api/v1/*` 真实路径冒烟通过（不能只看 `/health`）

### 10.4 本地部署测试命令

轻量开发链路：

```powershell
./netdisk.ps1 start
./netdisk.ps1 status
curl.exe -H "Authorization: Bearer test-token-user-123" http://localhost:9090/api/v1/netdisk/file-spaces
./netdisk.ps1 logs
```

TEST 兼容链路：

```powershell
./netdisk.ps1 start dev
./netdisk.ps1 status
./netdisk.ps1 smoke dev
powershell -NoProfile -ExecutionPolicy Bypass -File nacos-config\compare-with-nacos.ps1 -Environment test
```

本地 Docker 全栈链路：

```powershell
./netdisk.ps1 start full
./netdisk.ps1 status
./netdisk.ps1 smoke full
```

Nacos 发布前先做 dry run：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File nacos-config\import-to-nacos.ps1 -Environment test -DryRun
```

Java 平台链路验收必须额外验证：

- `POST /api/v1/host/session` 返回受限会话信息。
- Redis 存在 `amdox:auth:user:token:{sha256(token)}` 对应的 `UserSessionContext`。
- 通过 Java Gateway 调用 `/api/v1/netdisk/file-spaces`、`/api/v1/file/list`、`/api/v1/task/list` 返回业务结果。
- 过期或撤销 token 能触发 401，并由前端/LMS 进入刷新流程。
