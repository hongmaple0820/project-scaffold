# 规范体系

本目录保存跨项目可复用的工程规范。业务项目差异应写入 `docs/standards/projects/`，不要复制整套通用规范造成漂移。

## 分层

```text
docs/standards/
|-- README.md
|-- common/
|   |-- GIT_STANDARDS.md
|   |-- DOCUMENT_STANDARDS.md
|   |-- TEAM_COLLABORATION.md
|   |-- SECURITY_SENSITIVE_DATA.md
|   `-- ...
`-- projects/
    `-- <project>/
```

## 使用顺序

1. 读根目录 `AGENTS.md` 和 `CLAUDE.md`，确认任务等级、红线和验证要求。
2. 读本目录通用规范。
3. 读目标项目的 `projects/<project>/` 差异规范。
4. 如项目规范和通用规范冲突，记录原因、影响和退出条件。

## 规范级别

| 级别 | 含义 | 处理方式 |
| --- | --- | --- |
| MUST | 必须遵守 | 不满足则阻断 |
| SHOULD | 默认遵守 | 偏离必须说明理由 |
| MAY | 可选 | 按项目需要采用 |

## 维护规则

- 一个事实只保留一个主来源，其他文档链接引用。
- 架构、接口、配置、服务矩阵、验证命令变化时，同步更新规范索引。
- 冲突解决后检查相对链接、版本说明和上下游模块关系。
- 临时测试报告、截图和探索草稿不进入长期规范。

## SCALE 最新工作流相关规范

- `scale governance mode` 用于判断治理强度，不替代人工风险判断。
- `scale skill radar` 用于工具推荐和证据要求，不自动安装未知第三方工具。
- `scale context budget` 用于控制 token 成本，避免把生成报告和历史草稿塞进上下文。
- `scale eval run` 用于评估工作流效果，失败案例应进入复盘，而不是被删除。
- `scale artifact dashboard` 用于人类审阅，源事实仍以 Markdown、代码和命令证据为准。
