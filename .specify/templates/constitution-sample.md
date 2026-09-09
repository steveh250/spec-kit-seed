<!--
  constitution-sample.md — a reusable, pre-filled starting point for
  .specify/memory/constitution.md.

  Unlike constitution-template.md (upstream, blank), this file already carries the
  principles that recur across this owner's projects. Only the bracketed
  [ALL_CAPS] tokens are project-specific. To adopt it:

    1. cp .specify/templates/constitution-sample.md .specify/memory/constitution.md
    2. Replace every [ALL_CAPS] token (grep -n '\[[A-Z][A-Z0-9_]*\]' to find them).
    3. Delete any section marked "Applicability" that does not apply, or keep it
       and state why it is Not Applicable.
    4. Delete this comment block. The plan/tasks/implement gates stay locked while
       any [ALL_CAPS] token remains, so nothing half-filled can be planned against.

  Or simply invoke the speckit-constitution skill: it reads this file as the
  baseline and asks only about what differs for the project.
-->
<!--
Sync Impact Report
==================
Version change: (sample) → 1.0.0
Rationale: Initial ratification for [PROJECT_NAME], adopted from the owner's
cross-project constitution sample with project-specific values filled in.

Principles defined (9):
  I.    Specification Before Code
  II.   Documentation Is a Build Artifact
  III.  Hard Boundaries Between Tiers
  IV.   Security and Untrusted Input by Default
  V.    Tests Accompany Every Behaviour Change
  VI.   Consistent, Linted, Typed Code
  VII.  Configuration Over Hardcoding; Degrade Gracefully
  VIII. Observability and Auditable Provenance
  IX.   Simplicity and Honest Scope

Sections:
  Added → "Technology Constraints"
  Added → "Database Change Policy (Expand, Migrate, Contract)"
  Added → "Quality Targets (ISO 25010)"
  Added → "Development Workflow"
  Added → "Governance"

Runtime consumers to keep in sync:
  - CLAUDE.md (SDD phase order, hard gates, build/test/lint commands)
  - .specify/templates/plan-template.md (Constitution Check reads this file)

Deferred setup (tracked as follow-up work, not an open governance question):
  - [DEFERRED_SETUP_ITEMS]
-->

# [PROJECT_NAME] Constitution

[PROJECT_ONE_LINE_DESCRIPTION]

## Core Principles

### I. Specification Before Code

Behaviour is defined in a specification before it is implemented, and the
specification is the source of truth when code and spec disagree:

- New work follows the Spec-Driven Development (SDD) workflow in `CLAUDE.md`:
  `spec.md` → `plan.md` → `tasks.md` → code. No implementation code MUST be
  written for a feature without both `plan.md` and `tasks.md`.
- Where a Gherkin feature set exists, every in-scope scenario MUST be traced to a
  numbered functional requirement in `docs/FR.md` with a status of
  `Implemented`, `Partial`, or `Not Started`. Scenarios that do not apply to this
  build MUST be listed as excluded with a one-line rationale, never silently
  omitted.
- Any change to observable behaviour MUST update `spec.md` (and `plan.md` /
  `tasks.md` if affected) in the same change, before or alongside the code.
- Open questions are recorded as `[NEEDS CLARIFICATION]` markers in the spec and
  MUST be resolved before planning. Guessing is not permitted.

Rationale: a spec that is written first is testable, reviewable, and survives
the session that produced it. Artifacts, not conversation memory, carry state
between sessions.

### II. Documentation Is a Build Artifact

Documentation is produced and maintained in lockstep with code, not afterwards.
The following MUST exist and MUST be updated in every commit that changes code,
schema, or configuration:

| File | Contents |
|---|---|
| `README.md` | Summary and target audience, badges, quickstart in under five commands, links to the docs below, **known limitations and out-of-scope items** |
| `docs/ARCHITECTURE.md` | Mermaid component diagram, what each tier owns and does not own, communication paths, data-flow narrative, function inventory |
| `docs/DEPLOY.md` | Prerequisites, environment-variable table (`.env.example` mirrors it), deploy steps, migration procedure, rollback, local setup that mirrors production |
| `docs/FR.md` | Functional requirements traced to spec / Gherkin scenarios, with status |
| `docs/NFR.md` | Non-functional requirements, one row per ISO 25010 characteristic, measurable, with status `Met` / `Partial` / `Not Met` / `Not Applicable` |
| `docs/TEST-CASES.md` | Test cases for every implemented FR and NFR, with pass/fail and a summary table |
| `docs/SCHEMA.md` | Mermaid ERD, table reference, enums, indexes, migration history (omit only when there is no datastore, and say so in the file) |

A project MAY mark a document `Not Applicable` (for example `SCHEMA.md` in a
script-only repo) but MUST state the rationale in the file rather than leaving
it absent. A CI documentation-freshness check SHOULD fail the build when a
required file is missing or stale.

Rationale: every project, down to a two-script utility, has been easier to pick
up months later when the six documents exist. Making them a build artifact is
the only way they stay current.

### III. Hard Boundaries Between Tiers

Components are separated so each can be developed, deployed, scaled, and
replaced independently:

- The web tier (frontend + API) and any processing / agent tier MUST NOT call
  each other directly. Their only shared resource is the database (a job queue
  table, claimed with `SELECT … FOR UPDATE SKIP LOCKED`) or another explicitly
  declared contract in `docs/ARCHITECTURE.md`. Neither tier imports the other's
  modules; only a `shared/` configuration module is common.
- The frontend contains **no business logic**. All computation, validation, and
  transformation live in the backend language.
- Each deployable MUST be independently deployable and MUST own its own database
  and migration history. Deployables MUST NOT share a schema.
- Backends bind to loopback or sit behind an authenticating reverse proxy /
  edge middleware; they are never exposed directly.
- Shared tunables (ports, timeouts, feature flags) live in one configuration
  module; no component hardcodes a value that appears there.

Rationale: a database-only integration boundary makes "advisory processing
cannot corrupt authoritative data" a structural guarantee, and lets a local LLM
agent tier be swapped, restarted, or scaled without touching the web tier.

### IV. Security and Untrusted Input by Default

Every input from outside the process is hostile until validated:

- Uploaded files, document contents, API payloads, and anything forwarded to an
  LLM MUST be treated as untrusted data. Prompt-injection defences MUST be
  applied before external content reaches a model, and no operational business
  data is sent to a model unless the spec explicitly allows it.
- Secrets MUST come from environment variables or the platform's encrypted
  store, never from source. A `.env.example` MUST document every variable with
  placeholder values.
- Authentication and authorisation MUST be enforced server-side, before the
  origin, on every data-access and mutating endpoint (401 when absent).
  Credentials, tokens, and access strings MUST never reach the browser bundle.
- Ownership MUST be checked on every per-user query; a mismatch returns 404,
  not 403, so existence is not revealed.
- Filenames MUST be sanitised before use as paths; size limits MUST be enforced
  before writing to disk (413 with a readable message).
- No `eval`, `exec`, dynamically constructed code, or SQL built from user
  content. All queries are parameterised.

Rationale: these projects mediate business-critical documents and call external
or local models. Assuming hostile input and keeping credentials server-side
contains both the injection and the credential-leak classes of attack.

### V. Tests Accompany Every Behaviour Change

Every behaviour change ships with its tests in the same change:

- Backend: `pytest`, minimum [PYTHON_COVERAGE_MIN]% line coverage (target
  [PYTHON_COVERAGE_TARGET]%), enforced in CI. Every module has a corresponding
  test file. Integration tests run against a real database service container,
  never mocks of the schema.
- Frontend: unit tests ([FRONTEND_UNIT_TEST_TOOL]) and Playwright end-to-end
  tests covering the happy path **and** the error-recovery path, plus an
  axe-core scan with zero critical violations.
- Contract behaviour, security boundaries, immutability / hashing guarantees,
  and every `[NEEDS CLARIFICATION]` resolution MUST be covered by automated
  tests.
- Strict test-first (TDD) is NOT required; ordering is the author's choice.
- A failing test is never skipped, disabled, or quarantined to get to green.
  "Flake" is not a root cause.
- A change that alters observable behaviour without accompanying tests MUST NOT
  merge.

Rationale: tests are the executable record of intended behaviour. Requiring
them alongside every change, without dictating authoring order, keeps the safety
net current without ceremony.

### VI. Consistent, Linted, Typed Code

One style per language, enforced by tooling, as part of the definition of done:

- Python MUST pass `ruff` (lint + format) and `mypy`.
- TypeScript / Svelte MUST pass the framework type check (`svelte-check` or
  `tsc`) and the framework linter ([FRONTEND_LINT_COMMAND]).
- CI MUST run lint → type-check → test → build as blocking gates on every pull
  request. Nothing merges red.
- If a mandated tool is not yet configured, the constitution says so explicitly
  under *Deferred setup* in the Sync Impact Report; the absence is never blessed
  by silence.

Rationale: consistent style removes review noise and makes diffs about
behaviour. Naming deferred tooling keeps the principle honest until it is
enforceable.

### VII. Configuration Over Hardcoding; Degrade Gracefully

The whole system runs on a laptop and in production from the same code:

- Every tunable (ports, intervals, limits, model names, feature flags) MUST be
  overridable by environment variable or CLI flag with a documented default.
  Hardcoded values are build-blocking defects.
- Optional services (an LLM runtime, a vector store, a third-party API) MUST
  have a clearly labelled stub or `mock` mode so the full stack starts without
  them. Stub output MUST be visibly marked as such, never passed off as real.
- Local development MUST mirror production behaviour (same schema, same auth
  path with a dev shim, same API contract).
- API responses use one envelope (`{ "data": …, "error": null }` /
  `{ "data": null, "error": { "code", "message" } }`) and documented HTTP status
  codes; a 200 for an error condition is a defect.

Rationale: a stack that only works with every external dependency present is a
stack nobody can run, test, or demo. Fallbacks and configuration make the
"clone → run in five commands" quickstart true.

### VIII. Observability and Auditable Provenance

Anything the system decides can be reconstructed afterwards from stored state:

- All components emit structured logs with timestamp, component name, level,
  and message. Long-running workers include an instance identifier in every line.
- Every job / pipeline step records `started_at`, `completed_at`,
  `elapsed_seconds`, and `status`; failures record a descriptive error and mark
  the job `error`, never silently continue.
- Every LLM run persists the exact canonical input, the model and parameters,
  and the raw response, so a finding is reproducible. Agent reasoning traces
  are saved as audit files alongside outputs.
- Records that govern decisions (rules, published packages, assessments) are
  versioned and immutable once active; changing behaviour means a new version.
  Published artifacts are write-once and content-addressed by SHA-256 where the
  spec calls for it.

Rationale: business decisions and model outputs must be auditable after the
fact. Structured logs plus stored inputs make every result traceable to a
verifiable input.

### IX. Simplicity and Honest Scope

Build the smallest thing that satisfies the spec, and say what it is:

- The README states plainly whether the build is a proof of concept or
  production-grade, and lists known limitations and out-of-scope items.
- YAGNI: no abstraction, framework, or infrastructure that the current spec
  does not require. Complexity MUST be justified in `plan.md`'s Complexity
  Tracking table with the simpler alternative that was rejected.
- Introducing a new language, framework, datastore, or dependency of comparable
  weight requires a constitution amendment or a recorded decision in the
  feature's `plan.md`.
- Third-party code and forks preserve the upstream licence and copyright notice
  (MIT by default) and document what was taken verbatim versus adapted.

Rationale: honest scope statements keep a POC from being mistaken for a
product, and keep the codebase small enough for one person to hold in their
head.

## Technology Constraints

The stack is fixed unless amended here. Delete rows that do not apply.

| Layer | Technology |
|---|---|
| Backend / business logic | Python 3.11+ ([PYTHON_WEB_FRAMEWORK]), Pydantic v2 |
| Frontend | [FRONTEND_FRAMEWORK] (SvelteKit or Next.js), TypeScript, Tailwind |
| Database | PostgreSQL ([POSTGRES_PROVIDER]) in production; SQLite or a local Postgres container for tests |
| Migrations | [MIGRATION_TOOL] (Alembic, or numbered SQL under `database/migrations/`) |
| LLM / inference | [LLM_PROVIDER] (Ollama locally; OpenAI or equivalent hosted, via structured JSON output) |
| Vector store | [VECTOR_STORE] (Chroma with in-memory fallback) or Not Applicable |
| Auth | Server-side session cookie behind edge middleware or reverse proxy |
| Hosting | [HOSTING_PLATFORM] (Vercel or Cloudflare Pages), preview deployments on every PR |
| Source control / CI | GitHub, branch protection, PR-gated merges, GitHub Actions |

**Deployables**: [DEPLOYABLE_LIST] (single-deployable, or list each with its
tag, path, and test command for multi-deployable task tagging).

## Database Change Policy (Expand, Migrate, Contract)

*Applicability: any project with a relational datastore. Delete this section if
there is none, and note that in `docs/SCHEMA.md`.*

Destructive schema changes in a single step are prohibited: `DROP COLUMN`,
`RENAME COLUMN`, incompatible `ALTER COLUMN TYPE`, `DROP TABLE`, removing an
enum value, or adding `NOT NULL` without a `DEFAULT`. Every schema change
follows three phases:

1. **Expand**: add new structures alongside old; new columns nullable or
   defaulted; script idempotent (`IF NOT EXISTS`, `CREATE OR REPLACE`).
2. **Migrate**: move data in configurable batches (default 1 000 rows); never
   hold an exclusive lock longer than 5 seconds; resumable and idempotent.
3. **Contract**: remove old structures only after code no longer references
   them (CI ref-check) and migration is verified complete; requires named
   reviewer approval.

Migration files are numbered `NNNN_phase_description.sql` with no gaps, carry a
header comment (phase, description, author, date, rollback reference), and have
a rollback script for Expand and Contract phases. `database/schema.sql` is the
target end state; CI verifies that applying all migrations to a blank database
matches it and that applying them twice is error-free.

## Quality Targets (ISO 25010)

Measurable targets, recorded per characteristic in `docs/NFR.md`. Adjust the
numbers; do not replace them with aspirational language.

| Characteristic | Target |
|---|---|
| Performance | API p95 < [API_P95_MS] ms; status poll p95 < 200 ms; page load < 2 s on 4G |
| Reliability | [UPTIME_TARGET]% uptime over 30 days; a single worker/agent failure never crashes the runner; graceful `SIGINT`/`SIGTERM` |
| Security | Principle IV enforced; zero secrets in source; auth on every endpoint |
| Maintainability | Principle VII: no hardcoded values; one shared config module; every module has a test file |
| Usability / accessibility | WCAG 2.1 AA; inline form validation; recover from errors without reload |
| Portability | Full stack runs locally with documented commands; switching hosting adapter changes no application logic |

## Development Workflow

- **SDD phases**: `speckit-constitution` → `speckit-specify` → `speckit-clarify`
  → `speckit-plan` → `speckit-tasks` → (`speckit-analyze` / `speckit-checklist`)
  → `speckit-implement` → `speckit-converge`. One phase per session; each phase
  commits its artifact before the next session starts.
- **Hard gates**: no `plan.md` against an unfilled constitution or unresolved
  `[NEEDS CLARIFICATION]`; no `tasks.md` without `plan.md`; no code without
  both. Constitution conflicts are resolved by changing the spec / plan / tasks
  or by amending this file, never by ignoring the principle.
- **Branches**: [BRANCH_MODEL]. Sessions work on the current branch only and
  never create or switch branches. `main` is protected; changes land by pull
  request with CI green. The active feature resolves from
  `.specify/feature.json`, never from a branch name.
- **Tasks**: every task in `tasks.md` carries an ID, an optional `[P]`
  parallel marker, a `[US#]` story label, an exact file path, and, in
  multi-deployable repos, a deployable tag so a session installs one toolchain
  and works a contiguous block.
- **Definition of done** for a change: spec updated, tests added and green,
  lint / type-check green, the documentation set in Principle II updated,
  `tasks.md` checkboxes ticked, and the commit pushed.
- **Commits**: small, descriptive, one concern each; artifacts committed as they
  are produced. Never rewrite history on a shared branch.
- **Conflicts**: if an instruction conflicts with this constitution or the
  build contract, flag the conflict before proceeding.

## Governance

This constitution supersedes ad-hoc practice and any conflicting guidance in
`CLAUDE.md`. When a principle conflicts with a spec, plan, or task, the conflict
MUST be resolved by changing the spec / plan / task or by amending this file,
never by silently ignoring the principle.

Amendments are made by editing this file with an updated Sync Impact Report, a
semantic version bump, and the amendment date:

- **MAJOR**: a principle is removed or redefined in a backward-incompatible way.
- **MINOR**: a principle or section is added, or guidance materially expanded.
- **PATCH**: clarifications and wording that do not change meaning.

Compliance is verified twice: at plan time, in `plan.md`'s Constitution Check
(every principle assessed PASS or justified in Complexity Tracking), and at
review time on every pull request. Runtime development guidance (commands,
layout, branch rules) lives in `CLAUDE.md`.

**Version**: 1.0.0 | **Ratified**: [RATIFICATION_DATE] | **Last Amended**: [RATIFICATION_DATE]
