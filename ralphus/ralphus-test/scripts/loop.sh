#!/bin/bash
# Ralphus Test - Autonomous Test Creation Loop
# Usage: ./ralphus/ralphus-test/scripts/loop.sh [plan] [ultrawork|ulw] [max_iterations]
# Examples:
#   ./ralphus/ralphus-test/scripts/loop.sh                  # Test creation mode
#   ./ralphus/ralphus-test/scripts/loop.sh 20               # Max 20 tests
#   ./ralphus/ralphus-test/scripts/loop.sh plan             # Plan mode
#   ./ralphus/ralphus-test/scripts/loop.sh plan 1           # Plan mode, single iteration

set -euo pipefail

# Resolve script directory and ralphus-test root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RALPHUS_TEST_DIR="$(dirname "$SCRIPT_DIR")"

# Configuration (override via environment variables)
AGENT="${RALPH_AGENT:-Sisyphus}"
OPENCODE="${OPENCODE_BIN:-opencode}"
TEST_SPECS_DIR="test-specs"
TEMPLATES_DIR="$RALPHUS_TEST_DIR/templates"
INSTRUCTIONS_DIR="$RALPHUS_TEST_DIR/instructions"
ULTRAWORK=0

# Parse arguments
MODE="test"
PROMPT_FILE="$INSTRUCTIONS_DIR/PROMPT_test_build.md"
MAX_ITERATIONS=0

for arg in "$@"; do
    if [ "$arg" = "plan" ]; then
        MODE="plan"
        PROMPT_FILE="$INSTRUCTIONS_DIR/PROMPT_test_plan.md"
    elif [ "$arg" = "ultrawork" ] || [ "$arg" = "ulw" ]; then
        ULTRAWORK=1
    elif [[ "$arg" =~ ^[0-9]+$ ]]; then
        MAX_ITERATIONS=$arg
    fi
done

ITERATION=0
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")

# Header
echo "=== RALPHUS TEST: $MODE mode | $AGENT | $CURRENT_BRANCH ==="
[ "$ULTRAWORK" -eq 1 ] && echo "Ultrawork: enabled"
[ "$MAX_ITERATIONS" -gt 0 ] && echo "Max iterations: $MAX_ITERATIONS"

# Verify prompt file exists
if [ ! -f "$PROMPT_FILE" ]; then
    echo "Error: $PROMPT_FILE not found"
    exit 1
fi

# Verify templates directory exists
if [ ! -d "$TEMPLATES_DIR" ]; then
    echo "Error: $TEMPLATES_DIR/ directory not found."
    exit 1
fi

# Verify test-specs/ directory exists (in project root)
if [ ! -d "$TEST_SPECS_DIR" ]; then
    echo "Error: $TEST_SPECS_DIR/ directory not found."
    echo "Create $TEST_SPECS_DIR/*.md files with your test specifications."
    exit 1
fi

# Test mode: check for incomplete tests
if [ "$MODE" = "test" ]; then
    echo "Test specs directory: $TEST_SPECS_DIR/"
    
    # Check if any spec has incomplete tests
    if ! grep -rq "\[ \]" "$TEST_SPECS_DIR/"; then
        if grep -rq "\[x\]" "$TEST_SPECS_DIR/"; then
            echo "=== ALL TESTS COMPLETE ==="
            exit 0
        else
            echo "Warning: No checkboxes found in test specs."
            echo "Run planning mode first: $0 plan"
            exit 1
        fi
    fi
fi

# Archive previous run if branch changed
LAST_BRANCH_FILE=".last-branch"
if [ -f "$LAST_BRANCH_FILE" ]; then
    LAST_BRANCH=$(cat "$LAST_BRANCH_FILE")
    if [ "$LAST_BRANCH" != "$CURRENT_BRANCH" ]; then
        ARCHIVE_DIR="archive/$(date +%Y-%m-%d)-$LAST_BRANCH"
        mkdir -p "$ARCHIVE_DIR"
        # Archive all test specs
        cp -r "$TEST_SPECS_DIR" "$ARCHIVE_DIR/" 2>/dev/null || true
        echo "Archived previous run to $ARCHIVE_DIR"
    fi
fi
echo "$CURRENT_BRANCH" > "$LAST_BRANCH_FILE"

# Graceful shutdown handler
SHUTDOWN=0
trap 'SHUTDOWN=1; echo -e "\n⚠ Shutdown requested. Finishing current test..."' INT TERM

# Main loop
while true; do
    # Check for shutdown request
    if [ "$SHUTDOWN" -eq 1 ]; then
        echo "Shutting down gracefully."
        exit 0
    fi

    # Check iteration limit
    if [ "$MAX_ITERATIONS" -gt 0 ] && [ "$ITERATION" -ge "$MAX_ITERATIONS" ]; then
        echo "Reached max iterations: $MAX_ITERATIONS"
        break
    fi

    # Check if all tests are complete (no more [ ] in any spec)
    if [ "$MODE" = "test" ] && ! grep -rq "\[ \]" "$TEST_SPECS_DIR/"; then
        echo "=== ALL TESTS COMPLETE ==="
        exit 0
    fi

    ITERATION=$((ITERATION + 1))
    echo -e "\n======================== ITERATION $ITERATION ========================\n"

    if [ "$ULTRAWORK" -eq 1 ]; then
        MESSAGE="Read the attached prompt file and execute the instructions. ulw"
    else
        MESSAGE="Read the attached prompt file and execute the instructions"
    fi

    # Run OpenCode with the prompt file AND templates directory
    # Attach both the prompt and all template files for context
    OUTPUT=$("$OPENCODE" run --agent "$AGENT" \
        -f "$PROMPT_FILE" \
        -f "$TEMPLATES_DIR/SPEC_FORMAT.md" \
        -f "$TEMPLATES_DIR/SUMMARY_HEADER.md" \
        -f "$TEMPLATES_DIR/TEST_UTILITIES.md" \
        -- "$MESSAGE" 2>&1 | tee /dev/stderr) || true

    # Check completion signals
    if echo "$OUTPUT" | grep -q "<promise>PLAN_COMPLETE</promise>"; then
        echo "=== PLANNING COMPLETE ==="
        echo "Test specification prepared. Run: $0"
        exit 0
    fi
    if echo "$OUTPUT" | grep -q "<promise>PHASE_COMPLETE</promise>"; then
        echo "=== TEST COMPLETE - next iteration ==="
    fi
    if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
        echo "=== ALL TESTS IMPLEMENTED ===" && exit 0
    fi
    if echo "$OUTPUT" | grep -q "<promise>BLOCKED:"; then
        echo "=== BLOCKED ===" && echo "$OUTPUT" | grep -o "<promise>BLOCKED:[^<]*</promise>" && exit 1
    fi

    # Push changes after each iteration (if in a git repo)
    if git rev-parse --git-dir > /dev/null 2>&1; then
        git push origin "$CURRENT_BRANCH" 2>/dev/null || {
            echo "Note: Failed to push. Creating remote branch..."
            git push -u origin "$CURRENT_BRANCH" 2>/dev/null || echo "Warning: Could not push to remote"
        }
    fi
done

echo "=== Loop finished after $ITERATION iterations ==="
