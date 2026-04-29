# Makefile - 通用项目脚手架
.PHONY: help dev build test lint fmt gate plan checkpoint resume install-tools validate test-scaffold

# 默认目标
.DEFAULT_GOAL := help

# 检测操作系统
UNAME_S := $(shell uname -s 2>/dev/null || echo Windows)

# 颜色输出
ifdef COMSPEC
    RED=
    GREEN=
    YELLOW=
    BLUE=
    NC=
else
    RED=\033[0;31m
    GREEN=\033[0;32m
    YELLOW=\033[0;33m
    BLUE=\033[0;34m
    NC=\033[0m
endif

## help: 显示本帮助信息
help:
	@echo ""
	@echo "$(BLUE)========================================$(NC)"
	@echo "$(BLUE)   项目脚手架 - 可用命令$(NC)"
	@echo "$(BLUE)========================================$(NC)"
	@echo ""
	@echo "$(GREEN)开发:$(NC)"
	@echo "  make dev          启动开发环境"
	@echo "  make build        构建项目"
	@echo "  make test         运行测试"
	@echo "  make lint         代码检查"
	@echo "  make fmt          格式化代码"
	@echo ""
	@echo "$(GREEN)质量门控:$(NC)"
	@echo "  make gate         运行所有门控"
	@echo "  make validate     验证配置"
	@echo "  make test-scaffold 脚手架自测"
	@echo ""
	@echo "$(GREEN)项目管理:$(NC)"
	@echo "  make plan NAME=x  创建新计划"
	@echo "  make checkpoint   保存状态检查点"
	@echo "  make resume       恢复之前状态"
	@echo "  make graphify     构建知识图谱"
	@echo ""
	@echo "$(GREEN)环境:$(NC)"
	@echo "  make install-tools 安装推荐工具"
	@echo "  make preflight     环境预检"
	@echo ""

## dev: 启动开发环境
# 请根据技术栈修改具体命令
dev:
	@echo "$(BLUE)[MAKE] 启动开发环境...$(NC)"
	@echo "$(YELLOW)[INFO] 请根据技术栈实现具体命令$(NC)"
	# Go示例: go run .
	# Node示例: npm run dev
	# Python示例: python manage.py runserver

## build: 构建项目
build:
	@echo "$(BLUE)[MAKE] 构建项目...$(NC)"
	@mkdir -p bin
	@echo "$(YELLOW)[INFO] 请根据技术栈实现具体命令$(NC)"
	# Go示例: go build -o bin/app .
	# Node示例: npm run build
	# Python示例: pyinstaller

## test: 运行测试
test:
	@echo "$(BLUE)[MAKE] 运行测试...$(NC)"
	@mkdir -p .agent/logs
	@echo "$(YELLOW)[INFO] 请根据技术栈实现具体命令$(NC)"
	# Go示例: go test ./... -race -json > .agent/logs/test.json 2>&1

## lint: 代码检查
lint:
	@echo "$(BLUE)[MAKE] 运行代码检查...$(NC)"
	@mkdir -p .agent/logs
	@echo "$(YELLOW)[INFO] 请根据技术栈实现具体命令$(NC)"
	# Go示例: golangci-lint run --out-format=json > .agent/logs/lint.json 2>&1 || true

## fmt: 格式化代码
fmt:
	@echo "$(BLUE)[MAKE] 格式化代码...$(NC)"
	@echo "$(YELLOW)[INFO] 请根据技术栈实现具体命令$(NC)"
	# Go示例: go fmt ./...
	# Node示例: prettier --write .

## gate: 运行所有质量门控
gate:
	@echo "$(BLUE)[MAKE] 运行质量门控...$(NC)"
	@bash scripts/gates/all.sh

## plan: 创建新计划 (使用: make plan NAME=feature-name)
plan:
	@if [ -z "$(NAME)" ]; then \
		echo "$(RED)[ERROR] 请指定名称: make plan NAME=feature-name$(NC)"; \
		exit 1; \
	fi
	@bash scripts/init-plan.sh

## checkpoint: 保存状态检查点
checkpoint:
	@echo "$(BLUE)[MAKE] 保存状态检查点...$(NC)"
	@bash scripts/checkpoint/save.sh $(PHASE)

## resume: 恢复之前状态
resume:
	@echo "$(BLUE)[MAKE] 恢复之前状态...$(NC)"
	@bash scripts/checkpoint/resume.sh

## validate: 验证配置
validate:
	@echo "$(BLUE)[MAKE] 验证配置...$(NC)"
	@bash scripts/validate-config.sh

## test-scaffold: 运行脚手架自测
test-scaffold:
	@echo "$(BLUE)[MAKE] 运行脚手架自测...$(NC)"
	@bash scripts/tests/run.sh

## preflight: 环境预检
preflight:
	@echo "$(BLUE)[MAKE] 环境预检...$(NC)"
	@bash scripts/preflight/all.sh

## graphify: 构建知识图谱
graphify:
	@echo "$(BLUE)[MAKE] 构建知识图谱...$(NC)"
	@if command -v graphify >/dev/null 2>&1; then \
		graphify .; \
		echo "$(GREEN)[OK] 知识图谱已构建$(NC)"; \
	else \
		echo "$(YELLOW)[WARN] graphify 未安装$(NC)"; \
		echo "$(YELLOW)[HINT] 运行: pip install graphifyy$(NC)"; \
	fi

## install-tools: 安装推荐工具
install-tools:
	@echo "$(BLUE)[MAKE] 安装推荐工具...$(NC)"
	@echo "$(YELLOW)[INFO] 请根据操作系统选择安装命令$(NC)"
	@echo ""
	@echo "macOS:"
	@echo "  brew install git make jq golangci-lint gh ripgrep fd bat"
	@echo ""
	@echo "Linux (Ubuntu/Debian):"
	@echo "  sudo apt-get install git make jq"
	@echo "  # 其他工具请查看官方文档"
	@echo ""
	@echo "Go工具:"
	@echo "  go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest"
	@echo "  go install github.com/securego/gosec/v2/cmd/gosec@latest"
	@echo ""
	@echo "Python工具:"
	@echo "  pip install graphifyy"
