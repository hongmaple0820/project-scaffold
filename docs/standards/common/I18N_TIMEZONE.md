# Internationalization and Timezone Standard

**Version**: v1.1
**Date**: 2026-05-15
**Scope**: Netdisk backend services, gateway, frontend, API contracts, database fields
**Platform source**: `F:/project/amdox/java/docs/standards/i18n-timezone.md`

---

## 1. Mandatory Protocol

All new netdisk API requests must carry:

```http
Accept-Language: zh-CN
X-Time-Zone: Asia/Shanghai
```

Rules:

- `Accept-Language` uses canonical language codes aligned with the Java language code table.
- `X-Time-Zone` uses IANA timezone IDs, such as `Asia/Shanghai` or `America/Los_Angeles`.
- Time point payload fields use ISO 8601 offset date-time, such as `2026-05-14T09:30:00+08:00`.
- Pure date fields use `YYYY-MM-DD` and do not participate in timezone conversion.
- Business calculation and database business time semantics use `Asia/Shanghai`.
- Response time points are converted to the client timezone from `X-Time-Zone` and returned with offset.

## 2. Language Standard

Language resolution order:

1. `Accept-Language` normalized to canonical code.
2. User account `locale`, when the request is authenticated and the value is supported.
3. System default `zh-CN`.

Minimum supported language codes for netdisk:

| Code | Meaning | Frontend directory | Backend message target |
| --- | --- | --- | --- |
| `zh-CN` | Simplified Chinese | `src/locales/zh-CN` | `messages_zh_CN.*` or Go map/catalog equivalent |
| `en` | English | `src/locales/en` | `messages_en.*` or Go map/catalog equivalent |

Additional languages must use canonical codes from the Java language code table. Browser aliases such as `zh`, `zh-Hans`, `en-US`, and `en-GB` must be normalized before use as business values.

## 3. Backend i18n Rules

The Go backend must expose one i18n path, targeted as `pkg/i18n`.

Responsibilities:

- Parse and normalize `Accept-Language`.
- Resolve fallback language.
- Map error codes to message keys.
- Interpolate safe parameters into localized messages.
- Return user-facing localized `msg` in the unified response envelope.
- Keep internal error details in logs only.

Message key naming:

| Key pattern | Usage |
| --- | --- |
| `common.error.invalidParam` | Shared validation errors |
| `common.error.unauthorized` | Shared auth errors |
| `netdisk.error.3201` | Netdisk business error by stable code |
| `netdisk.driver.baidu.authExpired` | Provider-specific business error |
| `netdisk.validation.storageName.required` | Field validation |

Error response example:

```json
{
  "code": 3201,
  "msg": "File not found",
  "data": null
}
```

Logs must retain error code, trace ID, key business identifiers, and original error. Logs must not expose tokens, secrets, SQL internals, stack traces in API responses, or third-party raw sensitive responses.

## 4. Frontend i18n Rules

Frontend user-facing text must come from the i18n resource layer.

Required targets:

- `amdox-netdisk-ui/src/i18n.ts`
- `amdox-netdisk-ui/src/locales/zh-CN/*`
- `amdox-netdisk-ui/src/locales/en/*`
- `amdox-netdisk-ui/src/api/request.ts`

Rules:

- Pages, menus, buttons, form labels, validation messages, empty states, and API error prompts use i18n keys.
- Do not concatenate translated fragments. Use interpolation.
- New API calls must go through the unified request layer.
- The request layer injects `Accept-Language` and `X-Time-Zone`.
- UI component library locale must follow the same resolved frontend locale.

Interpolation example:

```ts
t('file.deleteConfirm', { name: fileName })
```

## 5. Timezone Standard

The platform business timezone is:

```text
Asia/Shanghai
```

Backend responsibilities:

- Read `X-Time-Zone`.
- Validate it as an IANA timezone.
- Parse input time points by their explicit offset or source timezone.
- Convert business time points to `Asia/Shanghai` before business calculation and persistence.
- Convert output time points to the client timezone before response.
- Reject missing or invalid timezone on new APIs with a stable error code.
- Compatibility APIs may temporarily fall back to `Asia/Shanghai`, but must log the fallback.

Frontend responsibilities:

- Resolve local timezone with `Intl.DateTimeFormat().resolvedOptions().timeZone`.
- Validate the resolved timezone before sending it.
- Fall back to `Asia/Shanghai` only when the runtime cannot provide a valid IANA timezone.
- Display backend time points in the user timezone.
- Keep pure dates as `YYYY-MM-DD`.

## 6. Database Time Rules

Business time fields in MySQL use `DATETIME` with explicit comments that state `Asia/Shanghai`.

Example:

```sql
expire_time DATETIME COMMENT 'Expiration time, Asia/Shanghai business time'
```

MySQL DSN rules:

- Do not rely on `loc=Local`.
- Use an explicit location such as `loc=Asia%2FShanghai` when parsing `DATETIME` into Go `time.Time`.
- Keep `parseTime=true`.

Cross-border or third-party source times that need traceability must store source semantics:

```sql
source_timezone VARCHAR(64) COMMENT 'Original source timezone, IANA format',
source_time_raw VARCHAR(128) COMMENT 'Original provider time value',
source_local_time DATETIME COMMENT 'Original provider local time'
```

## 7. Third-Party Provider Time Rules

Provider time handling:

1. Parse provider time using the provider's documented format.
2. Preserve raw provider time only in sync logs or provider metadata when needed for audit.
3. Convert business-facing time to `Asia/Shanghai` before writing business tables.
4. Return API time using the request `X-Time-Zone`.

Provider-specific timezone assumptions must be documented in the driver or provider client standard.

## 8. Testing Matrix

Minimum verification matrix for i18n/timezone work:

| Case | Expected result |
| --- | --- |
| `Accept-Language: zh-CN` | Chinese user-facing error message |
| `Accept-Language: en` | English user-facing error message |
| Missing `Accept-Language` | Fallback `zh-CN` |
| `X-Time-Zone: Asia/Shanghai` | Response offset `+08:00` when applicable |
| `X-Time-Zone: America/Los_Angeles` | Response converted to client offset |
| Invalid `X-Time-Zone` | Stable parameter error code and localized message |
| Pure date `2026-05-14` | No timezone conversion |
| ISO offset time `2026-05-13T18:30:00-07:00` | Converted to `Asia/Shanghai` for business storage |

## 9. Embedded Web and Host App Rules

Pure Web components embedded into IWB, cube, LMS, desktop WebView, or other host applications must use the same i18n and timezone contract as standalone Web.

Host applications must pass a startup context before the component sends business requests:

```ts
type SyncNestEmbedContext = {
  accessToken: string
  locale?: string
  timezone?: string
  hostApp: 'standalone' | 'iwb' | 'cube' | 'lms' | 'desktop'
  bridgeVersion?: string
  capabilities?: Record<string, boolean>
}
```

Resolution order for embedded mode:

1. `SyncNestEmbedContext.locale` and `SyncNestEmbedContext.timezone`.
2. Host bridge values, when the host exposes them.
3. User preference stored by SyncNest.
4. Browser/runtime values.
5. Default fallback: `zh-CN` and `Asia/Shanghai`.

Rules:

- Embedded components must not read arbitrary host globals for locale or timezone.
- Host apps must not translate SyncNest message keys themselves unless they own the same locale catalog version.
- Client/native bridge errors must return stable `code` and `messageKey`; the Web component renders localized text.
- Host apps may pin a Web component version. Locale pack versions must match the component version in `embed-manifest.json`.
- If host locale is unsupported, the component falls back to `zh-CN` and logs the unsupported value with trace ID.
- If host timezone is invalid, the component must reject new business APIs that require timezone correctness, or fall back only for explicitly compatible legacy APIs.

## 9. Prohibited Patterns

- New frontend code calling backend outside the unified request layer.
- New UI text hardcoded in page or component code.
- New backend error messages returned directly from raw errors.
- New API time point fields without timezone or offset.
- Business code writing `time.Now()` directly to persistent business fields without a business-time helper.
- MySQL DSN using implicit local timezone for business time behavior.
