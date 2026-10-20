# .specify — Spec-Driven Development install provenance

This directory and `.claude/skills/speckit-*/` implement the
[github/spec-kit](https://github.com/github/spec-kit) methodology as Claude Code skills,
adapted for Claude Code **cloud sessions**. It was deployed from a portable **spec-kit
seed** (see the seed's `INSTALL.md`) rather than installed per-repo from upstream.

## Path taken

**Upstream fetch + adapt.** The seed's artifacts were fetched file-by-file from the pinned
upstream release tag and adapted — **not** reconstructed from memory. The pristine upstream
sources are preserved under `.specify/upstream/<tag>/` for diffing on upgrade.

- Upstream: `github/spec-kit`
- Release tag: **v1.2.2** (refreshed from v0.15.1 — see "Changes in the v1.2.2 refresh" below)

## Installed verbatim (unmodified from upstream)

- `.specify/templates/{spec,plan,tasks,checklist,constitution}-template.md`
- `.specify/memory/constitution.md` — a copy of `constitution-template.md`, unfilled
  (fill it with the `speckit-constitution` skill)
- `.specify/scripts/bash/common.sh` — feature/path resolution
- `.specify/scripts/bash/check-prerequisites.sh` — prerequisite validation

## Authored for the seed (repo-agnostic)

- `.specify/scripts/bash/preflight.sh` — prints constitution status and every feature under
  `specs/features/` with its next valid phase (`preflight.sh <feature>` for one feature's
  artifacts); read-only, never reads or writes `feature.json`, never touches git. It flags
  feature numbers used by two directories and a leftover `feature.json`.
- `.specify/.gitignore` — ignores `feature.json`, mirroring the managed `.specify/.gitignore`
  upstream's `specify init` writes, so a pointer written by a hand-run script or left over from
  an older install can never be committed.
- `.specify/integration.json` — a minimal stand-in for the file `specify init` writes; it only
  sets `invoke_separator: "-"` so script error messages name skills as `/speckit-plan` rather
  than upstream's default `/speckit.plan`.
- `.specify/templates/constitution-sample.md` — a pre-filled constitution baseline (the
  owner's recurring principles, with `[ALL_CAPS]` tokens for project-specific values).
  `speckit-constitution` starts from it when present. Not an upstream file.
- `.claude/skills/speckit-*/SKILL.md` (9 skills) — generated from the upstream
  `templates/commands/*.md` prompts (see deviations below).
- The `## Spec-Driven Development (SDD)` section pasted into this repo's root `CLAUDE.md`.

## Deviations from upstream (and why)

1. **Skills mode, not slash-command prompts.** Each upstream `templates/commands/<x>.md`
   became `.claude/skills/speckit-<x>/SKILL.md` with `name` + a selection-specific
   `description` in frontmatter, so the right phase can be chosen autonomously from a
   natural-language request.

2. **Preflight hard-stops.** Every skill opens with a Preflight block that resolves the
   active feature and stops with an actionable message if its prerequisite artifact is
   missing (plan requires spec.md and no unresolved `[NEEDS CLARIFICATION]`; tasks require
   plan.md; implement requires plan.md + tasks.md; analyze/converge also require spec.md,
   matching upstream's `--require-spec` since v1.0.3; etc.). Upstream relied
   on the invoking command's `scripts:` frontmatter alone.

3. **No branching / no git extension.** Cloud sessions can only push to the current branch,
   so nothing here creates or switches branches. spec-kit's separate *git extension* and
   `create-new-feature.sh` were **not** installed. The feature resolves from the user's
   request (see deviation 11) — never from a git branch name. The `before_specify`
   branch-creation hook language and all branch prose in the specify prompt were removed and
   replaced with an explicit "stay on the current branch" policy. The installed core scripts
   (`common.sh`, `check-prerequisites.sh`) are already branch-free upstream at this tag.
   A consequence worth stating: the workflow is **branch-model agnostic**. It runs unchanged
   in repos that have no feature branches at all (e.g. only `development` / `hotfix` / `main`)
   — all phases execute on whichever long-lived branch is checked out, and multiple features
   coexist there as separate `specs/features/<NNN-…>/` directories. Where a template prints a
   `Branch` field, `common.sh` falls back to the feature directory basename as the identifier.
   The skills' "cloud session" preamble applies verbatim on the desktop client too; the only
   difference is that the user, not the platform, chooses the branch before the session starts.

4. **Scripts scoped to path resolution + prerequisite checks only.** `setup-plan.sh` and
   `setup-tasks.sh` were **not** installed; the `speckit-plan` and `speckit-tasks` skills
   instead seed their template inline (`cp .specify/templates/<x>-template.md …`, never
   overwriting an existing file). Powershell scripts were not installed.

5. **Extension-hook + preset machinery removed.** The `## Pre-Execution Checks` /
   `## (Mandatory) Post-Execution Checks/Hooks` sections referencing `.specify/extensions.yml`
   were stripped from every skill (self-disabling machinery we do not install). The single
   preset/template-resolution reference was replaced with a direct `.specify/templates/` path.

6. **Placeholder normalization.** `__SPECKIT_COMMAND_<X>__` → `speckit-<x>`; `{SCRIPT}` → the
   concrete `check-prerequisites.sh` invocation; `/memory/constitution.md` →
   `.specify/memory/constitution.md`.

7. **Feature artifacts namespaced under `specs/features/`.** Feature artifacts install under
   `specs/features/<NNN-short-name>/` so they never interleave with any pre-existing design
   docs at the top level of `specs/`. (`common.sh` / `check-prerequisites.sh` resolve the
   nested path correctly from `SPECIFY_FEATURE_DIRECTORY` — they read the directory value and
   never assume `specs/` depth.)

8. **Explicit sequential numbering in `speckit-specify`.** Because `create-new-feature.sh`
   was not installed, the specify skill states the rule directly: scan `specs/features/` for
   directories matching `^[0-9]{3}-`, take the highest, increment, zero-pad to three digits;
   start at `001` if none match; ignore non-conformant names and **never** renumber or rename
   pre-existing directories.

9. **Constitution gate.** `speckit-plan`, `speckit-tasks`, and `speckit-implement` hard-stop
   if `.specify/memory/constitution.md` is still the unfilled template (bracketed
   placeholders, the template's `<!-- Example: -->` guidance, or `TODO` markers).
   `preflight.sh` surfaces constitution status as `missing` / `still-template` / `filled`.
   This prevents a "clean" Constitution Check reconciled against placeholder headings.

10. **Deployable tagging is opt-in, not baked in.** The seed defaults to a
    **single-deployable repo**: `speckit-tasks` requires only Task ID + `[P?]` + `[US#?]` +
    file path. Multi-deployable (monorepo) `[deploy]` tagging and per-deployable grouping is
    documented in `speckit-tasks` as an explicit opt-in to enable when this repo's `plan.md`
    describes two or more deployables. (An earlier monorepo install hardcoded per-deployable
    tags; the seed generalizes that to opt-in.)

11. **The feature is named per request; there is no `feature.json` pointer.** Upstream keeps
    a single `.specify/feature.json` pointer (written by `speckit.specify`, git-ignored by
    `specify init`) and, since v1.0.11, offers `SPECIFY_FEATURE_DIRECTORY` +
    `SPECIFY_FEATURE_NO_PERSIST` for concurrent agents. Several problems follow from it:
    - A cloud session is a fresh clone, so a git-ignored pointer doesn't survive between
      phases.
    - A committed pointer makes parallel sessions on different features collide.
    - In a checkout shared by local agents, one agent's pointer silently becomes every other
      agent's feature.
    The seed therefore never writes or reads it. Every skill's preamble resolves the feature
    in this order: the feature named in the user's request (`002`, `002-name`, or a path) →
    `SPECIFY_FEATURE_DIRECTORY` → the feature this conversation already created or resolved →
    the only directory in `specs/features/` → stop and ask. Every script call is pinned with
    `SPECIFY_FEATURE_DIRECTORY=<dir> SPECIFY_FEATURE_NO_PERSIST=1`, so upstream's scripts
    neither read nor write the pointer either. `speckit-specify` fetches every remote branch
    and numbers above the highest `NNN-` it finds on any local or remote branch, then re-checks the number
    before each commit and push, renaming its own not-yet-pushed directory if the number has
    been taken. `preflight.sh` flags any number still used twice.

12. **The Sync Impact Report never stays in the committed constitution.** Upstream v1.2.2
    calls the report "temporary scratch material… expected to be removed before the amended
    constitution file is committed" but says neither who removes it nor where durable items
    (deferred setup, `TODO`s) go. `speckit-constitution` makes both explicit:
    - Durable items move into the constitution body (the sample's *Deferred Setup* section,
      inline `TODO(<FIELD>)` markers).
    - The report comment is then deleted and its text becomes the commit message body.
    - A report left over from an earlier amendment is migrated and removed the same way.
    `constitution-sample.md` no longer ships a report, and its Governance section says the
    same.

13. **Shared artifacts are declared, not guessed.** Upstream says nothing about files that
    several features change (decision logs, `docs/`, changelogs, `CLAUDE.md`). Under
    parallel work they are where features conflict or overwrite each other. The CLAUDE.md
    snippet adds a *Shared artifacts* table giving each such file one rule: append-only
    keyed by feature id, feature-local first, one file per entry, or serialized.
    `constitution-sample.md` requires the table. `speckit-plan`, `speckit-tasks` and
    `speckit-implement` follow it. They append only, tagged with the feature id, to a
    shared file it doesn't list, and flag that file in their report. The upgrade prompt in
    the seed's `INSTALL.md` takes an inventory of an existing project's shared files and
    proposes rules for approval.

## Upstream baseline (for upgrades)

The unmodified upstream sources this install was adapted from are stored under
`.specify/upstream/v1.2.2/`:

- `commands/` — all ten `templates/commands/*.md` prompt bodies (the nine adapted into
  skills, plus `taskstoissues.md` which has no skill), verbatim.
- `templates/` — the five `*-template.md` files, verbatim.

**How to upgrade to a newer spec-kit release (e.g. vX):** fetch the new upstream
`commands/` and `templates/` into `.specify/upstream/vX/`, then **diff `upstream/vX`
against `upstream/v1.2.2`** to see exactly what upstream changed. Re-apply the deviations
recorded above to those changed sections and regenerate the adapted
`.claude/skills/speckit-*/SKILL.md`. Do **not** diff a new upstream release directly
against the adapted skills — the adaptations would swamp the real upstream delta and hide
it. The upstream-vs-upstream diff is the signal; the recorded deviations are the patch.

## Changes in the v1.2.2 refresh (from v0.15.1)

Upstream moved 563 commits between these tags; nearly all of it is in machinery the seed
does not install (the Python `specify` CLI, agent integrations, presets, extension/bundle
catalogs, the workflow engine, the MCP server). What reached the seed:

- **Checklists are reviewer-owned** (`speckit-checklist`, `checklist-template.md`): `[x]` on
  a custom checklist means a reviewer judged that requirement well-written, not that work is
  done; the skill never pre-checks items. `speckit-implement` reads checklists as a
  read-only gate (Checked / Unchecked) and never edits them.
- **Converge distrusts checkboxes:** every task is reassessed regardless of `[x]` —
  "completion claims are not evidence" — and code that exceeds or contradicts intent is
  flagged too. Expect the first converge after upgrading to find previously "done" gaps.
- **Tasks quote data-model constraints** (max length, nullability, enums, validation)
  verbatim.
- **Clarify defers less:** only questions about implementation method, stack choice, or task
  breakdown are deferred to planning.
- **analyze / converge require spec.md**; `check-prerequisites.sh` gains `--require-spec`
  and `--template NAME`, and rejects an empty `plan.md`.
- **Constitution:** the Sync Impact Report is temporary review material, removed before the
  amendment is committed; the skill writes only `.specify/memory/constitution.md`.
- `plan` reads `FEATURE_DIR` (was `SPECS_DIR`); `common.sh` adds UTF-8 `feature.json`
  reads, `SPECKIT_PYTHON` override, and preset/extension template resolution (inert here —
  no `.specify/presets/` or `.specify/extensions/`).
- Not adopted: upstream's `resolve-template.sh` (constitution template via presets — the
  seed's `constitution-sample.md` flow is kept), the deprecated `taskstoissues`, and the
  optional `bug` / `assess` extensions.
- Seed-side changes made at the same time: deviation 11 (feature named per request, no
  `feature.json` pointer, numbering across all remote branches, duplicate-number warning) and
  deviation 12 (Sync Impact Report kept out of the committed constitution; the sample's
  deferred-setup list moved into its body and the `feature.json` governance rule replaced).
  Deviation 13 (shared-artifacts table) followed in a later seed change.
- **Projects upgrading from v0.15.1:** a constitution adopted from the older sample still says
  the feature resolves from `.specify/feature.json`, and may carry a committed Sync Impact
  Report. The upgrade prompt in the seed's `INSTALL.md` checks for both and proposes an
  amendment; see its rollout steps when features are in flight.

## Re-running / updating

All skill install steps are idempotent (existing files are not overwritten). After any
refresh, re-verify no `git checkout -b` / `git switch -c` / `git branch` commands were
introduced and that no skill hardcodes a bare `specs/<NNN` feature path (feature artifacts
live under `specs/features/`).
