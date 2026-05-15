.PHONY: help preflight new-task explore checkpoint gate gate-workflow gate-quality resume status lint-scaffold verify verify-list validate test-scaffold
help:
	@echo "make preflight | make new-task NAME=x LEVEL=M | make explore FILES='...' MSG='...'"
	@echo "make checkpoint PHASE=execute | make gate | make verify PROFILE=scaffold | make validate"
gate:
	bash scripts/gates/all.sh --all
gate-workflow:
	bash scripts/gates/all.sh --workflow
gate-quality:
	bash scripts/gates/all.sh --quality
new-task:
	@if [ -z "$(NAME)" ]; then echo "usage: make new-task NAME=x LEVEL=M"; exit 1; fi
	bash scripts/workflow/new-task.sh "$(NAME)" "$(or $(LEVEL),M)"
explore:
	@if [ -z "$(FILES)" ]; then echo "usage: make explore FILES='file1 file2' MSG='main contradiction'"; exit 1; fi
	bash scripts/workflow/explore.sh $(FILES) "$(MSG)"
checkpoint:
	bash scripts/workflow/checkpoint.sh "$(or $(PHASE),execute)"
resume:
	bash scripts/workflow/resume.sh
status: resume
lint-scaffold:
	bash scripts/workflow/lint-scaffold.sh
verify:
	bash scripts/workflow/verify.sh --profile "$(or $(PROFILE),scaffold)"
verify-list:
	bash scripts/workflow/verify.sh --list
validate:
	bash scripts/validate-config.sh
preflight:
	bash scripts/preflight/all.sh
test-scaffold:
	bash scripts/tests/run.sh
