#!/usr/bin/env bash
# Shared planning bootstrap for session-start flows.
# - If docs/manus/.active exists: resume manus planning.
# - If not: guide native planning and offer manus enablement.

set -euo pipefail

OUTPUT_MODE="default"
if [ "${1:-}" = "--mode" ]; then
    OUTPUT_MODE="${2:-default}"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TEMPLATES_DIR="${PLUGIN_ROOT}/skills/manus-planning/templates"

if git_root="$(git -C "${PWD}" rev-parse --show-toplevel 2>/dev/null)"; then
    WORKING_DIR="${git_root}"
else
    WORKING_DIR="${PWD}"
fi

MANUS_DIR="${WORKING_DIR}/docs/manus"
MARKER_FILE="${MANUS_DIR}/.active"
TASK_PLAN_FILE="${MANUS_DIR}/task_plan.md"
FINDINGS_FILE="${MANUS_DIR}/findings.md"
PROGRESS_FILE="${MANUS_DIR}/progress.md"

trim() {
    local value="$1"
    value="$(printf '%s' "$value" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
    printf '%s' "$value"
}

copy_template_or_fallback() {
    local target_file="$1"
    local template_name="$2"
    local fallback_content="$3"

    if [ -f "${TEMPLATES_DIR}/${template_name}" ]; then
        cp "${TEMPLATES_DIR}/${template_name}" "${target_file}"
    else
        printf '%s\n' "${fallback_content}" > "${target_file}"
    fi
}

extract_goal() {
    local goal_line=""

    if [ -f "${TASK_PLAN_FILE}" ]; then
        goal_line="$(grep -m1 '^\*\*Goal:\*\*' "${TASK_PLAN_FILE}" | sed -E 's/^\*\*Goal:\*\*[[:space:]]*//' || true)"
        goal_line="$(trim "${goal_line}")"
        if [ -n "${goal_line}" ]; then
            printf '%s' "${goal_line}"
            return
        fi

        goal_line="$(awk '
            /^## Goal/ {capture=1; next}
            /^## / && capture {capture=0}
            capture && NF {print; exit}
        ' "${TASK_PLAN_FILE}" || true)"
        goal_line="$(trim "${goal_line}")"
    fi

    if [ -z "${goal_line}" ]; then
        goal_line="Goal not yet documented"
    fi

    printf '%s' "${goal_line}"
}

extract_task_title() {
    local title=""

    if [ -f "${TASK_PLAN_FILE}" ]; then
        title="$(grep -m1 '^# ' "${TASK_PLAN_FILE}" | sed -E 's/^#[[:space:]]+//' || true)"
        title="$(trim "${title}")"
    fi

    if [ -z "${title}" ]; then
        title="$(extract_goal)"
    fi

    printf '%s' "${title}"
}

extract_current_phase() {
    local phase=""

    if [ -f "${TASK_PLAN_FILE}" ]; then
        phase="$(grep -m1 '^\*\*Current Phase:\*\*' "${TASK_PLAN_FILE}" | sed -E 's/^\*\*Current Phase:\*\*[[:space:]]*//' || true)"
        phase="$(trim "${phase}")"
        if [ -n "${phase}" ]; then
            printf '%s' "${phase}"
            return
        fi

        phase="$(grep -m1 '^### Phase ' "${TASK_PLAN_FILE}" | sed -E 's/^### [[:space:]]*//' || true)"
        phase="$(trim "${phase}")"
    fi

    if [ -z "${phase}" ]; then
        phase="Unknown"
    fi

    printf '%s' "${phase}"
}

extract_recent_lines() {
    local file_path="$1"
    local fallback="$2"
    local lines=""

    if [ -f "${file_path}" ]; then
        lines="$(tail -n 120 "${file_path}" | sed '/^[[:space:]]*$/d' | grep -v '^---$' | tail -n 4 || true)"
    fi

    if [ -z "${lines}" ]; then
        lines="${fallback}"
    fi

    printf '%s' "${lines}"
}

if [ ! -f "${MARKER_FILE}" ]; then
    cat <<'EOF'
Planning mode: NATIVE

No active Manus task (`docs/manus/.active` not found).

Native startup flow:
- Start with a lightweight 3-line plan:
  Goal: <one sentence>
  Steps: <2-4 bullets>
  Verification: <how you will validate>
- Ask the user: "Enable manus persistent planning for this task? (yes/no)"
- If user says yes, create:
  - docs/manus/task_plan.md
  - docs/manus/findings.md
  - docs/manus/progress.md
  - docs/manus/.active
EOF
    exit 0
fi

mkdir -p "${MANUS_DIR}"

declare -a recovered_files=()

if [ ! -s "${TASK_PLAN_FILE}" ]; then
    copy_template_or_fallback "${TASK_PLAN_FILE}" "task_plan.md" "# Task Plan"
    recovered_files+=("task_plan.md")
fi

if [ ! -s "${FINDINGS_FILE}" ]; then
    copy_template_or_fallback "${FINDINGS_FILE}" "findings.md" "# Findings"
    recovered_files+=("findings.md")
fi

if [ ! -s "${PROGRESS_FILE}" ]; then
    copy_template_or_fallback "${PROGRESS_FILE}" "progress.md" "# Progress Log"
    recovered_files+=("progress.md")
fi

if [ "${#recovered_files[@]}" -gt 0 ]; then
    recovered_list="$(IFS=', '; printf '%s' "${recovered_files[*]}")"
    timestamp="$(date '+%Y-%m-%d %H:%M:%S %Z')"
    {
        echo ""
        echo "### Bootstrap Recovery (${timestamp})"
        echo "- Recovered missing plan files: ${recovered_list}"
    } >> "${PROGRESS_FILE}"
fi

task_title="$(extract_task_title)"
goal="$(extract_goal)"
current_phase="$(extract_current_phase)"
recent_progress="$(extract_recent_lines "${PROGRESS_FILE}" "No progress entries yet.")"
recent_findings="$(extract_recent_lines "${FINDINGS_FILE}" "No findings entries yet.")"

recovery_note=""
if [ "${#recovered_files[@]}" -gt 0 ]; then
    recovery_note="Recovery: Recovered missing plan files (${recovered_list})."
fi

cat <<EOF
Planning mode: MANUS (active task: ${task_title})

Active Manus task detected via \`docs/manus/.active\`.
${recovery_note}

Required continuation flow:
1. Read \`docs/manus/task_plan.md\`, \`docs/manus/progress.md\`, and \`docs/manus/findings.md\`.
2. In your first response, provide a brief continuation summary and the exact next step.
3. Continue writing \`progress.md\` and \`findings.md\` as work advances (at minimum append progress).

Continuation snapshot:
- Goal: ${goal}
- Current phase: ${current_phase}
- Recent progress:
${recent_progress}
- Recent findings:
${recent_findings}
EOF

# Allow future mode-specific behavior while keeping interface stable.
if [ "${OUTPUT_MODE}" = "codex" ]; then
    :
fi
