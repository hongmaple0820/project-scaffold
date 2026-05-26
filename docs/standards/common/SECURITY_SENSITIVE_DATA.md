# Security and Sensitive Data Standard

**Version**: v1.0  
**Date**: 2026-05-14  
**Scope**: Authentication, authorization, secrets, encryption, masking, rate limiting, logs
**Platform source**: `F:/project/amdox/java/docs/standards/security-sensitive-data.md`

---

## 1. Core Rules

- Backend enforces authentication and authorization. Frontend permissions are UX only.
- Production secrets must not enter Git.
- Passwords, tokens, client secrets, private keys, provider credentials, signed URLs, and PII must be masked in logs and responses.
- Auth, permission, production config, secret, and encryption changes are CRITICAL.
- Security-sensitive behavior must be centralized in common layer packages or gateway middleware.

## 2. User Context

The standard user context fields are:

| Field | Meaning |
| --- | --- |
| `userId` | Platform user ID |
| `username` | Login or account name |
| `tenantId` | Tenant or organization ID |
| `campusId` | Campus context |
| `roles` | Role identifiers |
| `permissions` | Permission identifiers |
| `locale` | User language preference |
| `timeZone` | User or request timezone |
| `traceId` | Request trace |
| `clientType` | Web, desktop, mobile, integration |

Services must read user context from the unified context path, not from ad hoc header parsing in business logic.

## 3. Authorization

Rules:

- Gateway authentication does not replace backend authorization.
- Sensitive operations require backend permission checks.
- Public endpoints must be explicitly listed and reviewed.
- Role checks and permission checks must use a common helper.
- Permission failures return stable codes and localized messages.

Sensitive netdisk operations include:

- Bind or unbind provider account.
- Refresh provider token.
- Create, delete, move, copy, rename files.
- Create public share.
- Download protected resources.
- Manage storage drivers or mount points.
- View administrative metrics.

## 4. Secret Handling

Secrets include:

- DB passwords.
- Redis passwords.
- Nacos passwords.
- Provider client secrets.
- OAuth tokens and refresh tokens.
- Private keys.
- Encryption keys.
- Signed URL credentials.

Rules:

- Production secrets must live in Nacos/env/secret management.
- Local examples must use fake values.
- Secret values must not be committed in docs, code, tests, or screenshots.
- If a secret is discovered in Git, remove it from active files and escalate for rotation assessment.

## 5. Masking Rules

| Data | Masking rule | Example |
| --- | --- | --- |
| Token/access token | Keep first 6 and last 4 when needed | `abcdef******1234` |
| Refresh token | Fully mask | `******` |
| Password | Fully mask | `******` |
| Client secret | Fully mask | `******` |
| Phone | Keep first 3 and last 4 | `138****1234` |
| Email | Keep first 3 and domain | `tes***@example.com` |
| Signed URL | Remove signature/query credential fields | `https://host/path?signature=******` |
| Provider raw response | Log summarized status only | `provider=baidu status=401` |

## 6. Encryption and Passwords

- User passwords must use strong one-way hashing. Plaintext, reversible encryption, and single MD5 are forbidden.
- API encryption/decryption must be implemented through a common boundary.
- Encryption keys are loaded from Nacos/env/secret management.
- Key rotation must include compatibility and rollback notes.

## 7. Rate Limiting and Abuse Control

Rate-limit assessment is required for:

- Login.
- Token refresh.
- Captcha or verification code.
- Upload and download.
- Search.
- Share public access.
- Provider OAuth callback.
- Export or bulk operations.

Rate-limit responses must use stable error codes and localized messages.

## 8. Review Checklist

- [ ] Does backend enforce authorization?
- [ ] Is the endpoint public only when explicitly reviewed?
- [ ] Are secrets absent from code and docs?
- [ ] Are logs masked?
- [ ] Are tokens and provider credentials hidden from API responses?
- [ ] Does the change require CRITICAL confirmation?
- [ ] Is rate limiting considered for abuse-prone operations?
