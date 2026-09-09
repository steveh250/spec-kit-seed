# spec-kit-seed

A standalone, reusable seed that installs [github/spec-kit](https://github.com/github/spec-kit)
Spec-Driven Development (SDD) — as Claude Code skills, adapted for cloud sessions — into a
fresh repository. Start every new project from this seed to get the same SDD workflow each
time.

The seed is **self-contained**: nothing in it connects to, or depends on, any other
repository at runtime. Everything below is doable from the **GitHub web UI and Claude Code on
the web — no terminal required**.

## What you get

- **9 SDD phase skills** in `.claude/skills/speckit-*/` — constitution → specify → clarify →
  plan → tasks → analyze → checklist → implement → converge.
- **`.specify/`** — the scripts, templates, an unfilled constitution, and the pinned upstream
  baseline the skills rely on.
- **`CLAUDE.snippet.md`** — the SDD routing section to drop into a project's `CLAUDE.md`.
- **`INSTALL.md`** — the full install + upgrade reference.

Single-deployable by default; multi-deployable (monorepo) task tagging is an opt-in.

Branch-model agnostic: features are identified by `specs/features/<NNN-…>/` and
`.specify/feature.json`, never by a git branch, so it works with per-feature branches **or**
with a fixed `development` / `hotfix` / `main` layout that has no feature branches at all (see
["Working without feature branches"](USAGE.md#working-without-feature-branches-eg-development--hotfix--main)
in `USAGE.md`). Works from Claude Code on the web or the desktop client.

## Initialise a new project from this seed

**One time — turn this into a template repo:** in this repo's **Settings**, tick **Template
repository**. (Step 0 in [`INSTALL.md`](INSTALL.md) covers creating the seed repo itself.)

**Each new project:**

1. Click **Use this template → Create a new repository** on this repo's GitHub page, and name
   your new project. GitHub creates it as an independent copy of the seed — no link back.
2. Connect that new repo to Claude Code on the web and open a session on it.
3. **Paste this one prompt** to Claude:

   > This repo was created from a spec-kit seed template. Finalize the install: merge the two
   > sections of `CLAUDE.snippet.md` into `CLAUDE.md` (create `CLAUDE.md` if absent) and fill
   > every `<FILL IN>` placeholder — build/test/lint/run commands from this repo's real
   > tooling, and the branch model from its existing branches (say so if there are no feature
   > branches); then delete `INSTALL.md` and `CLAUDE.snippet.md` (they are seed tooling, not
   > project files).
   > Run `bash .specify/scripts/bash/preflight.sh` to verify, then commit and push to the
   > current branch.

   Claude does the rest and reports the preflight result plus the commit it pushed. No terminal
   at any point.

Not using template repos? [`INSTALL.md`](INSTALL.md) has an alternative where Claude copies the
seed in from your own seed repo, plus an optional local-terminal path.

## Then: run the SDD workflow

One phase per session, each invoked by skill name — just ask Claude (e.g. *"Use the
speckit-constitution skill to draft our principles"*):

`speckit-constitution` → `speckit-specify` → `speckit-clarify` (if needed) → `speckit-plan` →
`speckit-tasks` → `speckit-analyze` / `speckit-checklist` (optional) → `speckit-implement` →
`speckit-converge`.

The constitution ships as an unfilled template; `speckit-constitution` fills it, and the plan/
tasks/implement gates stay locked until it is.

**Step-by-step walkthrough — generating the constitution and building a feature with concrete
example prompts for each phase:** [`USAGE.md`](USAGE.md).

## More detail

- **Day-to-day workflow (constitution → feature), phase by phase:** [`USAGE.md`](USAGE.md)
- **Full install, alternatives, and upgrades:** [`INSTALL.md`](INSTALL.md)
- **Provenance, upstream pin, and deviations:** [`.specify/README.md`](.specify/README.md)

## License & credits

Licensed under the [MIT License](LICENSE).

## Some Notes
* Setup branch protetion (be careful enabling approvals when you are getting started)
* Move the default branch from main to, say, development (also helps protect development from deletion)

Built on [github/spec-kit](https://github.com/github/spec-kit) (MIT, © GitHub, Inc.), pinned
to release **v0.15.1** and adapted into Claude Code skills for cloud sessions. The upstream
copyright is preserved in [`LICENSE`](LICENSE); what was taken verbatim vs. adapted, and why,
is documented in [`.specify/README.md`](.specify/README.md).
