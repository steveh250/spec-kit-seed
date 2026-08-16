# Using spec-kit — from constitution to a shipped feature

This is the hands-on guide to *driving* the Spec-Driven Development (SDD) workflow after the
seed is installed in a project. If you haven't installed it yet, do that first
([`INSTALL.md`](INSTALL.md)); if you just want the one-line quick-start, see
[`README.md`](README.md).

Everything here is done by **talking to Claude Code on the web** — you invoke a phase by asking
for its skill by name; Claude runs the scripts, writes the artifacts, and commits. No terminal.

---

## How the workflow is shaped (read this once)

- **One phase per session.** Each phase is a separate Claude Code web session. Run the phase,
  review and commit its artifact, then start a **fresh session** for the next phase. This keeps
  each phase focused and its context clean.
- **Artifacts, not memory, carry state.** Everything a later phase needs is written to files:
  the constitution, then `spec.md` → `plan.md` → `tasks.md` and their companions. A new session
  picks up exactly where the files leave off.
- **The active feature is tracked in a file,** `.specify/feature.json` — never the git branch.
  `speckit-specify` sets it when you create a feature; the other phases read it.
- **Check state any time** by asking Claude to run `bash .specify/scripts/bash/preflight.sh`.
  It prints: constitution status (`missing` / `still-template` / `filled`), the active feature,
  which artifacts exist, and **the next valid phase**. When you're unsure what to do next, run
  this.
- **Hard gates you can't skip:**
  - No `plan.md` until the constitution is *filled* (not the template) and `spec.md` has no
    unresolved `[NEEDS CLARIFICATION]` markers.
  - No `tasks.md` without `plan.md`; no implementation without both `plan.md` and `tasks.md`.
  - Any change in behaviour updates `spec.md` (and `plan.md`/`tasks.md` if affected) **before**
    the code. If a phase stops with a gate message, it's telling you which earlier phase to run.
- **Stay on the current branch.** Cloud sessions only push to the branch they're on; the skills
  never create or switch branches.

---

## Part 1 — Generate the constitution

The constitution (`.specify/memory/constitution.md`) is your project's non-negotiable
principles. It ships as an **unfilled template**, and the plan/tasks/implement phases stay
**locked** until it's filled — so this is always the first thing you do in a new project.

### 1. Start a session and invoke the skill

Open a Claude Code web session on the repo and say something like:

> Use the **speckit-constitution** skill to draft this project's constitution. It's a
> [brief description: e.g. "a TypeScript CLI that formats config files"]. Principles I care
> about: [e.g. "everything testable, no network calls in the core library, semver for the
> public API"]. Ask me about anything you need to decide.

You don't have to supply principles up front — you can just say "help me write our
constitution" and answer Claude's questions.

### 2. Answer Claude's questions

The skill will:
- Inspect the repo to see what tooling actually exists (linters, formatters, test framework),
  and **raise code-quality/tooling decisions with you** rather than silently assuming a stack —
  e.g. "there's no linter configured; should the constitution require one, or accept its absence
  for now?" Answer these; your answers get encoded (or recorded as a `TODO(...)` if deferred).
- Ask you to confirm the principle set (you can ask for more or fewer than the template's five),
  the ratification date, and anything ambiguous.

### 3. Review what it wrote

Claude fills the template and prepends a **Sync Impact Report** (version change, which
principles were added/modified, any deferred TODOs). Read the principles back — they govern
every future spec, plan, and task, so it's worth getting them right now. Ask for edits in the
same session until they read the way you want.

### 4. Commit and verify

Ask Claude to commit (it suggests a message like `docs: ratify constitution v1.0.0`) and push.
Then confirm the gate is open:

> Run the preflight script.

You want to see **`Constitution: filled`**. If it still says `still-template`, the file still
has bracketed `[PLACEHOLDERS]`, the template's `<!-- Example: -->` comments, or `TODO` markers —
ask Claude to resolve them. Once it's `filled`, you're ready to build features.

> **Amending later:** to change principles down the road, start a new session and invoke
> `speckit-constitution` again — it versions the change (MAJOR/MINOR/PATCH) and updates the
> Sync Impact Report. Principles are only ever changed deliberately, never quietly worked around.

---

## Part 2 — Build a feature the SDD way

A feature moves through phases, each producing an artifact the next one consumes. All feature
artifacts live together under `specs/features/<NNN-short-name>/` (e.g.
`specs/features/001-user-export/`), numbered sequentially and kept separate from any other docs.

The pipeline:

```
specify → clarify (if needed) → plan → tasks → [analyze] [checklist] → implement → converge
```

`[analyze]` and `[checklist]` are optional quality gates. Do one phase per session; commit each
artifact before moving on.

### Phase 1 — `speckit-specify`: what & why (no tech)

**Produces:** `specs/features/<NNN-short-name>/spec.md`, and sets `.specify/feature.json` to
make this the active feature.

Start a fresh session:

> Use the **speckit-specify** skill to write the spec for a feature: users should be able to
> export their data as a CSV from their account page. [Add whatever context you have — who it's
> for, why, any constraints.]

The spec captures **user scenarios, functional requirements, and measurable success criteria —
deliberately no implementation detail** (no frameworks, no schemas). Where something is
genuinely undecided, the skill inserts a `[NEEDS CLARIFICATION: …]` marker rather than guessing.

Review the requirements and success criteria, ask for edits, then have Claude commit and push
`spec.md`.

### Phase 2 — `speckit-clarify`: resolve the unknowns (run only if needed)

**Requires:** `spec.md`. **Updates:** `spec.md` in place.

If the spec has any `[NEEDS CLARIFICATION]` markers, the plan phase **will not run** until
they're gone. In a fresh session:

> Use the **speckit-clarify** skill to resolve the open questions in the spec.

The skill asks up to five targeted questions and writes your answers back into the spec,
removing the markers. Commit the updated `spec.md`. (If the spec had no markers, you can skip
this phase — preflight will send you straight to `plan`.)

### Phase 3 — `speckit-plan`: the technical design

**Requires:** filled constitution + `spec.md` with no unresolved markers.
**Produces:** `plan.md` plus, as relevant, `research.md`, `data-model.md`, `contracts/`, and
`quickstart.md` in the feature directory.

Fresh session:

> Use the **speckit-plan** skill to design the implementation. [State any tech constraints you
> have: language, framework, datastore, or "you choose and justify it in research.md".]

This is where technology decisions get made and recorded — the stack, the data model, interface
contracts, and a Constitution Check that reconciles the design against your principles. If the
design would violate a principle, that's surfaced here, to be resolved by changing the design
(or, deliberately, the constitution). Review `plan.md` and the companion files, then commit.

### Phase 4 — `speckit-tasks`: the work breakdown

**Requires:** `plan.md` (+ filled constitution). **Produces:** `tasks.md`.

Fresh session:

> Use the **speckit-tasks** skill to break the plan into tasks.

You get a dependency-ordered `tasks.md`, grouped by user story, where every task has an ID, an
exact file path, an optional `[P]` (parallelizable) marker, and a `[US#]` story label in the
story phases. It also proposes an MVP scope (usually just User Story 1). Review the breakdown
and commit.

> **Monorepo note:** if your project has more than one deployable, ask Claude to enable the
> optional `[deploy]` tagging documented inside `speckit-tasks`, so each task names which
> deployable it lands in and tasks are grouped by deployable. Single-deployable projects skip
> this — it's off by default.

### Phase 5 (optional) — `speckit-analyze` and `speckit-checklist`

Quality gates before you write code. Both are non-destructive.

- **`speckit-analyze`** (requires spec + plan + tasks): a cross-artifact consistency report —
  finds contradictions, duplication, ambiguities, coverage gaps, and constitution conflicts
  across the three files. Fix anything it flags in the relevant artifact's phase, then re-run.

  > Use the **speckit-analyze** skill to check the spec, plan, and tasks for consistency.

- **`speckit-checklist`** (requires plan): generates a domain-specific quality checklist — a
  "unit test for the English" of your spec (e.g. a security, API, or accessibility checklist).
  Repeatable; make as many as you want.

  > Use the **speckit-checklist** skill to create a security checklist for this feature.

### Phase 6 — `speckit-implement`: build it

**Requires:** filled constitution + `plan.md` + `tasks.md`.
**Produces:** the actual code, with tasks checked off in `tasks.md` as they're completed.

Fresh session:

> Use the **speckit-implement** skill to build the feature from tasks.md.

Claude works through `tasks.md` phase by phase, following `plan.md` and honouring the
constitution, marking each task `- [x]` as it goes. You can implement the MVP (User Story 1)
first and stop, then do later stories in their own sessions — each story is designed to be an
independently testable increment. Review the code, run the tests, and commit.

### Phase 7 — `speckit-converge`: close the gap to done

**Requires:** `plan.md` + `tasks.md`. **Updates:** `tasks.md`.

If implementation drifted from the plan, or work remains, run this to reconcile:

> Use the **speckit-converge** skill to check the code against the spec and plan and list
> what's left.

It assesses the codebase against spec/plan/tasks and **appends any remaining unbuilt work back
to `tasks.md`**, so a follow-up `speckit-implement` session can finish it. Loop implement ↔
converge until nothing new is appended.

---

## Phase quick reference

| Phase | Skill | Needs first | Produces / updates |
|-------|-------|-------------|--------------------|
| Constitution | `speckit-constitution` | — | `.specify/memory/constitution.md` |
| Specify | `speckit-specify` | filled constitution | `specs/features/<NNN>/spec.md` + `feature.json` |
| Clarify | `speckit-clarify` | `spec.md` with markers | `spec.md` (markers resolved) |
| Plan | `speckit-plan` | constitution + clean `spec.md` | `plan.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md` |
| Tasks | `speckit-tasks` | `plan.md` | `tasks.md` |
| Analyze | `speckit-analyze` | spec + plan + tasks | consistency report (no file changes) |
| Checklist | `speckit-checklist` | `plan.md` | `checklists/*.md` |
| Implement | `speckit-implement` | constitution + plan + tasks | source code; `tasks.md` checkboxes |
| Converge | `speckit-converge` | plan + tasks | appends remaining work to `tasks.md` |

## Starting a second feature

Just run `speckit-specify` again in a fresh session and describe the new feature. It scans
`specs/features/` for the highest `NNN-` directory, increments the number, creates the new
feature directory, and repoints `.specify/feature.json` at it. Each feature keeps its own spec,
plan, and tasks side by side.

## When in doubt

Run preflight — it always tells you the constitution status, the active feature, and the next
valid phase:

> Run `bash .specify/scripts/bash/preflight.sh`.
