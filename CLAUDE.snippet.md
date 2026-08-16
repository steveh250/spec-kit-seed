<!--
  CLAUDE.md snippet — Spec-Driven Development routing.

  This is NOT a standalone CLAUDE.md. Paste the two sections below into the
  target repo's CLAUDE.md (create one if it has none), then fill the <FILL IN>
  placeholders with that repo's real layout and commands. Delete this comment
  block when you paste.

  Everything below the line is meant for the target repo's CLAUDE.md verbatim
  (after filling placeholders).
-->

---

## Build, test & lint

<!-- FILL IN: replace with this repo's real install/test/lint/run commands.
     Single-deployable example: -->

| Task | Command |
|------|---------|
| Install | `<FILL IN>` |
| Test | `<FILL IN>` |
| Lint | `<FILL IN>` |
| Run | `<FILL IN>` |

<!-- If this repo has more than one deployable, use a row per deployable with an
     Area column instead, and mirror those area tags in the SDD "task tagging"
     note below. -->

## Spec-Driven Development (SDD)

This repo uses the [github/spec-kit](https://github.com/github/spec-kit) methodology,
installed as Claude Code **skills** and adapted for cloud sessions. Provenance and
deviations: `.specify/README.md`.

**Phase order — one skill owns each phase, one phase per session:**

1. `speckit-constitution` → `.specify/memory/constitution.md` (project principles)
2. `speckit-specify` → `specs/features/<NNN-short-name>/spec.md` (what & why; no tech)
3. `speckit-clarify` → resolves `[NEEDS CLARIFICATION]` in `spec.md`
4. `speckit-plan` → `plan.md` + `research.md`, `data-model.md`, `contracts/`, `quickstart.md`
5. `speckit-tasks` → `tasks.md` (dependency-ordered)
6. `speckit-analyze` → cross-artifact consistency report (non-destructive)
7. `speckit-checklist` → domain quality checklists (optional, repeatable)
8. `speckit-implement` → writes the code from `tasks.md`
9. `speckit-converge` → appends any unbuilt work back to `tasks.md`

Invoke a phase with its skill (e.g. "Use the speckit-plan skill…"). Each skill opens with
a Preflight that resolves the active feature and **hard-stops** if its prerequisite artifact
is missing.

**Task tagging:** every task in `tasks.md` carries a Task ID, an optional `[P]`
(parallelizable) marker, a `[US#]` story label in user-story phases, and an exact file path.
<!-- FILL IN (multi-deployable repos only): if this repo has more than one deployable,
     also require a [deploy] tag on every task naming which deployable it lands in
     (e.g. [web], [api], [repo] for cross-cutting), and group tasks by deployable into
     contiguous blocks within each phase. List the tags and each one's test command here.
     Single-deployable repos: delete this note — no deploy tag is used. -->

**Where artifacts live / how the active feature resolves:**
- Feature artifacts: `specs/features/<NNN-short-name>/` (spec.md, plan.md, tasks.md, …).
- Templates: `.specify/templates/`. Constitution: `.specify/memory/constitution.md`.
- Scripts: `.specify/scripts/bash/` — run `bash .specify/scripts/bash/preflight.sh` to see
  the active feature, existing artifacts, and the next valid phase.
- The active feature resolves from `.specify/feature.json` (`feature_directory` key),
  overridable with the `SPECIFY_FEATURE_DIRECTORY` env var. **Never** from the git branch name.

**Hard gates (do not bypass):**
- No implementation code without both `plan.md` and `tasks.md` for the feature.
- No unresolved `[NEEDS CLARIFICATION]` markers may enter the plan phase — run
  `speckit-clarify` (or resolve them) first.
- Any behaviour change updates `spec.md` (and, if affected, `plan.md`/`tasks.md`) **before** code.
- Constitution principles are non-negotiable; conflicts are resolved by changing the
  spec/plan/tasks, or by an explicit constitution amendment — never by silently ignoring them.

**Cloud-session rules:**
- Work on the **current git branch only**. Never `git checkout -b`, `git switch -c`, or
  `git branch` — a cloud session can only push to the current branch.
- Commit artifacts as they are produced (spec, plan, tasks, code).
- One phase per session; hand off to the next phase in a fresh session.
