#!/bin/bash
# plan.sh — 创建计划目录和模板文件
# 用法: bash scripts/workflow/plan.sh "feature-name"
# 产出: docs/plans/YYYY-MM-DD-{name}/ (spec.md + plan.md + tasks.md)

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
NAME="${1:-unnamed}"

if [ "$NAME" = "unnamed" ]; then
    echo "[PLAN] 用法: bash scripts/workflow/plan.sh feature-name"
    exit 1
fi

DATE=$(date +%Y-%m-%d)
PLAN_DIR="$PROJECT_ROOT/docs/plans/${DATE}-${NAME}"
TEMPLATES="$PROJECT_ROOT/templates/plan"

mkdir -p "$PLAN_DIR"

# 从模板创建文件（如果模板存在）
for f in spec.md plan.md tasks.md; do
    if [ -f "$TEMPLATES/$f" ]; then
        sed "s/{{NAME}}/$NAME/g; s/{{DATE}}/$DATE/g" "$TEMPLATES/$f" > "$PLAN_DIR/$f"
    else
        cat > "$PLAN_DIR/$f" << EOF
# ${f%.md} — $NAME

> 日期: $DATE
> 任务: $NAME

（在此填写内容）
EOF
    fi
done

# 记录到状态文件
STATE_DIR="$PROJECT_ROOT/.agent/state"
mkdir -p "$STATE_DIR"

echo "[PLAN] ✅ 已创建计划目录: $PLAN_DIR"
echo "[PLAN] 包含: spec.md, plan.md, tasks.md"
echo "[PLAN] 下一步: 填写 spec.md（WHAT）→ plan.md（HOW）→ tasks.md（DO）"
