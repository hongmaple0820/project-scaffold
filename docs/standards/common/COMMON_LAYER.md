# Common Layer Standard

**Version**: v1.0  
**Date**: 2026-05-14  
**Scope**: Shared Go/go-zero backend capabilities for netdisk services  
**Platform source**: `F:/project/amdox/java/docs/standards/backend-architecture.md`

---

## 1. Purpose

Netdisk must not duplicate cross-cutting logic inside handlers or business logic. Shared behavior must enter a common layer first, then be consumed by services.

The Go common layer adapts Java `campusmgmt-common-*` and `campusmgmt-service-common` responsibilities to Go/go-zero conventions.

## 2. Target Package Map

| Target package | Responsibility |
| --- | --- |
| `pkg/response` | Unified `{code,msg,data}` response, pagination envelope, HTTP error conversion |
| `pkg/errors` | Stable error codes, business errors, wrapping, i18n key mapping |
| `pkg/i18n` | Language resolution, message catalog, interpolation |
| `pkg/timezone` | `X-Time-Zone` parsing, IANA validation, normalization |
| `pkg/biztime` | `Asia/Shanghai` business time helpers |
| `pkg/userctx` | User, tenant, campus, roles, permissions, locale, timezone, trace context |
| `pkg/authz` | Permission and role checks |
| `pkg/masking` | Phone, email, token, credential, provider response masking |
| `pkg/crypto` | Encryption/decryption helpers and key loading boundary |
| `pkg/redisx` | Redis client access, key naming, TTL conventions |
| `pkg/remotecall` | Internal/external call wrappers, timeout/retry/header propagation |
| `pkg/storage` | OSS/resource access contracts and signed URL behavior |
| `pkg/configx` | Environment-aware config helpers and secret boundary checks |
| `pkg/ratelimit` | Rate-limit configuration and unified error behavior |
| `pkg/tracex` | Trace ID extraction and propagation helpers |

Existing service-local packages can remain during migration, but new shared behavior should target these package boundaries.

## 3. Layering Rules

```text
handler
  -> logic/application
    -> domain/service
      -> model/repository
        -> database/cache/driver/remote
```

Rules:

- Handler parses protocol, validates input, invokes logic, and writes unified response.
- Logic orchestrates business behavior and returns domain results or errors.
- Logic must not return HTTP response envelopes.
- Model/repository performs persistence only.
- Driver/provider clients hide third-party API differences.
- Cross-cutting behavior belongs in `pkg/*`, middleware, or gateway layer.

## 4. Required Shared Capabilities

| Capability | Must be centralized because |
| --- | --- |
| Unified response | Prevents mixed response shapes |
| Error code and i18n | Prevents raw internal errors and untranslatable messages |
| User context | Prevents inconsistent auth, tenant, campus, and role semantics |
| Permission checks | Frontend permission is UX only; backend must enforce |
| Timezone | Prevents mixed UTC/local/Beijing assumptions |
| Redis | Prevents key collisions and inconsistent TTL |
| Remote calls | Prevents missing auth, locale, timezone, trace, timeout, retry |
| Masking | Prevents credential and PII leakage |
| Encryption | Prevents ad hoc key handling |
| Storage/OSS | Prevents direct provider SDK usage from business handlers |

## 5. Public Layer Rules

- A package in `pkg/*` must document its contract before wide use.
- Public helpers must accept `context.Context` when they need user, trace, locale, timezone, timeout, or cancellation.
- Public helpers must return errors with stable codes when failures are user-facing.
- No common package may depend on a concrete business handler.
- No common package may log unmasked secrets or tokens.
- Common packages must be small enough to test independently.

## 6. Migration Priority

| Priority | Package | Reason |
| --- | --- | --- |
| P0 | `pkg/response`, `pkg/errors` | Every API depends on consistent output |
| P0 | `pkg/i18n`, `pkg/timezone`, `pkg/biztime` | Required before new API contracts |
| P0 | `pkg/userctx`, `pkg/authz` | Required for auth and permission consistency |
| P1 | `pkg/masking`, `pkg/crypto` | Required for sensitive data control |
| P1 | `pkg/remotecall`, `pkg/redisx` | Required for integration safety |
| P2 | `pkg/storage`, `pkg/configx`, `pkg/ratelimit`, `pkg/tracex` | Required for maintainability and observability |

## 7. Review Checklist

- [ ] Is cross-cutting logic implemented once in a common package or middleware?
- [ ] Does the handler avoid business decisions?
- [ ] Does the logic avoid HTTP response envelopes?
- [ ] Does the code use `context.Context` for propagated request data?
- [ ] Does user-facing failure use a stable code and localized message key?
- [ ] Does the implementation avoid logging secrets or tokens?
- [ ] Does the new helper have a clear package owner and tests when implemented?
