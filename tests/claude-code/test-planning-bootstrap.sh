#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: planning bootstrap ==="

TEST_PROJECT=$(create_test_project)
trap "cleanup_test_project $TEST_PROJECT" EXIT

# Case 1: No .active marker -> native mode
output_native=$(cd "$TEST_PROJECT" && "$SCRIPT_DIR/../../hooks/planning-bootstrap.sh")
assert_contains "$output_native" "Planning mode: NATIVE" "Reports native mode when inactive"
assert_contains "$output_native" "Enable manus persistent planning" "Suggests manus enablement"

# Case 2: .active + all files -> manus mode and continuation summary
mkdir -p "$TEST_PROJECT/docs/manus"
cat > "$TEST_PROJECT/docs/manus/task_plan.md" <<'PLAN'
# Demo Active Task

**Goal:** Validate bootstrap continuation summary
**Current Phase:** 3 - Implementation
PLAN

cat > "$TEST_PROJECT/docs/manus/findings.md" <<'FINDINGS'
# Findings

Recent finding: API edge-case discovered.
FINDINGS

cat > "$TEST_PROJECT/docs/manus/progress.md" <<'PROGRESS'
# Progress Log

Implemented baseline endpoint.
PROGRESS

touch "$TEST_PROJECT/docs/manus/.active"

output_active=$(cd "$TEST_PROJECT" && "$SCRIPT_DIR/../../hooks/planning-bootstrap.sh")
assert_contains "$output_active" "Planning mode: MANUS" "Reports manus mode when active"
assert_contains "$output_active" "active task: Demo Active Task" "Extracts active task title"
assert_contains "$output_active" "Required continuation flow" "Prints continuation flow"

# Case 3: .active + missing files -> auto recovery + log entry
rm -f "$TEST_PROJECT/docs/manus/findings.md"
: > "$TEST_PROJECT/docs/manus/progress.md"

output_recovery=$(cd "$TEST_PROJECT" && "$SCRIPT_DIR/../../hooks/planning-bootstrap.sh")
assert_contains "$output_recovery" "Planning mode: MANUS" "Stays in manus mode after recovery"
assert_contains "$output_recovery" "Recovered missing plan files" "Reports recovered files"
assert_file_exists "$TEST_PROJECT/docs/manus/findings.md" "Recreates findings file"
assert_file_contains "$TEST_PROJECT/docs/manus/progress.md" "Recovered missing plan files" "Logs recovery in progress"

echo "=== All tests passed ==="
