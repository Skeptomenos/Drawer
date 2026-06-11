# Drawer validation gate (hardening roadmap Phase 0).
#
# `make validate` is THE definition of done. One deterministic command,
# stages chained so nothing is skipped silently:
#   1. lint   - swiftlint --strict (zero violations)
#   2. build  - app target; SWIFT_TREAT_WARNINGS_AS_ERRORS=YES is set in the
#              Drawer target build settings (zero-warnings policy)
#   3. test   - safe unit suite (system tests auto-skip; see DrawerTests/SystemTestGate.swift)
#   4. smoke  - launch the built .app, assert it stays alive, terminate it
#
# `make validate-system` additionally runs the system-level suite
# (DRAWER_SYSTEM_TESTS=1). It interacts with the REAL menu bar and requires
# granted TCC permissions - run manually on a dev machine, never in CI.

PROJECT      := Drawer.xcodeproj
SCHEME       := Drawer
CONFIG       := Debug
BUILD_FLAGS  := -project $(PROJECT) -scheme $(SCHEME) -configuration $(CONFIG) CODE_SIGNING_ALLOWED=NO
DERIVED_DATA := $(shell xcodebuild $(BUILD_FLAGS) -showBuildSettings 2>/dev/null | awk '/ BUILT_PRODUCTS_DIR =/{print $$3; exit}')

.PHONY: validate validate-system lint build test smoke clean

validate: lint build test smoke
	@echo "=== VALIDATE: ALL STAGES GREEN ==="

validate-system: lint build test-system smoke
	@echo "=== VALIDATE-SYSTEM: ALL STAGES GREEN ==="

lint:
	@echo "=== STAGE 1: lint ==="
	swiftlint --strict --quiet

build:
	@echo "=== STAGE 2: build (warnings as errors) ==="
	set -o pipefail; xcodebuild $(BUILD_FLAGS) build 2>&1 | grep -E "(warning|error):|BUILD "

test:
	@echo "=== STAGE 3: safe unit tests (system tests skip) ==="
	set -o pipefail; xcodebuild test $(BUILD_FLAGS) -only-testing:DrawerTests 2>&1 \
		| grep -E "Test Suite|Executed.*tests|error:|failed" | tail -8
	@pkill -f "$(DERIVED_DATA)/Drawer.app/Contents/MacOS/Drawer" 2>/dev/null; true

test-system:
	@echo "=== STAGE 3: FULL suite incl. system tests (real menu bar interaction) ==="
	set -o pipefail; DRAWER_SYSTEM_TESTS=1 xcodebuild test $(BUILD_FLAGS) -only-testing:DrawerTests 2>&1 \
		| grep -E "Test Suite|Executed.*tests|error:|failed" | tail -8
	@pkill -f "$(DERIVED_DATA)/Drawer.app/Contents/MacOS/Drawer" 2>/dev/null; true

smoke: build
	@echo "=== STAGE 4: launch smoke (built artifact) ==="
	@./scripts/smoke.sh "$(DERIVED_DATA)/Drawer.app"

clean:
	xcodebuild $(BUILD_FLAGS) clean | tail -1
