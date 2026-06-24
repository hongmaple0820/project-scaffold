.PHONY: help preflight new-task explore checkpoint gate gate-workflow gate-quality resume status lint-scaffold verify verify-list validate test-scaffold bootstrap-scale bootstrap-scale-install bootstrap-scale-latest workflow-upgrade-check workflow-upgrade-plan workflow-upgrade-apply workflow-upgrade-rollback workflow-upgrade-verify workflow-aios-adopt scale-version scale-mode scale-context scale-codegraph scale-eval scale-radar scale-dashboard scale-smoke
SCALE ?= scale
SCALE_VERSION ?= locked
TASK ?= workflow scaffold adaptation
FILES ?= AGENTS.md,CLAUDE.md,README.md
LEVEL ?= M
BUDGET ?= 8000
PHASE ?= plan
PROFILE ?= scaffold
SERVICES ?=

help:
	@echo "make preflight | make new-task NAME=x LEVEL=M | make explore FILES='...' MSG='...'"
	@echo "make checkpoint PHASE=execute | make gate | make verify PROFILE=scaffold | make verify-list | make validate"
	@echo "make scale-smoke TASK='...' FILES='AGENTS.md,README.md'"
	@echo "make bootstrap-scale | make bootstrap-scale-install | make bootstrap-scale-latest"
	@echo "make workflow-upgrade-check | make workflow-upgrade-plan | make workflow-upgrade-apply | make workflow-upgrade-verify | make workflow-aios-adopt"
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
bootstrap-scale:
	powershell -NoProfile -ExecutionPolicy Bypass -File scripts/bootstrap-scale.ps1 -Version "$(or $(SCALE_VERSION),locked)"
bootstrap-scale-install:
	powershell -NoProfile -ExecutionPolicy Bypass -File scripts/bootstrap-scale.ps1 -Version "$(or $(SCALE_VERSION),locked)" -AutoInstall
bootstrap-scale-latest:
	powershell -NoProfile -ExecutionPolicy Bypass -File scripts/bootstrap-scale.ps1 -Version latest -AutoInstall
workflow-upgrade-check:
	$(SCALE) upgrade check --dir . --lang zh
workflow-upgrade-plan:
	$(SCALE) upgrade plan --dir . --html --lang zh
workflow-upgrade-apply:
	$(SCALE) upgrade apply --dir . --confirm --lang zh
workflow-upgrade-rollback:
	$(SCALE) upgrade rollback --dir . --lang zh
workflow-upgrade-verify:
	$(SCALE) preflight --dir . --service all --preflight-profile quick
workflow-aios-adopt:
	$(SCALE) ai-os adopt --dir . --task "$(TASK)" --files "$(FILES)" --level "$(LEVEL)" --budget "$(BUDGET)" --lang zh
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
