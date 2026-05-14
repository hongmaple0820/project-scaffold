# Graph Report - .  (2026-05-14)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 37 nodes · 62 edges · 8 communities detected
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 3|Community 3]]
- [[_COMMUNITY_Community 4|Community 4]]
- [[_COMMUNITY_Community 5|Community 5]]
- [[_COMMUNITY_Community 6|Community 6]]
- [[_COMMUNITY_Community 7|Community 7]]

## God Nodes (most connected - your core abstractions)
1. `Standards System` - 9 edges
2. `Cognitive Workflow` - 7 edges
3. `Project-Specific Standards` - 7 edges
4. `Quality Gates (G1-G7)` - 6 edges
5. `CONFIG_WEBSITE_OPTIMIZATION` - 6 edges
6. `Hooks System` - 5 edges
7. `Documentation Center` - 5 edges
8. `Getting Started Guide` - 4 edges
9. `Project Scaffold v2.0` - 3 edges
10. `Absolute Red Lines (R1-R6)` - 3 edges

## Surprising Connections (you probably didn't know these)
- `CONFIG_WEBSITE_OPTIMIZATION` --guides--> `Project Scaffold v2.0`  [EXTRACTED]
  CONFIG_WEBSITE_OPTIMIZATION.md → README.md
- `Workflow State Machine` --implements--> `Cognitive Workflow`  [EXTRACTED]
  CLAUDE.md → docs/guides/DEVELOPMENT_WORKFLOW.md
- `Knowledge Graph (graphify)` --guides--> `Cognitive Workflow`  [EXTRACTED]
  CLAUDE.md → docs/guides/DEVELOPMENT_WORKFLOW.md
- `Hooks System` --implements--> `TDD Compliance Check`  [EXTRACTED]
  CLAUDE.md → CONFIG_WEBSITE_OPTIMIZATION.md
- `Contributing Guidelines` --references--> `Git Standards`  [EXTRACTED]
  CONTRIBUTING.md → docs/standards/common/GIT_STANDARDS.md

## Hyperedges (group relationships)
- **Agent Execution Framework** — claude_md, agents_md, cognitive_workflow, quality_gates, workflow_state_machine [INFERRED]
- **Common Standards Layer** — standards_system, naming_standard, api_standard, database_standard, git_standard [INFERRED]
- **SDD Three-Layer Artifacts** — spec_template, plan_template, tasks_template, cognitive_workflow [INFERRED]

## Communities

### Community 0 - "Community 0"
Cohesion: 0.33
Nodes (9): Cognitive Workflow, Configuration Layering, CONFIG_WEBSITE_OPTIMIZATION, Contributing Guidelines, Hooks System, Quality Gates (G1-G7), State Management & Checkpoint Recovery, TDD Compliance Check (+1 more)

### Community 1 - "Community 1"
Cohesion: 0.46
Nodes (8): API Standards, Database Standards, Document Standards, Git Standards, Naming Standards, Project-Specific Standards, Standards System, Team Collaboration Standards

### Community 2 - "Community 2"
Cohesion: 0.4
Nodes (6): ADR Template, Architecture Overview, Development Workflow Guide, Documentation Center, Getting Started Guide, Skills Manual

### Community 3 - "Community 3"
Cohesion: 0.67
Nodes (3): Knowledge Graph (graphify), MCP Servers, Skills Configuration

### Community 4 - "Community 4"
Cohesion: 0.67
Nodes (2): Project Scaffold v2.0, Task Tier Classification (S/M/L)

### Community 5 - "Community 5"
Cohesion: 0.67
Nodes (3): Plan Template (plan.md), Spec Template (spec.md), Tasks Template (tasks.md)

### Community 6 - "Community 6"
Cohesion: 1.0
Nodes (2): Agent Honesty Protocol, Anti-Laziness Mechanisms

### Community 7 - "Community 7"
Cohesion: 1.0
Nodes (2): Code Rules (Regex-Verifiable), Absolute Red Lines (R1-R6)

## Knowledge Gaps
- **5 isolated node(s):** `MCP Servers`, `Task Tier Classification (S/M/L)`, `ADR Template`, `Spec Template (spec.md)`, `Tasks Template (tasks.md)`
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Community 4`** (3 nodes): `AGENTS.md`, `Project Scaffold v2.0`, `Task Tier Classification (S/M/L)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 6`** (2 nodes): `Agent Honesty Protocol`, `Anti-Laziness Mechanisms`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 7`** (2 nodes): `Code Rules (Regex-Verifiable)`, `Absolute Red Lines (R1-R6)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Getting Started Guide` connect `Community 2` to `Community 1`, `Community 3`?**
  _High betweenness centrality (0.251) - this node is a cross-community bridge._
- **Why does `Standards System` connect `Community 1` to `Community 2`?**
  _High betweenness centrality (0.246) - this node is a cross-community bridge._
- **Why does `Documentation Center` connect `Community 2` to `Community 1`?**
  _High betweenness centrality (0.132) - this node is a cross-community bridge._
- **What connects `MCP Servers`, `Task Tier Classification (S/M/L)`, `ADR Template` to the rest of the system?**
  _5 weakly-connected nodes found - possible documentation gaps or missing edges._