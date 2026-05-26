# 统一版本管理规范

> 适用范围：SyncNest 网盘产品版本、服务镜像、前端构建、Nacos 发布和部署验证。

## 1. 版本源

`VERSION` 是产品版本的唯一人工维护源，必须使用 SemVer：

```text
MAJOR.MINOR.PATCH[-PRERELEASE][+BUILD]
```

`release/version.json` 是机器可读发布清单，必须与 `VERSION` 保持一致，并声明各服务版本：

```json
{
  "schemaVersion": 1,
  "product": "SyncNest 网盘",
  "version": "0.1.0",
  "channel": "dev",
  "services": {
    "netdisk": "0.1.0",
    "gateway": "0.1.0",
    "auth": "0.1.0",
    "ui": "0.1.0"
  }
}
```

当前阶段采用产品统一版本：`netdisk`、`gateway`、`auth`、`ui` 必须等于根 `VERSION`。后续如果服务需要独立版本，必须先更新本规范和发布清单 schema。

## 2. 环境与版本边界

`local`、`dev`、`test`、`prod`、`sg-test`、`sg-prod` 是部署或运行环境，不是产品版本。

同一个 `VERSION` 可以部署到不同环境，但发布记录必须同时记录：

- 产品版本：例如 `0.1.0`
- Git commit：例如 `abc1234`
- 环境：例如 `test`、`prod`、`sg-prod`
- 镜像或前端构建产物：例如 `syncnest-netdisk-api:0.1.0-abc1234`

## 3. 校验入口

本仓库提供统一校验命令：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/version.ps1 show
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/version.ps1 check
make version
make version-check
```

`version-check` 至少校验：

- `VERSION` 是合法 SemVer。
- `release/version.json.version` 等于 `VERSION`。
- `release/version.json.services.*` 等于 `VERSION`。
- `amdox-netdisk-ui/package.json` 等于 `VERSION`。
- `amdox-netdisk-ui/package-lock.json` 等于 `VERSION`。
- `amdox-netdisk-ui/src-tauri/tauri.conf.json` 等于 `VERSION`。
- `amdox-go-netdisk/package.json` 和 `package-lock.json` 中的 E2E 测试包版本等于 `VERSION`。

工作流门禁 `scripts/gates/all.sh --workflow` 和 `scripts/gates/all.ps1 -Mode workflow` 必须先执行 `G0` 版本校验，再执行其他治理检查。

## 4. 发布命名

Git tag 使用 `vX.Y.Z`：

```bash
git tag -a v0.1.0 -m "release v0.1.0"
```

镜像 tag 使用 `<version>-<short-commit>`：

```text
syncnest-netdisk-api:0.1.0-abc1234
syncnest-gateway:0.1.0-abc1234
syncnest-auth:0.1.0-abc1234
syncnest-web:0.1.0-abc1234
```

前端远程资源建议包含版本目录：

```text
/netdisk/remote/v0.1.0/
```

## 5. 构建注入

构建系统应将版本、commit、构建时间注入服务和前端：

| 目标 | 推荐字段 |
| --- | --- |
| Go 服务 | `Build.Version`, `Build.Commit`, `Build.Time` |
| UI | `VITE_BUILD_VERSION`, `VITE_BUILD_COMMIT`, `VITE_BUILD_TIME` |
| Nacos | `Build.Version`, `Build.Commit`, `Build.Environment` |
| 健康/版本接口 | `/version` 或 `/health` 的 build 区块 |

任何服务日志、错误响应和监控标签只能输出版本、commit、环境，不得输出 token、cookie、secret 或内部鉴权头。

## 6. 发布门禁

发布到 `test`、`prod`、`sg-test`、`sg-prod` 前必须完成：

- `make version-check`
- `git diff --check`
- 影响服务的 build/test/lint
- 真实 `/api/v1/*` 冒烟，不能只看 `/health`
- Nacos dry-run 和生产发布人工确认

版本不一致时禁止发布。
