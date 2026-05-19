# 开发工作流指南

**定位**: 认知工作流的完整操作手册

---

## 概述

```
探索 → 规划 → 执行 → 验证 → 沉淀
```

适用于 **M级** 和 **L级** 任务。

---

## 第一阶段：探索

### 目标
理解问题上下文，识别主要矛盾。

### 动作
1. 读取 CLAUDE.md
2. 扫描相关代码
3. 矛盾分析（核心难点是什么？）
4. 检查可用技能

### 输出
- 已读文件列表
- 主要矛盾识别

### 门控 G1
- [ ] 已读 ≥3 个相关文件
- [ ] 已识别主要矛盾

---

## 第二阶段：规划

### 目标
制定可执行的实施方案。

### 动作
1. 需求精炼（模糊度<20%）
2. 影响面推理（影响哪些模块？）
3. 契约定义：
   - 功能边界
   - 异常场景（≥3种）
   - 回滚方案

### 输出
- `.planning/tasks/YYYY-MM-DD-feature/mini-prd.md` - 用户侧需求和验收
- `.planning/tasks/YYYY-MM-DD-feature/plan.md` - 方案、边界、风险和回滚
- `.planning/tasks/YYYY-MM-DD-feature/verification.md` - 验证命令和结果
- `.planning/tasks/YYYY-MM-DD-feature/review.md` - 评审和剩余风险

### 门控 G2
- [ ] `plan.md` 已填写，且不保留 TODO/待填写
- [ ] 含范围、边界、验收、风险、回滚和验证
- [ ] **L级：人工确认通过**

---

## 第三阶段：执行

### 目标
按 TDD 流程实现功能。

### TDD 流程

```
RED → GREEN → REFACTOR
```

#### RED：写测试
```bash
# 1. 写测试
# 2. 运行测试，确认失败
make test
```

#### GREEN：写实现
```bash
# 1. 写最小实现使测试通过
# 2. 运行测试，确认通过
make test
```

#### REFACTOR：重构
```bash
# 1. 优化代码
# 2. 确保测试仍通过
make test
```

### 安全自检
- [ ] 输入校验
- [ ] SQL注入防护
- [ ] XSS防护
- [ ] 越权检查

### 门控 G3
- [ ] 测试文件先于实现文件
- [ ] 所有测试通过

---

## 第四阶段：验证

### 目标
通过所有质量门控。

### 门控检查

```bash
make gate-workflow
make gate-quality
make verify PROFILE=default
```

| 门控 | 检查项 |
|------|--------|
| G4 | 脚本语法和 Python helper 通过 |
| G5 | 脚手架自检通过 |
| G6 | metrics 和 M/L 任务产物存在 |
| G7 | 技术栈安全扫描无高危 |

### 验证原则
1. 工具验证，不脑补
2. 完整阅读输出
3. 确认与预期一致
4. 失败2次后 `/clear`

---

## 第五阶段：沉淀

### 目标
知识提取，经验复用。

### 泛化检查
- [ ] 这个 bug 是个案还是模式？
- [ ] 同模块有无同类问题？
- [ ] 上下游有无被波及？

### AI Slop 自检
- [ ] 代码是否像人类写的？
- [ ] 有无 AI 生成痕迹？

### 文档更新
- [ ] 任务证据 → `.planning/tasks/`
- [ ] 模块长期文档 → `docs/modules/<module>/`
- [ ] 架构决策 → `docs/adr/`
- [ ] 可复用模式 → `docs/skills/`

---

## 快捷命令

```bash
# 创建任务
make new-task NAME=feature-x LEVEL=M
make explore FILES='AGENTS.md CLAUDE.md README.md' MSG='主要矛盾'

# 运行门控
make gate

# 查看任务状态
make resume
```

---

**[← 返回文档中心](../README.md)**
