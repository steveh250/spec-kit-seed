# spec-kit-seed — portable Spec-Driven Development kit

A standalone seed that installs the [github/spec-kit](https://github.com/github/spec-kit)
methodology (adapted for Claude Code cloud sessions) into a fresh repository. This seed is
**self-contained**: its contents have no runtime connection to, or dependency on, any other
repository. You create your own seed repo from these files once, then start each new project
from it.

**Everything here can be done from the GitHub web UI and Claude Code on the web — no terminal
or command prompt required.**

## What's in the seed

When these files are their own repository, they sit at the **repo root**:

```
INSTALL.md                     ← this file (seed tooling — delete it from each seeded project)
CLAUDE.snippet.md              ← source text to merge into the target repo's CLAUDE.md, then delete
.claude/
└── skills/speckit-*/SKILL.md  ← 9 SDD phase skills
.specify/
├── README.md                  ← provenance + upgrade guide (keep — it travels into each project)
├── feature.json               ← reset to no active feature
├── memory/constitution.md     ← unfilled template — filled per project
├── scripts/bash/*.sh          ← preflight / prerequisite / path resolution
├── templates/*.md             ← the five spec-kit templates
└── upstream/v0.15.1/          ← pristine upstream baseline, for upgrades
```

Single-deployable by default. Multi-deployable (monorepo) task tagging is an opt-in
documented inside `speckit-tasks` and the CLAUDE.md snippet.

---

## Step 0 (once): create your standalone seed repo

Create a new GitHub repository from these files — from the GitHub web UI:

1. Create an empty repo (e.g. `spec-kit-seed`).
2. Add these files to it so they sit at the repo root (GitHub's **Add file → Upload files**
   lets you drag the whole folder in from your browser — no terminal needed), then commit.
3. In the repo's **Settings**, tick **Template repository**. This is what makes the one-click
   install below work.

That seed repo is now completely independent. Nothing in it points back at where it came from.

---

## Install into a new project (recommended: "Use this template")

No terminal, no cross-repo connection — GitHub creates the new project as an independent copy
of the seed:

1. On the seed repo's GitHub page, click **Use this template → Create a new repository**, and
   name your new project. GitHub creates it with the seed's contents as its initial commit
   (an independent repo, not a fork — no ongoing link to the seed).
2. Connect that new repo to Claude Code on the web and open a session on it.
3. Paste this prompt to Claude:

   > This repo was created from a spec-kit seed template. Finalize the install: merge the two
   > sections of `CLAUDE.snippet.md` into `CLAUDE.md` (create `CLAUDE.md` if absent) and fill
   > every `<FILL IN>` placeholder from this repo's real install/test/lint/run commands; then
   > delete `INSTALL.md` and `CLAUDE.snippet.md` (they are seed tooling, not project files).
   > Run `bash .specify/scripts/bash/preflight.sh` to verify, then commit and push to the
   > current branch.

4. Claude reports the preflight output and the commit it pushed. Done — no terminal at any
   point.

## Alternative: let Claude copy the seed in (if you don't use template repos)

Also fully web-based. This connects the new project's session to your **seed repo** (never to
any other project):

1. Open a Claude Code web session on the new project repo.
2. Paste this prompt, substituting your seed repo's `owner/name`:

   > Install the spec-kit seed into this repository. The seed is the GitHub repo
   > **`<owner>/spec-kit-seed`**, with its files at the repo root. Add that seed repo to the
   > session so you can read it, copy `.claude/` and `.specify/` in verbatim, merge the
   > `CLAUDE.snippet.md` sections into `CLAUDE.md` and fill the `<FILL IN>` placeholders from
   > this repo's real tooling, run `bash .specify/scripts/bash/preflight.sh` to verify, then
   > commit and push to the current branch. Do not copy `INSTALL.md` or `CLAUDE.snippet.md`
   > into this repo.

If your web environment's network policy blocks adding the seed repo, tell Claude to read the
seed's files individually from GitHub instead — the manifest above is the file list.

### What Claude does (either path), for reference

These run **inside the web session**, executed by Claude — not steps you type:

1. Ensure `.claude/skills/speckit-*/` and `.specify/` are present at the repo root (already
   there with the template path; copied in on the alternative path). Never overwrite an
   existing `.specify/memory/constitution.md` or `.specify/feature.json` if the repo already
   has spec-kit.
2. Wire up CLAUDE.md from `CLAUDE.snippet.md`'s two sections (`## Build, test & lint` and
   `## Spec-Driven Development (SDD)`): create or merge, don't duplicate an existing build/test
   section, fill every `<FILL IN>` from the repo's real commands, and delete the snippet's
   leading HTML comment and any multi-deployable note that doesn't apply.
3. Delete `INSTALL.md` and `CLAUDE.snippet.md`.
4. Verify with `bash .specify/scripts/bash/preflight.sh` — expect `Constitution:
   still-template`, `Active feature: (none resolved)`, `Next valid phase: speckit-constitution
   … then speckit-specify`.
5. Commit and push to the current branch (cloud sessions only push to the current branch;
   never create or switch branches).

---

## First session after installing

Run the phases in order, **one phase per session**, each invoked by skill name — you do this
by asking Claude (e.g. "Use the speckit-constitution skill to draft our principles"):

`speckit-constitution` → `speckit-specify` → `speckit-clarify` (if needed) → `speckit-plan` →
`speckit-tasks` → `speckit-analyze` / `speckit-checklist` (optional) → `speckit-implement` →
`speckit-converge`.

The constitution starts as an unfilled template; `speckit-constitution` fills it, and the hard
gates in `speckit-plan` / `speckit-tasks` / `speckit-implement` stay locked until it is filled.

## Design notes

- **Single-deployable by default.** `speckit-tasks` requires only Task ID + `[P?]` + `[US#?]`
  + file path. Multi-deployable (monorepo) `[deploy]` tagging and per-deployable grouping is an
  opt-in documented inside `speckit-tasks`, enabled when a project's `plan.md` describes two or
  more deployables.
- **`speckit-constitution`** inspects whatever tooling the target repo actually has before
  proposing a code-quality principle, rather than assuming any stack.
- **CLAUDE.md** ships as a snippet with `<FILL IN>` placeholders, so each project states its
  own layout and build/test commands.
- The constitution ships as an **unfilled template** and `feature.json` as
  `{"feature_directory": ""}` (no active feature), so every seeded project starts clean.

## Upgrading spec-kit later

Also done by asking Claude in a web session — no terminal. See the "Upstream baseline (for
upgrades)" section in `.specify/README.md`: fetch the new upstream into `.specify/upstream/vX/`,
diff it against `upstream/v0.15.1`, re-apply the recorded deviations to the changed sections,
and regenerate the skills.

---

## Appendix: installing from a local terminal (optional)

If you *do* have a shell with the seed repo checked out alongside the target repo, the copy is:

```bash
TARGET=/path/to/new-project
cp -R .claude   "$TARGET/"      # from the seed repo root
cp -R .specify  "$TARGET/"
# then merge CLAUDE.snippet.md into the target's CLAUDE.md, fill the <FILL IN> bits,
# and delete INSTALL.md + CLAUDE.snippet.md from the target.
```
