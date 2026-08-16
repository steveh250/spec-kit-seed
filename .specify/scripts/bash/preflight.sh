#!/usr/bin/env bash
# preflight.sh — report the active Spec Kit feature, which artifacts exist, and the
# next valid phase. Read-only and non-destructive: it never creates git branches,
# never writes .specify/feature.json, and exits 0 even when no feature is active yet.
#
# The active feature is resolved by common.sh from (in priority order):
#   1. SPECIFY_FEATURE_DIRECTORY  (explicit override)
#   2. .specify/feature.json      ("feature_directory" key, written by speckit-specify)
# — never from the git branch name. Cloud sessions stay on the current branch.

set -euo pipefail

SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

REPO_ROOT="$(get_repo_root)" || REPO_ROOT="$(pwd)"

# Report constitution state: missing / still-template / filled.
# "still-template" = contains bracketed [UPPER_SNAKE] placeholders, the template's
# own "<!-- Example:" guidance comments, or TODO markers.
constitution_status() {
    local c="$REPO_ROOT/.specify/memory/constitution.md"
    if [ ! -f "$c" ]; then
        echo "missing"
    elif grep -qE '\[[A-Z][A-Z0-9_]+\]|<!-- Example:|TODO' "$c"; then
        echo "still-template"
    else
        echo "filled"
    fi
}

echo "Spec Kit preflight"
echo "=================="
echo "Repo root: $REPO_ROOT"
echo "Constitution: $(constitution_status)  (.specify/memory/constitution.md)"

# Resolve feature paths without persisting (--no-persist keeps the working tree clean).
if ! paths_output="$(get_feature_paths --no-persist 2>/dev/null)"; then
    echo
    echo "Active feature: (none resolved)"
    echo
    echo "No feature is active yet. Set SPECIFY_FEATURE_DIRECTORY, or run the"
    echo "speckit-specify skill to create a feature and .specify/feature.json."
    echo
    echo "Next valid phase: speckit-constitution (if the constitution is unwritten),"
    echo "then speckit-specify."
    exit 0
fi
eval "$paths_output"

echo "Active feature dir: ${FEATURE_DIR:-unknown}"
echo

exists() { [ -f "$1" ] && printf '  [x] %s\n' "$2" || printf '  [ ] %s\n' "$2"; }

echo "Artifacts:"
exists "${FEATURE_SPEC:-/nonexistent}" "spec.md"
exists "${IMPL_PLAN:-/nonexistent}"    "plan.md"
exists "${TASKS:-/nonexistent}"        "tasks.md"
# Optional design docs
[ -f "${RESEARCH:-/nonexistent}" ]   && echo "  [x] research.md"
[ -f "${DATA_MODEL:-/nonexistent}" ] && echo "  [x] data-model.md"
[ -f "${QUICKSTART:-/nonexistent}" ] && echo "  [x] quickstart.md"
if [ -d "${CONTRACTS_DIR:-/nonexistent}" ] && [ -n "$(ls -A "$CONTRACTS_DIR" 2>/dev/null)" ]; then
    echo "  [x] contracts/"
fi
if [ -d "${FEATURE_DIR:-/nonexistent}/checklists" ] && [ -n "$(ls -A "$FEATURE_DIR/checklists" 2>/dev/null)" ]; then
    echo "  [x] checklists/"
fi

echo
# Determine the next valid phase from what exists.
have_spec=false;  [ -f "${FEATURE_SPEC:-/nonexistent}" ] && have_spec=true
have_plan=false;  [ -f "${IMPL_PLAN:-/nonexistent}" ]    && have_plan=true
have_tasks=false; [ -f "${TASKS:-/nonexistent}" ]        && have_tasks=true

if [ "$have_spec" = false ]; then
    next="speckit-specify (write spec.md for this feature)"
elif grep -q '\[NEEDS CLARIFICATION' "${FEATURE_SPEC}" 2>/dev/null; then
    next="speckit-clarify (spec.md has unresolved [NEEDS CLARIFICATION] markers)"
elif [ "$have_plan" = false ]; then
    next="speckit-plan (design the implementation from spec.md)"
elif [ "$have_tasks" = false ]; then
    next="speckit-tasks (break plan.md into tasks.md)"
else
    next="speckit-analyze / speckit-implement (artifacts complete; analyze then build)"
fi
echo "Next valid phase: $next"
