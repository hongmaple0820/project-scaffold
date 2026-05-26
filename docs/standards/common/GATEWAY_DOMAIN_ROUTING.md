# Gateway, Domain, and Routing Standard

**Version**: v1.0  
**Date**: 2026-05-14  
**Scope**: Frontend access, gateway routes, service discovery, domain registry, header propagation  
**Platform source**: `F:/project/amdox/java/docs/standards/gateway-domain-routing.md`

---

## 1. Core Rule

Frontend traffic must enter backend services through Java `campusmgmt-gateway`. Frontend code must not call backend service IPs, ports, service discovery addresses, Nacos, DB, Redis, or third-party provider management endpoints directly.

Netdisk target gateway path:

```text
/api/**
```

The production netdisk entry is Java `campusmgmt-gateway`. If the platform later assigns `/netdisk/**` instead of `/api/**`, that change must be treated as an L-level API/gateway contract migration and recorded in the project standards.

## 2. Route Ownership

| Route area | Owner | Downstream |
| --- | --- | --- |
| `/health` | Java Gateway | Gateway health handler |
| `/metrics` | Java Gateway | Gateway metrics handler |
| `/api/v1/auth/**` | Java Auth / platform session | `campusmgmt-auth` |
| `/api/v1/host/session/**` | Java Auth / platform session | `campusmgmt-auth` or Go Auth compatibility service in local dev mode |
| `/api/v1/netdisk/**` | Netdisk service | `amdox-go-netdisk` |
| `/api/v1/file/**` | Netdisk service | `amdox-go-netdisk` |
| `/api/v1/upload/**` | Netdisk service | `amdox-go-netdisk` |
| `/api/v1/share/public/**` | Netdisk service | Public share contract, auth rules documented per endpoint |

New public routes require human confirmation when they expose unauthenticated access, change auth semantics, or change gateway-public routing.

## 3. Required Headers

Gateway CORS and downstream propagation must support:

| Header | Purpose |
| --- | --- |
| `Authorization` | Bearer token |
| `Content-Type` | Request body type |
| `Accept-Language` | i18n language |
| `X-Time-Zone` | Client timezone |
| `X-Campus-Id` | Campus context when available |
| `X-Client-Type` | Web, desktop, mobile, or integration client |
| `X-Trace-Id` | Request trace correlation |
| `X-Request-Id` | Request ID compatibility |

Production user context must follow [AUTH_CONTEXT.md](AUTH_CONTEXT.md): Java Gateway forwards `Authorization`; Java Auth/平台会话服务 stores/refreshed user session context in Redis; downstream Go services restore `UserSessionContext` through `PlatformAuthAdapter`. `X-User-*` identity headers are compatibility/debug-only and must not become the primary authentication contract.

## 4. Internal Service Calls

Internal service calls must use service discovery or approved internal client configuration.

Rules:

- Do not hardcode service IPs or ports in business logic.
- Propagate `Authorization`, trace, locale, timezone, tenant/campus context, and client type when applicable.
- Do not synthesize user identity in downstream headers when a Redis-backed session context exists.
- Apply timeout and retry rules from `REMOTE_CALLS.md`.
- Mask request and response logs for sensitive fields.

## 5. Domain Registry

Real domains are environment assets. Store them in environment configuration or registry, not directly in feature code.

Required registry fields:

| Field | Description |
| --- | --- |
| Environment | `dev`, `test`, `prod`, `sg-test`, or `sg-prod` |
| Frontend domain | User-facing app domain |
| API gateway domain | Frontend API base |
| WebSocket gateway domain | Frontend real-time base |
| OSS/CDN public domain | Resource display/download base |
| Owner | Responsible team |
| Change record | Date, reason, reviewer |

## 6. Gateway Configuration Rules

Java Gateway config must define:

- Upstream name.
- Prefix.
- Target service or service discovery name.
- Auth exclude paths.
- CORS origins, methods, and headers.
- Rate limit policy.
- Timeout policy.

Production gateway config must come from environment-specific config. Local defaults must not contain production secrets.

## 7. Review Checklist

- [ ] Does the frontend use only the gateway base URL?
- [ ] Is the route owner clear?
- [ ] Are public unauthenticated paths explicitly listed?
- [ ] Are `Accept-Language` and `X-Time-Zone` allowed and propagated?
- [ ] Are service IPs/ports absent from frontend code?
- [ ] Does the change avoid committing production domain secrets or credentials?
