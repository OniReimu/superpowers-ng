#!/usr/bin/env bash
# Test: OpenCode bootstrap planning injection
# Verifies plugin injects shared planning bootstrap output (NATIVE and MANUS).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Test: OpenCode Bootstrap Planning Injection ==="

# Source setup to create isolated environment
source "$SCRIPT_DIR/setup.sh"

# Trap to cleanup on exit
trap cleanup_test_env EXIT

PLUGIN_FILE="$HOME/.config/opencode/superpowers-ng/.opencode/plugins/superpowers.js"

# Case 1: Native mode (no .active marker)
native_project="$TEST_HOME/native-project"
mkdir -p "$native_project"

echo "Test 1: Native planning mode injection..."
native_output=$(TEST_PROJECT_DIR="$native_project" PLUGIN_FILE="$PLUGIN_FILE" node --input-type=module <<'EOF'
const pluginPath = `file://${process.env.PLUGIN_FILE}`;
const { SuperpowersPlugin } = await import(pluginPath);
const output = {};
const plugin = await SuperpowersPlugin({ client: {}, directory: process.env.TEST_PROJECT_DIR });
await plugin['experimental.chat.system.transform']({}, output);
console.log((output.system || []).join('\n'));
EOF
)

if echo "$native_output" | grep -q "Planning mode: NATIVE"; then
    echo "  [PASS] Injects native planning mode when .active is absent"
else
    echo "  [FAIL] Missing native planning mode in bootstrap output"
    exit 1
fi

# Case 2: Manus mode (.active marker + plan files)
manus_project="$TEST_HOME/manus-project"
mkdir -p "$manus_project/docs/manus"
cat > "$manus_project/docs/manus/task_plan.md" <<'PLAN'
# OpenCode Active Task

**Goal:** Verify OpenCode planning bootstrap
**Current Phase:** 3 - Implementation
PLAN

cat > "$manus_project/docs/manus/findings.md" <<'FINDINGS'
# Findings

OpenCode bootstrap testing in progress.
FINDINGS

cat > "$manus_project/docs/manus/progress.md" <<'PROGRESS'
# Progress Log

Prepared active task state for bootstrap validation.
PROGRESS

touch "$manus_project/docs/manus/.active"

echo "Test 2: Manus planning mode injection..."
manus_output=$(TEST_PROJECT_DIR="$manus_project" PLUGIN_FILE="$PLUGIN_FILE" node --input-type=module <<'EOF'
const pluginPath = `file://${process.env.PLUGIN_FILE}`;
const { SuperpowersPlugin } = await import(pluginPath);
const output = {};
const plugin = await SuperpowersPlugin({ client: {}, directory: process.env.TEST_PROJECT_DIR });
await plugin['experimental.chat.system.transform']({}, output);
console.log((output.system || []).join('\n'));
EOF
)

if echo "$manus_output" | grep -q "Planning mode: MANUS"; then
    echo "  [PASS] Injects manus planning mode when .active is present"
else
    echo "  [FAIL] Missing manus planning mode in bootstrap output"
    exit 1
fi

if echo "$manus_output" | grep -q "active task: OpenCode Active Task"; then
    echo "  [PASS] Includes active task title in manus bootstrap output"
else
    echo "  [FAIL] Missing active task title in manus bootstrap output"
    exit 1
fi

echo ""
echo "=== All bootstrap planning tests passed ==="
