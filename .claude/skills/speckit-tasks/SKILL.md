---
name: speckit-tasks
description: Break the active feature's plan.md into an actionable, dependency-ordered tasks.md grouped by user story. Use when asked to generate tasks, create the task list, or build the work breakdown for a feature. Requires plan.md.
---

# Spec Kit — Tasks phase

## Preflight — run before anything else

You are in a **Claude Code cloud session**: all work stays on the **current git branch**. Never run `git checkout -b`, `git switch -c`, or `git branch`. The active feature is resolved from `.specify/feature.json` (override with `SPECIFY_FEATURE_DIRECTORY`), never from the branch name.

1. Run `bash .specify/scripts/bash/preflight.sh` to print the active feature, which artifacts exist, and the next valid phase.
2. Gate on the plan: `bash .specify/scripts/bash/check-prerequisites.sh --json`. If it exits non-zero or prints an ERROR about a missing `plan.md`, **STOP** and tell the user to run the **speckit-plan** skill first.
3. If `tasks.md` does not yet exist in the feature directory, seed it: `cp .specify/templates/tasks-template.md <FEATURE_DIR>/tasks.md` (never overwrite an existing tasks.md).
4. **Constitution gate:** if `.specify/memory/constitution.md` is missing, or `grep -qE '\[[A-Z][A-Z0-9_]+\]|<!-- Example:|TODO' .specify/memory/constitution.md` matches — meaning it still holds bracketed template placeholders, the template's `<!-- Example: -->` guidance, or `TODO` markers — **STOP** with: "The constitution is still a template — run speckit-constitution first."

Do not proceed past this Preflight until the gate above is satisfied.

---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

1. **Setup**: Run `bash .specify/scripts/bash/check-prerequisites.sh --json` from repo root and parse FEATURE_DIR, TASKS_TEMPLATE, and AVAILABLE_DOCS list. `FEATURE_DIR` and `TASKS_TEMPLATE` must be absolute paths when provided. `AVAILABLE_DOCS` is a list of document names/relative paths available under `FEATURE_DIR` (for example `research.md` or `contracts/`). For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

2. **Load design documents**: Read from FEATURE_DIR:
   - **Required**: plan.md (tech stack, libraries, structure), spec.md (user stories with priorities)
   - **Optional**: data-model.md (entities), contracts/ (interface contracts), research.md (decisions), quickstart.md (test scenarios)
   - **IF EXISTS**: Load `.specify/memory/constitution.md` for project principles and governance constraints
   - Note: Not all projects have all documents. Generate tasks based on what's available.

3. **Execute task generation workflow**:
   - Load plan.md and extract tech stack, libraries, project structure
   - Load spec.md and extract user stories with their priorities (P1, P2, P3, etc.)
   - If data-model.md exists: Extract entities and map to user stories
   - If contracts/ exists: Map interface contracts to user stories
   - If research.md exists: Extract decisions for setup tasks
   - Generate tasks organized by user story (see Task Generation Rules below)
   - Generate dependency graph showing user story completion order
   - Create parallel execution examples per user story
   - Validate task completeness (each user story has all needed tasks, independently testable)

4. **Generate tasks.md**: Read the tasks template from TASKS_TEMPLATE (from the JSON output above) and use it as structure. If TASKS_TEMPLATE is empty, fall back to `.specify/templates/tasks-template.md`. Fill with:
   - Correct feature name from plan.md
   - Phase 1: Setup tasks (project initialization)
   - Phase 2: Foundational tasks (blocking prerequisites for all user stories)
   - Phase 3+: One phase per user story (in priority order from spec.md)
   - Each phase includes: story goal, independent test criteria, tests (if requested), implementation tasks
   - Final Phase: Polish & cross-cutting concerns
   - All tasks must follow the strict checklist format (see Task Generation Rules below)
   - Clear file paths for each task
   - Dependencies section showing story completion order
   - Parallel execution examples per story
   - Implementation strategy section (MVP first, incremental delivery)

## Completion Report

Output path to generated tasks.md and summary:
- Total task count
- Task count per user story
- Parallel opportunities identified
- Independent test criteria for each story
- Suggested MVP scope (typically just User Story 1)
- Format validation: Confirm ALL tasks follow the checklist format (checkbox, ID, labels, file paths)

Context for task generation: $ARGUMENTS

The tasks.md should be immediately executable - each task must be specific enough that an LLM can complete it without additional context.

## Task Generation Rules

**CRITICAL**: Tasks MUST be organized by user story to enable independent implementation and testing.

**Tests are OPTIONAL**: Only generate test tasks if explicitly requested in the feature specification or if user requests TDD approach.

### Checklist Format (REQUIRED)

Every task MUST strictly follow this format:

```text
- [ ] [TaskID] [P?] [Story?] Description with file path
```

**Format Components**:

1. **Checkbox**: ALWAYS start with `- [ ]` (markdown checkbox)
2. **Task ID**: Sequential number (T001, T002, T003...) in execution order
3. **[P] marker**: Include ONLY if task is parallelizable (different files, no dependencies on incomplete tasks)
4. **[Story] label**: REQUIRED for user story phase tasks only
   - Format: [US1], [US2], [US3], etc. (maps to user stories from spec.md)
   - Setup phase: NO story label
   - Foundational phase: NO story label
   - User Story phases: MUST have story label
   - Polish phase: NO story label
5. **Description**: Clear action with exact file path

**Examples**:

- ✅ CORRECT: `- [ ] T001 Add feature flag config in .env.example`
- ✅ CORRECT: `- [ ] T005 [P] Implement authentication middleware in src/middleware/auth.py`
- ✅ CORRECT: `- [ ] T012 [P] [US1] Add rule-list table component in src/components/RuleList.tsx`
- ❌ WRONG: `T001 [US1] Create model` (missing checkbox)
- ❌ WRONG: `- [ ] [US1] Create User model` (missing Task ID)
- ❌ WRONG: `- [ ] T001 [US1] Create model` (missing file path)

### Multi-deployable repos (optional — enable only when the repo has more than one deployable)

This seed defaults to a **single-deployable repo**: one toolchain, one test command, no
per-task deployable tag. Most repos are this. **Skip this whole subsection unless plan.md's
project structure describes two or more independently built/tested deployables** (e.g. a
monorepo with `web/` + an API service, each with its own install and test command).

When the repo *is* multi-deployable, extend the checklist format with a leading `[Deploy]`
tag so each task names where it lands and a session can install one toolchain and work a
contiguous block:

```text
- [ ] [TaskID] [Deploy] [P?] [Story?] Description with file path
```

1. Derive the deployable tags and their test commands from plan.md's project structure —
   one short tag per deployable (e.g. `[web]`, `[api]`) plus `[repo]` for cross-cutting work
   (touching more than one deployable, or repo-root config). Do **not** hardcode tags from
   another project; read them from *this* repo's plan.
2. Put a `[Deploy]` tag on **every** task, exactly one per task.
3. Within each phase, after ordering by dependency, **group tasks by deployable** into
   contiguous blocks so a session sets up one toolchain and works the whole block before
   switching. Introduce each block with a sub-heading naming the deployable and its test
   command, e.g.:

   ```text
   #### [api] — cd api && pytest
   - [ ] T005 [api] ...
   - [ ] T006 [api] [P] ...

   #### [web] — cd web && npm run test
   - [ ] T007 [web] ...
   ```

4. `[repo]` cross-cutting tasks that block others go in their own block at the start of the
   phase; purely incidental `[repo]` tasks go at the end. Dependency order always wins —
   never break a hard dependency just to keep a deployable block contiguous.

If you enable deployable tags, add the matching tag legend/table to the target repo's
`CLAUDE.md` SDD section so the convention is documented alongside the code.

### Task Organization

1. **From User Stories (spec.md)** - PRIMARY ORGANIZATION:
   - Each user story (P1, P2, P3...) gets its own phase
   - Map all related components to their story:
     - Models needed for that story
     - Services needed for that story
     - Interfaces/UI needed for that story
     - If tests requested: Tests specific to that story
   - Mark story dependencies (most stories should be independent)

2. **From Contracts**:
   - Map each interface contract → to the user story it serves
   - If tests requested: Each interface contract → contract test task [P] before implementation in that story's phase

3. **From Data Model**:
   - Map each entity to the user story(ies) that need it
   - If entity serves multiple stories: Put in earliest story or Setup phase
   - Relationships → service layer tasks in appropriate story phase

4. **From Setup/Infrastructure**:
   - Shared infrastructure → Setup phase (Phase 1)
   - Foundational/blocking tasks → Foundational phase (Phase 2)
   - Story-specific setup → within that story's phase

### Phase Structure

- **Phase 1**: Setup (project initialization)
- **Phase 2**: Foundational (blocking prerequisites - MUST complete before user stories)
- **Phase 3+**: User Stories in priority order (P1, P2, P3...)
  - Within each story: Tests (if requested) → Models → Services → Endpoints → Integration
  - Each phase should be a complete, independently testable increment
- **Final Phase**: Polish & Cross-Cutting Concerns

## Done When

- [ ] tasks.md generated with all phases, task IDs, and file paths
- [ ] Completion reported to user with task count, story breakdown, and MVP scope
