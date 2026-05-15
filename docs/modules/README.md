# Module Documentation

派生项目在这里按模块维护长期文档。任务过程记录放在 `docs/worklog/tasks/`，不能替代模块文档。

推荐结构：

```text
docs/modules/<module>/
├── README.md
├── api.md
├── data.md
├── flows.md
└── risks.md
```

维护规则：

- 新模块必须有 `README.md`，说明职责、边界、上游和下游。
- API、数据结构、权限、配置和用户流程变更必须同步对应模块文档。
- 跨模块关系写入 `docs/architecture/`，模块文档只写本模块视角。
