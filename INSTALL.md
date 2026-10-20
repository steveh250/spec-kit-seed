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
├── .gitignore                 ← keeps any leftover feature.json pointer out of git
├── integration.json           ← makes script messages name skills as /speckit-<phase>
├── memory/constitution.md     ← unfilled template — filled per project
├── scripts/bash/*.sh          ← preflight / prerequisite / path resolution
├── templates/*.md             ← the five spec-kit templates
├── templates/constitution-sample.md ← pre-filled constitution baseline (reusable principles)
└── upstream/v1.2.2/           ← pristine upstream baseline, for upgrades
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
   > every `<FILL IN>` placeholder — build/test/lint/run commands from this repo's real
   > tooling, and the branch model from its existing branches (say so if there are no feature
   > branches); then delete `INSTALL.md` and `CLAUDE.snippet.md` (they are seed tooling, not
   > project files).
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
   > this repo's real tooling and existing branches, run
   > `bash .specify/scripts/bash/preflight.sh` to verify, then commit and push to the current
   > branch. Do not copy `INSTALL.md` or `CLAUDE.snippet.md` into this repo.

If your web environment's network policy blocks adding the seed repo, tell Claude to read the
seed's files individually from GitHub instead — the manifest above is the file list.

### What Claude does (either path), for reference

These run **inside the web session**, executed by Claude — not steps you type:

1. Ensure `.claude/skills/speckit-*/` and `.specify/` are present at the repo root (already
   there with the template path; copied in on the alternative path). Never overwrite an
   existing `.specify/memory/constitution.md` if the repo already has spec-kit.
2. Wire up CLAUDE.md from `CLAUDE.snippet.md`'s two sections (`## Build, test & lint` and
   `## Spec-Driven Development (SDD)`): create or merge, don't duplicate an existing build/test
   section, fill every `<FILL IN>` from the repo's real commands and its existing branches
   (the `Branch model` line — e.g. "development / hotfix / main, no feature branches; SDD work
   runs on development"), and delete the snippet's leading HTML comment and any
   multi-deployable note that doesn't apply.
3. Delete `INSTALL.md` and `CLAUDE.snippet.md`.
4. Verify with `bash .specify/scripts/bash/preflight.sh` — expect `Constitution:
   still-template`, `Active feature: (none resolved)`, `Next valid phase: speckit-constitution
   … then speckit-specify`.
5. Commit and push to the current branch (cloud sessions only push to the current branch;
   never create or switch branches). On the desktop client, check out the branch you want the
   install to land on **before** starting the session — for a `development` / `hotfix` / `main`
   repo with no feature branches that is normally `development`.

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
- The constitution ships as an **unfilled template** and there is no `feature.json` (the
  skills never write or read it; it is git-ignored in case a hand-run script creates one),
  so every seeded project starts clean.
- **`constitution-sample.md`** (in `.specify/templates/`) is a pre-filled baseline carrying
  the principles that recur across the owner's projects; only its `[ALL_CAPS]` tokens are
  project-specific. `speckit-constitution` uses it as the starting point when present, so the
  gates stay locked until those tokens are replaced. Edit the sample in the seed to change the
  house rules for every future project.
- **Parallel features.** There is no feature pointer at all, so separate sessions can work
  on different features at once (see "Several features in parallel" in `USAGE.md`).
- **No feature branches required.** Features are identified by their directory (named in
  each phase prompt), never by branch, so the seed drops into repos that only have long-lived branches (e.g.
  `development` / `hotfix` / `main`) without any change. Fill the `Branch model` line in the
  snippet's `Branch & session rules` block so sessions know where SDD work lands; the workflow
  notes are in `USAGE.md` ("Working without feature branches").

## Upgrading spec-kit later

Also done by asking Claude in a web session — no terminal. See the "Upstream baseline (for
upgrades)" section in `.specify/README.md`: fetch the new upstream into `.specify/upstream/vX/`,
diff it against the current `upstream/v1.2.2`, re-apply the recorded deviations to the changed
sections, and regenerate the skills.

## Upgrading a project that was seeded earlier

Seeded projects are independent copies, so after this seed is refreshed each project is
upgraded by copying the **seed-owned** files in and leaving the **project-owned** ones alone.
If several sessions or agents work on the project in parallel, follow the rollout below
rather than running the prompt on its own. Open a Claude Code session on the project's
integration branch (the branch features merge into, e.g. `development`) and paste
(substitute your seed repo's `owner/name`):

> Upgrade this repo's spec-kit install from the seed repo **`<owner>/spec-kit-seed`** (add it
> to the session read-only). Do not run any speckit phase in this session, and land the whole
> upgrade as **one commit**.
>
> 1. Replace these seed-owned paths with the seed's copies: `.claude/skills/speckit-*/`,
>    `.specify/scripts/bash/`, `.specify/templates/*-template.md`,
>    `.specify/templates/constitution-sample.md`, `.specify/README.md`, `.specify/.gitignore`,
>    `.specify/integration.json`, and replace `.specify/upstream/<old>/` with the seed's
>    `.specify/upstream/<new>/`. If this repo has local edits to any of them, show me the diff
>    and ask before overwriting. Do **not** touch `specs/`.
> 2. In `CLAUDE.md`, update only the `## Spec-Driven Development (SDD)` section from the seed's
>    `CLAUDE.snippet.md`, keeping this repo's filled-in values. Tell me if anything elsewhere
>    in `CLAUDE.md` says the feature resolves from `.specify/feature.json`.
> 3. If `.specify/feature.json` is tracked, run `git rm --cached .specify/feature.json`; then
>    delete the local file (`rm -f .specify/feature.json`) — the upgraded skills never use it.
> 4. Check `.specify/memory/constitution.md` against the upgraded skills. Read the upgraded
>    `.claude/skills/speckit-constitution/SKILL.md` from disk and follow it (not any copy
>    loaded when this session started). Look for: (a) a rule that the active feature resolves
>    from `.specify/feature.json`; (b) an amendment procedure requiring "an updated Sync Impact
>    Report"; (c) anything recorded only in a Sync Impact Report, such as a principle that puts
>    deferred tooling "in the Sync Impact Report"; (d) a Sync Impact Report comment committed
>    in the file. If you find any, propose an amendment that rewords them to match the seed's
>    `constitution-sample.md` (its *Branches* workflow line, *Deferred Setup* section and
>    *Governance* amendment paragraph), moves items listed only in the report into the body,
>    then removes the report — with the version bump the skill's rules call for, your reasoning,
>    and today's Last Amended date. Show me the diff and wait for my approval before writing
>    it. Report anything else in the constitution that contradicts the upgraded skills, but
>    don't change it.
> 5. Run `bash .specify/scripts/bash/preflight.sh`. Confirm it shows `Constitution: filled` and
>    lists every feature with its next phase, and report any duplicate-number warning to me.
>    Then commit and push to the current branch.

Nothing in `specs/` needs migrating. Check `.specify/README.md` ("Changes in this refresh")
for behaviour changes to tell the team about.

### Rolling the upgrade out while features are in flight

Old and new skill versions must not run side by side. The old ones read and write the
tracked `.specify/feature.json`, and a session keeps the skill instructions it started with.
So:

1. **Quiesce.** Let every running session finish its current phase and push. Start no new
   sessions until step 5.
2. **Upgrade the integration branch** with the prompt above, in one commit.
3. **Bring each in-flight feature branch up to date** (skip if all work runs on the
   integration branch). At a phase boundary, merge the integration branch into it. A branch
   whose old sessions wrote the pointer gets a modify/delete conflict on
   `.specify/feature.json`: resolve it with `git rm .specify/feature.json` (keep it deleted).
   Then run `preflight.sh <NNN>` on that branch. Do this before merging any such branch back,
   because a pull request from a branch that hasn't taken the upgrade hits the same conflict.
4. **Duplicate numbers.** If preflight warns that two directories share a number, rename the
   one merged second to the next free number before any session works on it.
5. **Restart** every agent in a fresh session, naming the feature in every prompt
   (*"speckit-implement for 004"*). For local agents, see "Several features in parallel" in
   `USAGE.md`: one `git worktree` per agent, never one shared checkout.
6. **Expect churn on in-flight features**, not conflicts:
   - Features whose implementation is **finished** (all tasks `[x]`): run `speckit-converge`
     before calling them done. It now re-checks every task regardless of `[x]` and may append
     work.
   - Features **mid-implementation**: finish `speckit-implement` first and converge afterwards
     as usual. Converge must run only after implement, and run early it would count the
     unbuilt tasks as missing and append duplicates of them.
   - A custom checklist's `[x]` now means a reviewer signed the item off, and implement asks
     before proceeding while any item is unchecked. Re-review any ticks an agent made under
     the old version (nothing forbade it then). For unattended agents, either get the
     checklists reviewed first or say in the implement prompt to proceed regardless.
   - `speckit-clarify` defers fewer questions, so re-running it on a draft spec may ask more.

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
