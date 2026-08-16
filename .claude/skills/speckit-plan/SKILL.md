---
name: speckit-plan
description: Produce the technical implementation plan for the active feature - plan.md plus research.md, data-model.md, and contracts - from spec.md and the constitution. Use when asked to plan, design the implementation, or choose the architecture or stack for a feature. Requires spec.md with no unresolved [NEEDS CLARIFICATION] markers.
---

# Spec Kit — Plan phase

## Preflight — run before anything else

You are in a **Claude Code cloud session**: all work stays on the **current git branch**. Never run `git checkout -b`, `git switch -c`, or `git branch`. The active feature is resolved from `.specify/feature.json` (override with `SPECIFY_FEATURE_DIRECTORY`), never from the branch name.

1. Run `bash .specify/scripts/bash/preflight.sh` to print the active feature, which artifacts exist, and the next valid phase.
2. Resolve paths: `bash .specify/scripts/bash/check-prerequisites.sh --json --paths-only`. If `spec.md` does not exist, **STOP** and tell the user to run the **speckit-specify** skill first.
3. Open `spec.md` and search for `[NEEDS CLARIFICATION`. If any marker remains, **STOP** - do not plan against an ambiguous spec. Tell the user to run the **speckit-clarify** skill (or resolve the markers) first.
4. If `plan.md` does not yet exist in the feature directory, seed it: `cp .specify/templates/plan-template.md <FEATURE_DIR>/plan.md` (never overwrite an existing plan.md).
5. **Constitution gate:** if `.specify/memory/constitution.md` is missing, or `grep -qE '\[[A-Z][A-Z0-9_]+\]|<!-- Example:|TODO' .specify/memory/constitution.md` matches — meaning it still holds bracketed template placeholders, the template's `<!-- Example: -->` guidance, or `TODO` markers — **STOP** with: "The constitution is still a template — run speckit-constitution first." Do not reconcile a plan against placeholder principles.

Do not proceed past this Preflight until the gate above is satisfied.

---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

1. **Setup**: Run `bash .specify/scripts/bash/check-prerequisites.sh --json --paths-only` from repo root and parse JSON for FEATURE_SPEC, IMPL_PLAN, SPECS_DIR, BRANCH. For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

2. **Load context**: Read FEATURE_SPEC and `.specify/memory/constitution.md`. Load IMPL_PLAN template (already copied).

3. **Execute plan workflow**: Follow the structure in IMPL_PLAN template to:
   - Fill Technical Context (mark unknowns as "NEEDS CLARIFICATION")
   - Fill Constitution Check section from constitution
   - Evaluate gates (ERROR if violations unjustified)
   - Phase 0: Generate research.md (resolve all NEEDS CLARIFICATION)
   - Phase 1: Generate data-model.md, contracts/, quickstart.md
   - Re-evaluate Constitution Check post-design

## Completion Report

Command ends after Phase 1 design. Report branch, IMPL_PLAN path, and generated artifacts.

## Phases

### Phase 0: Outline & Research

1. **Extract unknowns from Technical Context** above:
   - For each NEEDS CLARIFICATION → research task
   - For each dependency → best practices task
   - For each integration → patterns task

2. **Generate and dispatch research agents**:

   ```text
   For each unknown in Technical Context:
     Task: "Research {unknown} for {feature context}"
   For each technology choice:
     Task: "Find best practices for {tech} in {domain}"
   ```

3. **Consolidate findings** in `research.md` using format:
   - Decision: [what was chosen]
   - Rationale: [why chosen]
   - Alternatives considered: [what else evaluated]

**Output**: research.md with all NEEDS CLARIFICATION resolved

### Phase 1: Design & Contracts

**Prerequisites:** `research.md` complete

1. **Extract entities from feature spec** → `data-model.md`:
   - Entity name, fields, relationships
   - Validation rules from requirements
   - State transitions if applicable

2. **Define interface contracts** (if project has external interfaces) → `/contracts/`:
   - Identify what interfaces the project exposes to users or other systems
   - Document the contract format appropriate for the project type
   - Examples: public APIs for libraries, command schemas for CLI tools, endpoints for web services, grammars for parsers, UI contracts for applications
   - Skip if project is purely internal (build scripts, one-off tools, etc.)

3. **Create quickstart validation guide** → `quickstart.md`:
   - Document runnable validation scenarios that prove the feature works end-to-end
   - Include prerequisites, setup commands, test/run commands, and expected outcomes
   - Use links or references to contracts and data model details instead of duplicating them
   - Do not include full implementation code, model/service/controller bodies, migrations, or complete test suites
   - Keep this artifact as a validation/run guide; implementation details belong in `tasks.md` and the implementation phase

**Output**: data-model.md, /contracts/*, quickstart.md

## Key rules

- Use absolute paths for filesystem operations; use project-relative paths for references in documentation
- ERROR on gate failures or unresolved clarifications

## Done When

- [ ] Plan workflow executed and design artifacts generated
- [ ] Completion reported to user with branch, plan path, and generated artifacts
