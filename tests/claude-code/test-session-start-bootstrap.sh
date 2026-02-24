#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: session-start bootstrap context ==="

TEST_PROJECT=$(create_test_project)
trap "cleanup_test_project $TEST_PROJECT" EXIT

# Case 1: no .active marker -> SessionStart context should include NATIVE status line
output_native=$(cd "$TEST_PROJECT" && "$SCRIPT_DIR/../../hooks/session-start.sh")
assert_valid_json "$output_native" "SessionStart hook emits valid JSON (native case)"
assert_contains "$output_native" "\"hookEventName\": \"SessionStart\"" "SessionStart payload includes hook event name"
assert_contains "$output_native" "Planning mode: NATIVE" "SessionStart context includes native planning mode"

# Case 2: .active marker + manus files -> SessionStart context should include MANUS status line
mkdir -p "$TEST_PROJECT/docs/manus"
cat > "$TEST_PROJECT/docs/manus/task_plan.md" <<'PLAN'
# Cursor Resume Task

**Goal:** Verify Cursor/Claude SessionStart bootstrap
**Current Phase:** 2 - Planning & Structure
PLAN

cat > "$TEST_PROJECT/docs/manus/findings.md" <<'FINDINGS'
# Findings

Validated startup hook behavior.
FINDINGS

cat > "$TEST_PROJECT/docs/manus/progress.md" <<'PROGRESS'
# Progress Log

Prepared resume context for session start.
PROGRESS

touch "$TEST_PROJECT/docs/manus/.active"

output_manus=$(cd "$TEST_PROJECT" && "$SCRIPT_DIR/../../hooks/session-start.sh")
assert_valid_json "$output_manus" "SessionStart hook emits valid JSON (manus case)"
assert_contains "$output_manus" "Planning mode: MANUS" "SessionStart context includes manus planning mode"
assert_contains "$output_manus" "active task: Cursor Resume Task" "SessionStart context includes active task title"

echo "=== All tests passed ==="
