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
- Release tag: **v0.15.1**

## Installed verbatim (unmodified from upstream)

- `.specify/templates/{spec,plan,tasks,checklist,constitution}-template.md`
- `.specify/memory/constitution.md` — a copy of `constitution-template.md`, unfilled
  (fill it with the `speckit-constitution` skill)
- `.specify/scripts/bash/common.sh` — feature/path resolution
- `.specify/scripts/bash/check-prerequisites.sh` — prerequisite validation

## Authored for the seed (repo-agnostic)

- `.specify/scripts/bash/preflight.sh` — prints the active feature, which artifacts exist,
  and the next valid phase; read-only, never writes `feature.json`, never touches git.
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
   plan.md; analyze/implement/converge require plan.md + tasks.md; etc.). Upstream relied
   on the invoking command's `scripts:` frontmatter alone.

3. **No branching / no git extension.** Cloud sessions can only push to the current branch,
   so nothing here creates or switches branches. spec-kit's separate *git extension* and
   `create-new-feature.sh` were **not** installed. The active feature resolves solely from
   `.specify/feature.json` (`feature_directory` key), overridable via
   `SPECIFY_FEATURE_DIRECTORY` — never from a git branch name. The `before_specify`
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
   nested path correctly from `.specify/feature.json` — they read the directory value and
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

## Upstream baseline (for upgrades)

The unmodified upstream sources this install was adapted from are stored under
`.specify/upstream/v0.15.1/`:

- `commands/` — all ten `templates/commands/*.md` prompt bodies (the nine adapted into
  skills, plus `taskstoissues.md` which has no skill), verbatim.
- `templates/` — the five `*-template.md` files, verbatim.

**How to upgrade to a newer spec-kit release (e.g. vX):** fetch the new upstream
`commands/` and `templates/` into `.specify/upstream/vX/`, then **diff `upstream/vX`
against `upstream/v0.15.1`** to see exactly what upstream changed. Re-apply the deviations
recorded above to those changed sections and regenerate the adapted
`.claude/skills/speckit-*/SKILL.md`. Do **not** diff a new upstream release directly
against the adapted skills — the adaptations would swamp the real upstream delta and hide
it. The upstream-vs-upstream diff is the signal; the recorded deviations are the patch.

## Re-running / updating

All skill install steps are idempotent (existing files are not overwritten). After any
refresh, re-verify no `git checkout -b` / `git switch -c` / `git branch` commands were
introduced and that no skill hardcodes a bare `specs/<NNN` feature path (feature artifacts
live under `specs/features/`).
