#!/bin/bash
# Smoke stage of the Drawer validation gate (see Makefile).
#
# Launches the freshly BUILT Drawer.app (not the installed copy), asserts the
# process survives 5 seconds (catches crash-on-launch), then terminates ONLY
# the instance it launched. Never touches a user-launched Drawer instance.
set -euo pipefail

APP_PATH="${1:?usage: smoke.sh /path/to/Drawer.app}"
BINARY="$APP_PATH/Contents/MacOS/Drawer"

if [[ ! -x "$BINARY" ]]; then
    echo "SMOKE FAIL: built app not found at $APP_PATH (run 'make build' first)" >&2
    exit 1
fi

# Launch the binary directly (not `open`) so we own the exact PID.
"$BINARY" >/dev/null 2>&1 &
PID=$!

cleanup() {
    kill "$PID" 2>/dev/null || true
}
trap cleanup EXIT

sleep 5

if ! kill -0 "$PID" 2>/dev/null; then
    echo "SMOKE FAIL: Drawer (pid $PID) exited within 5s of launch - crash on startup" >&2
    exit 1
fi

echo "SMOKE OK: Drawer (pid $PID) launched from built artifact and stayed alive 5s"
