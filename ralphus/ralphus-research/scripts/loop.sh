#!/bin/bash
# Ralphus Research - Autonomous Learning Loop
# Usage: ./loop.sh [plan] [ultrawork|ulw] [max_iterations]
# Examples:
#   ./loop.sh                  # Research mode, unlimited iterations
#   ./loop.sh 20               # Research mode, max 20 iterations
#   ./loop.sh plan             # Plan mode, unlimited iterations
#   ./loop.sh plan 5           # Plan mode, max 5 iterations
#   ./loop.sh ultrawork        # Research mode with ultrawork
#   ./loop.sh ulw 10           # Ultrawork research, max 10 iterations

set -euo pipefail

# Configuration (override via environment variables)
AGENT="${RALPH_AGENT:-Sisyphus}"
OPENCODE="${OPENCODE_BIN:-opencode}"
ULTRAWORK=0

# Parse arguments
MODE="research"
PROMPT_FILE="PROMPT_research_build.md"
MAX_ITERATIONS=0

for arg in "$@"; do
    if [ "$arg" = "plan" ]; then
        MODE="plan"
        PROMPT_FILE="PROMPT_research_plan.md"
    elif [ "$arg" = "ultrawork" ] || [ "$arg" = "ulw" ]; then
        ULTRAWORK=1
    elif [[ "$arg" =~ ^[0-9]+$ ]]; then
        MAX_ITERATIONS=$arg
    fi
done

ITERATION=0
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")

# Header
echo "=== RALPHUS RESEARCH: $MODE mode | $AGENT | $CURRENT_BRANCH ==="
[ "$ULTRAWORK" -eq 1 ] && echo "Ultrawork: enabled"
[ "$MAX_ITERATIONS" -gt 0 ] && echo "Max iterations: $MAX_ITERATIONS"

# Verify prompt file exists
if [ ! -f "$PROMPT_FILE" ]; then
    echo "Error: $PROMPT_FILE not found"
    exit 1
fi

# Research mode requires RESEARCH_PLAN.md
if [ "$MODE" = "research" ] && [ ! -f "RESEARCH_PLAN.md" ]; then
    echo "Error: RESEARCH_PLAN.md not found."
    echo "Run planning mode first: ./loop.sh plan"
    exit 1
fi

# Archive previous run if branch changed
LAST_BRANCH_FILE=".last-branch"
if [ -f "$LAST_BRANCH_FILE" ]; then
    LAST_BRANCH=$(cat "$LAST_BRANCH_FILE")
    if [ "$LAST_BRANCH" != "$CURRENT_BRANCH" ]; then
        ARCHIVE_DIR="archive/$(date +%Y-%m-%d)-$LAST_BRANCH"
        mkdir -p "$ARCHIVE_DIR"
        cp RESEARCH_PLAN.md "$ARCHIVE_DIR/" 2>/dev/null || true
        cp -r knowledge/ "$ARCHIVE_DIR/" 2>/dev/null || true
        echo "Archived previous run to $ARCHIVE_DIR"
    fi
fi
echo "$CURRENT_BRANCH" > "$LAST_BRANCH_FILE"

# Graceful shutdown handler
SHUTDOWN=0
trap 'SHUTDOWN=1; echo -e "\n⚠ Shutdown requested. Finishing current iteration..."' INT TERM

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

    ITERATION=$((ITERATION + 1))
    echo -e "\n======================== ITERATION $ITERATION ========================\n"

    if [ "$ULTRAWORK" -eq 1 ]; then
        MESSAGE="Read the attached prompt file and execute the instructions. ulw"
    else
        MESSAGE="Read the attached prompt file and execute the instructions"
    fi

    # Run OpenCode with the prompt file
    OUTPUT=$("$OPENCODE" run --agent "$AGENT" -f "$PROMPT_FILE" -- "$MESSAGE" 2>&1 | tee /dev/stderr) || true

    # Check completion signals
    if echo "$OUTPUT" | grep -q "<promise>PHASE_COMPLETE</promise>"; then
        echo "=== TOPIC COMPLETE - next iteration ==="
    fi
    if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
        echo "=== ALL TOPICS LEARNED ===" && exit 0
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
