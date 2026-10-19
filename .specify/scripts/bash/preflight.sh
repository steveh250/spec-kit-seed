#!/usr/bin/env bash
# preflight.sh — report constitution status, the Spec Kit features in this repo, and the
# next valid phase for each. Read-only and non-destructive: it never creates git branches,
# never writes .specify/feature.json, and exits 0 unless a named feature cannot be found.
#
# Usage:
#   preflight.sh            list every feature under specs/features/ (detail if only one)
#   preflight.sh <feature>  detail for one feature: "002", "002-report-export", or a path
#
# With no argument, a feature pinned by SPECIFY_FEATURE_DIRECTORY or a local (untracked)
# .specify/feature.json is shown in detail. The feature is never resolved from the git
# branch name. Cloud sessions stay on the current branch.

set -euo pipefail

SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

REPO_ROOT="$(get_repo_root)" || REPO_ROOT="$(pwd)"
FEATURES_ROOT="$REPO_ROOT/specs/features"

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

# Every NNN-* feature directory, one absolute path per line, in numeric order.
list_features() {
    [ -d "$FEATURES_ROOT" ] || return 0
    local d
    for d in "$FEATURES_ROOT"/[0-9][0-9][0-9]-*/; do
        [ -d "$d" ] && printf '%s\n' "${d%/}"
    done
    return 0
}

# Next valid phase for a feature directory, derived from which artifacts exist.
next_phase() {
    local dir="$1" open
    if [ ! -f "$dir/spec.md" ]; then
        echo "speckit-specify (write spec.md for this feature)"
    elif grep -q '\[NEEDS CLARIFICATION' "$dir/spec.md" 2>/dev/null; then
        echo "speckit-clarify (spec.md has unresolved [NEEDS CLARIFICATION] markers)"
    elif [ ! -s "$dir/plan.md" ]; then
        echo "speckit-plan (design the implementation from spec.md)"
    elif [ ! -f "$dir/tasks.md" ]; then
        echo "speckit-tasks (break plan.md into tasks.md)"
    else
        open=$(grep -cE '^[[:space:]]*- \[ \]' "$dir/tasks.md" 2>/dev/null || true)
        if [ "${open:-0}" -gt 0 ]; then
            echo "speckit-analyze / speckit-implement ($open open tasks)"
        else
            echo "speckit-converge (all tasks checked; verify the code against the spec)"
        fi
    fi
}

show_feature() {
    local dir="$1"
    exists() { [ -f "$1" ] && printf '  [x] %s\n' "$2" || printf '  [ ] %s\n' "$2"; }

    echo "Feature: ${dir#"$REPO_ROOT"/}"
    echo
    echo "Artifacts:"
    exists "$dir/spec.md"  "spec.md"
    exists "$dir/plan.md"  "plan.md"
    exists "$dir/tasks.md" "tasks.md"
    # Optional design docs
    [ -f "$dir/research.md" ]   && echo "  [x] research.md"
    [ -f "$dir/data-model.md" ] && echo "  [x] data-model.md"
    [ -f "$dir/quickstart.md" ] && echo "  [x] quickstart.md"
    if [ -d "$dir/contracts" ] && [ -n "$(ls -A "$dir/contracts" 2>/dev/null)" ]; then
        echo "  [x] contracts/"
    fi
    if [ -d "$dir/checklists" ] && [ -n "$(ls -A "$dir/checklists" 2>/dev/null)" ]; then
        echo "  [x] checklists/"
    fi
    echo
    echo "Next valid phase: $(next_phase "$dir")"
}

show_all() {
    local features=() line
    while IFS= read -r line; do features+=("$line"); done < <(list_features)

    if [ "${#features[@]}" -eq 0 ]; then
        echo "Features: (none yet under specs/features/)"
        echo
        echo "Next valid phase: speckit-constitution (if the constitution is unwritten),"
        echo "then speckit-specify."
        return 0
    fi
    if [ "${#features[@]}" -eq 1 ]; then
        show_feature "${features[0]}"
        return 0
    fi
    echo "Features (name one in your request, e.g. \"speckit-plan for $(basename "${features[0]}" | cut -c1-3)\"):"
    for line in "${features[@]}"; do
        printf '  %-40s -> %s\n' "$(basename "$line")" "$(next_phase "$line")"
    done
}

echo "Spec Kit preflight"
echo "=================="
echo "Repo root: $REPO_ROOT"
echo "Constitution: $(constitution_status)  (.specify/memory/constitution.md)"
echo

if [ $# -gt 0 ] && [ -n "$1" ]; then
    want="${1%/}"
    matches=()
    if [ -d "$want" ]; then
        matches=("$(CDPATH="" cd "$want" && pwd)")
    elif [ -d "$REPO_ROOT/$want" ]; then
        matches=("$(CDPATH="" cd "$REPO_ROOT/$want" && pwd)")
    else
        while IFS= read -r line; do
            name="$(basename "$line")"
            if [ "$name" = "$want" ] || [ "${name%%-*}" = "$want" ]; then
                matches+=("$line")
            fi
        done < <(list_features)
    fi
    if [ "${#matches[@]}" -ne 1 ]; then
        echo "ERROR: feature '$1' matched ${#matches[@]} directories under specs/features/." >&2
        show_all
        exit 1
    fi
    show_feature "${matches[0]}"
elif paths_output="$(get_feature_paths --no-persist 2>/dev/null)"; then
    # Pinned by SPECIFY_FEATURE_DIRECTORY or a local .specify/feature.json.
    eval "$paths_output"
    show_feature "${FEATURE_DIR%/}"
else
    show_all
fi
