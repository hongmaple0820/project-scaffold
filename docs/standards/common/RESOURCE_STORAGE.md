# Resource and OSS Operation Standard

**Version**: v1.0  
**Date**: 2026-05-14  
**Scope**: Local storage, third-party cloud drives, object storage, signed URLs, upload/download resources

---

## 1. Purpose

Netdisk integrates local files, cloud drives, protocol storage, and future OSS/CDN resources. Resource operations must use a shared abstraction instead of provider-specific logic leaking into handlers.

## 2. Resource Operation Boundary

Allowed resource boundaries:

| Boundary | Responsibility |
| --- | --- |
| Driver interface | Provider-specific list/get/link/write behavior |
| `pkg/storage` target | Shared OSS/object storage helpers |
| Provider client wrapper | OAuth, token refresh, provider API calls |
| Task runner | Long-running upload/download/copy/move behavior |

Handlers and frontend code must not directly call provider SDKs, object storage SDKs, or filesystem operations for business resources.

## 3. Standard Operations

| Operation | Rule |
| --- | --- |
| List | Enforce permission and path boundary |
| Get metadata | Mask provider-sensitive metadata |
| Link/download URL | Use signed or proxied access when required |
| Upload | Validate size, type, user quota, idempotency, and target path |
| Move/copy | Validate source and target ownership |
| Delete | Support recycle/restore semantics when business requires |
| Share | Apply expiration, password, permission, and rate-limit checks |
| Preview | Avoid exposing raw provider credentials |

## 4. Signed URL Rules

Signed URLs:

- Must have expiration.
- Must not be logged in full.
- Must not be stored as permanent business data unless explicitly required.
- Must be scoped to a user/resource/action where provider supports it.
- Must use environment-specific domain/CDN configuration.

## 5. Provider Metadata Rules

Provider metadata may contain sensitive values. Store only fields required for product behavior.

If raw provider metadata is stored for troubleshooting or sync correctness:

- Store it in a provider metadata table or structured JSON field with access control.
- Mask it in logs and API responses.
- Record provider time handling according to `I18N_TIMEZONE.md`.
- Do not expose provider tokens or internal IDs unless the API contract requires it.

## 6. Resource Naming and Path Rules

- User-supplied paths must be normalized.
- Path traversal is forbidden.
- Windows and Unix path differences must be handled at the boundary.
- Provider virtual paths must not be trusted as local filesystem paths.
- File names returned to users must preserve display intent but must be escaped by the frontend.

## 7. Review Checklist

- [ ] Is the operation behind a driver, provider client, task runner, or `pkg/storage` boundary?
- [ ] Are permissions checked before resource access?
- [ ] Are signed URLs masked and expiring?
- [ ] Are provider tokens absent from API responses?
- [ ] Are paths normalized and traversal-safe?
- [ ] Are provider times converted according to the timezone standard?
