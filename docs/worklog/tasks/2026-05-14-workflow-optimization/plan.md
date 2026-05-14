# plan - 2026-05-14-workflow-optimization

Date: 2026-05-14
Level: M

## Notes

## Scope / 范围

- 优化脚手架的规范入口、工作流文档、门禁说明和自检脚本。

## Boundary / 边界

- 不引入业务项目专属规则。
- 不重写工作流状态核心，保留 `scripts/lib/workflow_state.py` 的既有行为。
- 不触碰其他仓库。

## Acceptance Criteria / 验收标准

- 根目录 `AGENTS.md`、`CLAUDE.md`、`README.md` 能清楚说明脚手架工作方式。
- `docs/workflow/README.md` 无乱码，并与真实脚本行为一致。
- G2/G4/G5/all 门禁能反映真实检查范围。
- 脚手架自检命令可运行。

## Risks / 风险

- 派生项目可能缺少语言工具链，质量门禁需要按 `.agent/project.json` 配置落地。

## Rollback / 回滚方案

- 回退本次文档和脚本改动即可，不涉及数据或生成产物迁移。

## Verification / 验证

- 运行 `bash scripts/gates/all.sh --dry-run`。
- 运行 `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/workflow/verify.ps1`。
- 运行 `bash scripts/preflight/all.sh`。
