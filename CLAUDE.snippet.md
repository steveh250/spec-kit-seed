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
a Preflight that resolves the feature and **hard-stops** if its prerequisite artifact
is missing. Name the feature in the request (e.g. "speckit-plan for feature 002"); with
none named, the skill uses the only feature, or lists them and asks.

**Task tagging:** every task in `tasks.md` carries a Task ID, an optional `[P]`
(parallelizable) marker, a `[US#]` story label in user-story phases, and an exact file path.
<!-- FILL IN (multi-deployable repos only): if this repo has more than one deployable,
     also require a [deploy] tag on every task naming which deployable it lands in
     (e.g. [web], [api], [repo] for cross-cutting), and group tasks by deployable into
     contiguous blocks within each phase. List the tags and each one's test command here.
     Single-deployable repos: delete this note — no deploy tag is used. -->

**Where artifacts live / how the feature resolves:**
- Feature artifacts: `specs/features/<NNN-short-name>/` (spec.md, plan.md, tasks.md, …).
- Templates: `.specify/templates/`. Constitution: `.specify/memory/constitution.md`.
- Scripts: `.specify/scripts/bash/` — run `bash .specify/scripts/bash/preflight.sh` to see
  every feature and its next valid phase (`preflight.sh 002` for one feature in detail).
- The feature resolves from the request (`002`, `002-short-name`, or its path), then
  `SPECIFY_FEATURE_DIRECTORY`, then the feature this conversation already created, then "the
  only feature in `specs/features/`". **Never** from the git branch name, and never from
  `.specify/feature.json`. The skills don't use that file; if one exists it is a stale,
  git-ignored leftover, so never commit it. Scripts run with
  `SPECIFY_FEATURE_DIRECTORY=<dir> SPECIFY_FEATURE_NO_PERSIST=1` so parallel sessions on
  different features never collide.
- The constitution's Sync Impact Report is review material only: it goes in the amendment's
  commit message, never in the committed `.specify/memory/constitution.md`.

**Hard gates (do not bypass):**
- No implementation code without both `plan.md` and `tasks.md` for the feature.
- No unresolved `[NEEDS CLARIFICATION]` markers may enter the plan phase — run
  `speckit-clarify` (or resolve them) first.
- Any behaviour change updates `spec.md` (and, if affected, `plan.md`/`tasks.md`) **before** code.
- Constitution principles are non-negotiable; conflicts are resolved by changing the
  spec/plan/tasks, or by an explicit constitution amendment — never by silently ignoring them.

**Branch & session rules:**
- Work on the **current git branch only**. Never `git checkout -b`, `git switch -c`, or
  `git branch` — a cloud session can only push to the current branch, and on the desktop
  client the user checks out the intended branch before the session starts.
- Branch model: `<FILL IN>`
  <!-- FILL IN: state the repo's branches and where SDD work lands. Feature-branch repos:
       e.g. "one feature branch per feature, PR into main". No-feature-branch repos:
       e.g. "long-lived development / hotfix / main only; all SDD phases (specs, plans,
       tasks, code) run on development, which is promoted to main; hotfix carries urgent
       fixes and is merged back into development. No per-feature branches are ever
       created." Features are identified by specs/features/<NNN-short-name>/,
       never by a branch, so either model works unchanged. -->
- Commit artifacts as they are produced (spec, plan, tasks, code).
- One phase per session; hand off to the next phase in a fresh session.

**Shared artifacts (files more than one feature changes):**
Everything under `specs/features/<NNN-…>/` belongs to one feature. Any other document or
record that several features update is shared. Sessions working on different features in
parallel would otherwise conflict on it or overwrite each other's entries. Every shared
artifact is listed here with the one way it is changed, and sessions follow that rule. A
session that has to change an unlisted one appends only, tags the entry with its feature
id, and flags the file in its report so a row gets added here. Source code is not covered:
code conflicts between features are ordinary merges.

| File | How it is changed |
|------|-------------------|
| `.specify/memory/constitution.md` | Only via `speckit-constitution`, one session at a time, on the integration branch |
| `CLAUDE.md` | One session at a time, on the integration branch |
| `<FILL IN>` | `<FILL IN>` |

<!-- FILL IN: add a row for every other file several features update, e.g. DECISIONS.md,
     CHANGELOG.md, README.md, the docs/ set the constitution requires (ARCHITECTURE, FR,
     NFR, TEST-CASES, SCHEMA…), a migrations index. Give each exactly one rule:
     - Append-only, keyed by feature: add entries/rows tagged with the feature id (e.g.
       "[004]"); never edit, renumber or reorder another feature's entries, so a merge
       conflict is always "keep both". Suits documents the constitution says every change
       must update (e.g. FR / NFR / TEST-CASES rows).
     - Feature-local first: the feature records it in its own directory (decisions in
       research.md); only cross-cutting items are copied here, one session at a time.
     - One file per entry: e.g. docs/decisions/NNNN-title.md instead of one log, so new
       entries never touch the same file.
     - Serialized: edited by one session at a time on the integration branch (e.g. after
       the feature merges). Don't choose this for a file every change must update.
     Delete the placeholder row if the repo has no other shared artifacts. -->
