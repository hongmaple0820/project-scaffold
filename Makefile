.PHONY: help preflight new-task explore checkpoint gate gate-workflow gate-quality resume status lint-scaffold verify verify-list validate test-scaffold scale-version scale-mode scale-context scale-codegraph scale-eval scale-radar scale-dashboard scale-smoke
SCALE ?= scale
TASK ?= workflow scaffold adaptation
FILES ?= AGENTS.md,CLAUDE.md,README.md
LEVEL ?= M
PHASE ?= plan
SERVICES ?=

help:
	@echo "make preflight | make new-task NAME=x LEVEL=M | make explore FILES='...' MSG='...'"
	@echo "make checkpoint PHASE=execute | make gate | make verify PROFILE=scaffold | make validate"
	@echo "make scale-smoke TASK='...' FILES='AGENTS.md,README.md'"
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
scale-version:
	$(SCALE) --version
scale-mode:
	$(SCALE) governance mode --task "$(TASK)" --files "$(FILES)"
scale-context:
	$(SCALE) context budget --dir .
scale-codegraph:
	$(SCALE) codegraph status --dir .
scale-eval:
	$(SCALE) eval run --dir .
scale-radar:
	$(SCALE) skill radar --dir . --task "$(TASK)" --phase "$(PHASE)" --level "$(LEVEL)" --files "$(FILES)" --services "$(SERVICES)"
scale-dashboard:
	$(SCALE) artifact dashboard --dir . --lang zh
scale-smoke:
	$(SCALE) --version
	$(SCALE) governance mode --task "$(TASK)" --files "$(FILES)"
	$(SCALE) context budget --dir .
	$(SCALE) codegraph status --dir .
	$(SCALE) eval run --dir .
	$(SCALE) artifact dashboard --dir . --lang zh
