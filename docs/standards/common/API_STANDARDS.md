# 通用API规范

**版本**: v1.0  
**适用范围**: 所有项目

---

## 1. RESTful API设计原则

### 1.1 URL设计

**标准格式**:
```
/api/<version>/<module>/<resource>
```

**示例**:
```
/api/v1/account/list
/api/v1/file/upload
/api/v1/task/123
```

### 1.2 HTTP方法使用

| 方法 | 用途 | 示例 |
|------|------|------|
| GET | 查询资源 | `GET /api/v1/file/list` |
| POST | 创建资源/执行操作 | `POST /api/v1/file/upload` |
| PUT | 更新资源（完整） | `PUT /api/v1/file/rename` |
| PATCH | 更新资源（部分） | `PATCH /api/v1/user/profile` |
| DELETE | 删除资源 | `DELETE /api/v1/file/delete` |

### 1.3 状态码使用

| 状态码 | 场景 | 说明 |
|--------|------|------|
| 200 | 成功 | 正常响应 |
| 201 | 创建成功 | POST请求创建资源 |
| 400 | 请求参数错误 | 参数校验失败 |
| 401 | 未认证 | Token缺失或无效 |
| 403 | 无权限 | 已认证但无权访问 |
| 404 | 资源不存在 | URL或资源不存在 |
| 409 | 资源冲突 | 重复创建等 |
| 422 | 业务逻辑错误 | 参数合法但业务上不可行 |
| 429 | 请求过于频繁 | 限流触发 |
| 500 | 服务器错误 | 系统内部错误 |

---

## 2. 统一响应格式

### 2.1 成功响应

**标准格式**:
```json
{
    "code": 200,
    "msg": "success",
    "data": { }
}
```

**分页响应**:
```json
{
    "code": 200,
    "msg": "success",
    "data": {
        "records": [
            { "id": 1, "name": "xxx" }
        ],
        "total": 100,
        "size": 12,
        "pages": 9,
        "current": 1
    }
}
```

### 2.2 错误响应

**标准格式**:
```json
{
    "code": 3001,
    "msg": "账号不存在",
    "data": null
}
```

**带详细信息的错误**:
```json
{
    "code": 3002,
    "msg": "参数校验失败",
    "data": {
        "errors": [
            { "field": "fileName", "message": "文件名不能为空" }
        ]
    }
}
```

### 2.3 字段说明

| 字段 | 类型 | 说明 |
|------|------|------|
| code | int | 业务状态码，200表示成功 |
| msg | string | 提示信息 |
| data | object/array/null | 响应数据 |

---

## 3. 请求规范

### 3.1 请求参数传递方式

| 场景 | 传递方式 | 示例 |
|------|----------|------|
| GET请求参数 | Query String | `?current=1&size=12` |
| POST/PUT/PATCH请求体 | JSON Body | `{ "name": "xxx" }` |
| 路径参数 | URL Path | `/api/v1/file/123` |
| 请求头 | Header | `Authorization: Bearer xxx` |

### 3.2 分页参数规范

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| current | int | 否 | 1 | 当前页码，从1开始 |
| size | int | 否 | 12 | 每页条数 |

**示例**:
```
GET /api/v1/file/list?current=1&size=12
```

### 3.3 排序参数规范

| 参数 | 类型 | 说明 |
|------|------|------|
| sortField | string | 排序字段 |
| sortOrder | string | 排序方向：asc/desc |

**示例**:
```
GET /api/v1/file/list?sortField=createTime&sortOrder=desc
```

### 3.4 批量操作参数

**批量ID传递**:
```json
{
    "ids": [1, 2, 3]
}
```

或

```
DELETE /api/v1/file/delete?ids=1,2,3
```

---

## 4. 业务错误码规范

### 4.1 错误码分段

| 范围 | 类别 | 说明 |
|------|------|------|
| 200 | 成功 | 唯一成功码 |
| 1000-1999 | 系统级错误 | 通用系统错误 |
| 2000-2999 | 认证授权错误 | 登录、权限相关 |
| 3000-3999 | 业务错误 | 各业务模块自定义 |
| 4000-4999 | 第三方服务错误 | 外部API调用错误 |
| 5000-5999 | 预留 | 未来扩展 |

### 4.2 系统级错误码 (1000-1999)

| 错误码 | 含义 |
|--------|------|
| 1001 | 系统错误 |
| 1002 | 数据库错误 |
| 1003 | 缓存错误 |
| 1004 | 网络错误 |
| 1005 | 服务不可用 |

### 4.3 认证授权错误码 (2000-2999)

| 错误码 | 含义 |
|--------|------|
| 2001 | 未登录/Token缺失 |
| 2002 | Token过期 |
| 2003 | Token无效 |
| 2004 | 无权限访问 |
| 2005 | 账号被禁用 |
| 2006 | 登录失败 |

### 4.4 业务错误码分配规则

每个业务模块分配100个错误码：

| 模块 | 错误码范围 |
|------|-----------|
| 通用业务 | 3000-3099 |
| 用户模块 | 3100-3199 |
| 账号模块 | 3200-3299 |
| 文件模块 | 3300-3399 |
| 任务模块 | 3400-3499 |
| 上传模块 | 3500-3599 |
| 预留 | 3600-3999 |

**示例**:
```
3001 - 参数错误
3002 - 数据不存在
3201 - 账号不存在
3202 - 账号已过期
3301 - 文件不存在
3302 - 文件已存在
```

---

## 5. 版本控制规范

### 5.1 URL版本控制（推荐）

```
/api/v1/users
/api/v2/users
```

### 5.2 Header版本控制（可选）

```
GET /api/users
X-API-Version: v2
```

### 5.3 版本升级原则

- 向后兼容的变更：保持当前版本
- 破坏性变更：创建新版本
- 旧版本至少支持3-6个月

---

## 6. 安全规范

### 6.1 认证方式

**Bearer Token**:
```
Authorization: Bearer <token>
```

**API Key**（内部服务）:
```
X-API-Key: <api-key>
```

### 6.2 请求头规范

| Header | 用途 | 示例 |
|--------|------|------|
| Content-Type | 内容类型 | `application/json` |
| Authorization | 认证信息 | `Bearer xxx` |
| X-Request-ID | 请求追踪ID | `uuid` |
| X-Client-Version | 客户端版本 | `1.2.3` |
| Accept-Language | 语言偏好 | `zh-CN`, `en-US` |

### 6.3 敏感数据处理

- 密码、Token等敏感字段不在URL中传递
- 敏感数据在响应中脱敏或省略
- 使用HTTPS传输

---

## 7. API文档规范

### 7.1 文档格式

推荐使用 OpenAPI 3.0 (Swagger) 格式

### 7.2 必需文档内容

- 接口URL和方法
- 请求参数说明（类型、必填、示例）
- 响应字段说明
- 错误码说明
- 调用示例

### 7.3 代码注释生成文档

**Go示例**:
```go
// FileList 获取文件列表
// @Summary 获取指定账号的文件列表
// @Description 支持分页、排序、关键词搜索
// @Tags 文件模块
// @Accept json
// @Produce json
// @Param accountId query int true "账号ID"
// @Param folderId query string false "文件夹ID"
// @Success 200 {object} types.FileListRes
// @Router /api/v1/file/list [get]
```
