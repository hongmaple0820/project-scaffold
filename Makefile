.PHONY: help gate gate-workflow gate-quality new-task resume verify validate preflight test-scaffold
help:
	@echo "make preflight | make new-task NAME=x LEVEL=M | make gate | make verify | make validate"
gate:
	bash scripts/gates/all.sh --all
gate-workflow:
	bash scripts/gates/all.sh --workflow
gate-quality:
	bash scripts/gates/all.sh --quality
new-task:
	@if [ -z "$(NAME)" ]; then echo "usage: make new-task NAME=x LEVEL=M"; exit 1; fi
	bash scripts/workflow/new-task.sh "$(NAME)" "$(or $(LEVEL),M)"
resume:
	bash scripts/workflow/resume.sh
verify:
	powershell -NoProfile -ExecutionPolicy Bypass -File scripts/workflow/verify.ps1
validate:
	bash scripts/validate-config.sh
preflight:
	bash scripts/preflight/all.sh
test-scaffold: verify
