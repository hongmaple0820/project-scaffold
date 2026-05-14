# Engineering Agent Workflow Optimization Plan

## Status

Implemented as a lightweight workflow scaffold.

## Core Principles

1. Explore before plan.
2. Verify before completion.
3. Keep one canonical workflow state: `.agent/state/current.json`.
4. Use task artifacts for M/L/CRITICAL work.
5. Keep language-specific gates thin and executable.

## Differentiation

- Scaffold projects verify scripts, templates, docs, and generated structure.
- Java microservices verify Maven modules with compile/test targets.
- Frontend projects verify lint/test/build/typecheck when package scripts exist.

## Definition of Done

- Gate dry-run discovers workflow and quality gates.
- `new-task -> explore -> G1` works.
- Language-specific `verify.ps1` exists.
- Metrics file records workflow results.

## Project

Project Scaffold
