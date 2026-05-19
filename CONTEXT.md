# CONTEXT.md

Project: project-scaffold

| Term | Definition | Examples | Aliases | Source |
|------|------------|----------|---------|--------|
| Governance scaffold | Reusable workflow and standards baseline copied into product projects | `scripts/workflow`, `docs/standards` | scaffold | `README.md` |
| Service matrix | Project-specific list of services and validation commands | `.agent/project.json` | verification matrix | `.agent/project.json` |
| Evidence | Command output or artifact proving what ran | `verification.md`, `.scale/evidence` | proof | SCALE workflow |
| Generated artifact | Derived report or dashboard that must not become the source of truth | `.scale/reports/*.html` | HTML artifact | `.scale/output-policy.json` |

## Rejected Meanings

- Do not treat project-scaffold as a business application template.
- Do not hardcode netdisk, Java, frontend, or other product-specific ports and commands into generic scaffold rules.
