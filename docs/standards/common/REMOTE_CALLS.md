# Remote Call Standard

**Version**: v1.0  
**Date**: 2026-05-14  
**Scope**: Internal service calls, external provider calls, provider SDK wrappers

---

## 1. Call Types

| Type | Examples | Required boundary |
| --- | --- | --- |
| Internal service call | Java Auth introspection fallback, user profile, Java platform service calls, Go Netdisk internal calls | `pkg/remotecall/internal` or service-specific client wrapper |
| External provider call | Baidu, Google Drive, OneDrive, S3, WebDAV, SMB, SFTP | Driver/provider client wrapper |
| Resource call | OSS/CDN signed URL, upload/download proxy | `pkg/storage` or driver abstraction |

Business handlers must not call third-party SDKs or internal services directly.

## 2. Internal Call Rules

Internal calls must:

- Use service discovery or environment-specific client config.
- Carry `Authorization: Bearer <token>` whenever the call is user-scoped; the Go callee restores `UserSessionContext` from Redis through `PlatformAuthAdapter` according to [AUTH_CONTEXT.md](AUTH_CONTEXT.md).
- Use approved service credentials only for non-user-scoped system jobs, and record the caller service, scope, and reason.
- Propagate `X-Trace-Id`, `Accept-Language`, `X-Time-Zone`, `X-Campus-Id`, and `X-Client-Type` when applicable.
- Set timeout explicitly.
- Return stable business errors instead of raw network errors.
- Log failures with masked headers and payload summaries.
- Do not propagate `X-User-*` as the source of truth for user identity.

## 3. External Call Rules

Every external provider client must document:

| Field | Required content |
| --- | --- |
| Provider | Baidu, Google, OneDrive, S3, WebDAV, SMB, SFTP |
| Purpose | Why the provider is called |
| Owner | Responsible module/team |
| Config source | Nacos/env/secret system |
| Timeout | Connect and request timeout |
| Retry | Retry count and retryable status/errors |
| Circuit breaker | Breaker or degradation behavior |
| Rate limit | Provider and local limits |
| Masking | Sensitive request/response fields |
| Timezone behavior | Provider time parsing and conversion |

## 4. Timeout, Retry, and Degradation

Default target policy:

| Concern | Rule |
| --- | --- |
| Timeout | Set per call type; no infinite waits |
| Retry | Retry only idempotent operations or provider-documented safe cases |
| Backoff | Use bounded backoff for transient provider errors |
| Circuit breaker | Use go-zero breaker or wrapper when provider instability can affect users |
| Degradation | Return stable error code and localized message |

Upload, delete, move, copy, and OAuth token operations require explicit idempotency analysis before retry.

## 5. Logging and Masking

Remote call logs must include:

- Provider or service name.
- Operation name.
- Trace ID.
- Duration.
- Status or stable error code.

Remote call logs must not include:

- Access tokens.
- Refresh tokens.
- Client secrets.
- Passwords.
- Private keys.
- Full signed URLs when credentials are embedded.
- Raw third-party sensitive responses.

## 6. Review Checklist

- [ ] Is the call behind an internal or provider client wrapper?
- [ ] Is timeout configured?
- [ ] Is retry safe and bounded?
- [ ] Are propagated headers preserved?
- [ ] Are secrets and tokens masked?
- [ ] Is provider time converted according to `I18N_TIMEZONE.md`?
- [ ] Is failure converted to a stable error code?
