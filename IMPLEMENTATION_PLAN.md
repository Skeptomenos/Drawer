# Implementation Plan: Menu Bar Layout Fixes

**Created**: 2026-01-18
**Specs**: 5.6 (Ordering Fix), 5.7 (Repositioning Fix), 5.8 (Ice Patterns Reference)

---

## Executive Summary

The Menu Bar Layout feature in `SettingsMenuBarLayoutView.swift` has two critical bugs:

1. **Ordering Bug (Spec 5.6)**: Icons "switch" positions when clicking refresh because `reconcileLayout()` uses saved layout order instead of actual captured X-position order.

2. **Repositioning Bug (Spec 5.7)**: Physical repositioning fails because `findIconItem()` uses only identifier matching, which fails when bundle IDs or titles differ between saved layout and live icons.

This plan implements fixes in 4 phases with 19 tasks total.

---

## Current State Analysis

| Component | Location | Issue |
|-----------|----------|-------|
| `reconcileLayout()` | Lines 667-724 | Uses `matchingSaved.order` instead of captured X-position |
| `findIconItem()` | Lines 410-418 | Single-tier matching (identifier only) |
| `windowIDCache` | N/A | Does not exist |
| `ReconciliationResult` | Lines 17-26 | Missing `windowIDCache` field |
| Test coverage | N/A | `DrawerTests/UI/` directory does not exist |

---

## Phase 1: Test Foundation (Tasks 1-4)

**Goal**: Create test infrastructure to verify fixes and prevent regressions.

### Task 1: Create UI Test Directory and Test File [COMPLETED]
- **File**: `DrawerTests/UI/Settings/SettingsMenuBarLayoutViewTests.swift`
- **Action**: Create directory structure and test file with XCTest imports
- **Scope**: File scaffolding only
- **Status**: Completed - Created `DrawerTests/UI/Settings/` directory and test file with 10 test method stubs (7 skipped, awaiting implementation)

### Task 2: Create Mock CapturedIcon Factory [COMPLETED]
- **File**: `DrawerTests/Mocks/MockCapturedIconFactory.swift`
- **Action**: Create helper to generate `CapturedIcon` instances with controllable X-positions
- **Scope**: Factory methods for test data generation
- **Status**: Completed - Created factory with:
  - `createIcon()` - Creates icons with specific bundleId, xPosition, section, windowID
  - `createIconWithoutInfo()` - Creates icons without itemInfo for edge case testing
  - `createIconsInOrder()` - Creates multiple icons at even intervals
  - `createIconsWithPositions()` - Creates icons with explicit X positions
  - `createIconsWithSections()` - Creates icons with mixed sections
  - `createLayoutItem()` / `createLayoutItems()` - Creates SettingsLayoutItem from icons
  - Test extension for `MenuBarItemInfo` with direct initializer

### Task 3: Write Ordering Tests (Spec 5.6) [COMPLETED]
- **File**: `DrawerTests/UI/Settings/SettingsMenuBarLayoutViewTests.swift`
- **Action**: Implement tests:
  - `testReconcileLayout_UsesCapturedOrder()` - Verifies X-position order is used
  - `testReconcileLayout_RespectsSectionOverrides()` - Verifies user overrides preserved
- **Status**: Completed - Implemented 7 tests for Spec 5.6:
  1. `testReconcileLayout_UsesCapturedOrder()` - PASSING
  2. `testReconcileLayout_RespectsSectionOverrides()` - PASSING
  3. `testReconcileLayout_NewIconsUseCapturedPosition()` - PASSING
  4. `testReconcileLayout_PreservesSpacers()` - PASSING
  5. `testReconcileLayout_PopulatesWindowIDCache()` - PASSING
  6. `testReconcileLayout_NoOverrideWhenSectionsMatch()` - PASSING
  7. `testReconcileLayout_NormalizesOrdersWithinSection()` - PASSING
- **Additional Changes**:
  - Created `Drawer/UI/Settings/LayoutReconciler.swift` - New testable reconciliation algorithm
  - Added ownerName fallback to `SettingsLayoutItem.matches()` for test compatibility
  - Renamed `ReconciliationResult` to `LegacyReconciliationResult` in `SettingsMenuBarLayoutView.swift` to avoid conflict

### Task 4: Write Icon Matching Tests (Spec 5.7) [COMPLETED]
- **File**: `DrawerTests/UI/Settings/SettingsMenuBarLayoutViewTests.swift`  
- **Action**: Implement tests:
  - `testFindIconItem_UsesWindowIDCache()` - Verifies windowID cache is used first
  - `testFindIconItem_FallsBackToBundleID()` - Verifies fallback matching
  - `testFindIconItem_ReturnsNilForSpacers()` - Verifies spacer handling
- **Status**: Completed - Implemented 7 tests for Spec 5.7:
  1. `testFindIconItem_UsesWindowIDCache()` - PASSING
  2. `testFindIconItem_FallsBackToBundleID()` - PASSING
  3. `testFindIconItem_ReturnsNilForSpacers()` - PASSING
  4. `testFindIconItem_MatchesByBundleIDIgnoringDynamicTitle()` - PASSING
  5. `testFindIconItem_FallsBackToOwnerName()` - PASSING
  6. `testFindIconItem_ReturnsNotFoundWhenNoMatch()` - PASSING
  7. `testFindIconItem_ExactMatchTakesPrecedence()` - PASSING
- **Additional Changes**:
  - Created `Drawer/UI/Settings/IconMatcher.swift` - New testable multi-tier matching algorithm
  - Added test initializer to `IconItem` for creating mock IconItems in tests

---

## Phase 2: Spec 5.6 - Ordering Fix (Tasks 5-10)

**Goal**: Fix `reconcileLayout()` to use captured X-positions as source of truth.

### Task 5: Add Debug Logger for Layout View [COMPLETED]
- **File**: `Drawer/UI/Settings/SettingsMenuBarLayoutView.swift`
- **Action**: Add `os.log` subsystem/category for layout debugging
- **Scope**: Logger setup only
- **Status**: Completed - Logger already exists at lines 107-110 with subsystem `com.drawer` and category `SettingsMenuBarLayoutView`. Currently used in 12 locations for debug, info, warning, and error logging.

### Task 6: Refactor reconcileLayout() - Sort by X-Position [COMPLETED]
- **File**: `Drawer/UI/Settings/SettingsMenuBarLayoutView.swift`
- **Lines**: 670-686 (after edit)
- **Action**: 
  1. Sort `capturedIcons` by `originalFrame.minX` at start of function
  2. Add debug log: `[Layout] Sorted \(count) icons by X-position`
- **Scope**: Add sorting before main loop
- **Status**: Completed - Added X-position sorting at line 681 and debug log at line 682. The loop now iterates over `sortedIcons` instead of `capturedIcons`.

### Task 7: Refactor reconcileLayout() - Section from Capture [COMPLETED]
- **File**: `Drawer/UI/Settings/SettingsMenuBarLayoutView.swift`
- **Action**: Updated `refreshItems()` to use `LayoutReconciler` instead of legacy `reconcileLayout()`
- **Changes**:
  1. Added `private let reconciler = LayoutReconciler()` property
  2. Updated `refreshItems()` to call `reconciler.reconcile()` instead of legacy method
  3. Removed legacy `reconcileLayout()` and `normalizeOrders()` methods
  4. Removed `LegacyReconciliationResult` struct
- **Status**: Completed - `LayoutReconciler` now handles section determination from captured icons with override support

### Task 8: Refactor reconcileLayout() - Order from Position [COMPLETED]
- **Action**: Already implemented in `LayoutReconciler.swift` lines 138-140
- **Status**: Completed - Order is assigned via `sectionOrderCounters` per section, not from saved layout

### Task 9: Update normalizeOrders() for New Algorithm [COMPLETED]
- **Action**: Already implemented in `LayoutReconciler.swift` lines 245-260
- **Status**: Completed - Normalization uses the same algorithm, now in `LayoutReconciler`

### Task 10: Verify Spec 5.6 Tests Pass [COMPLETED]
- **Action**: Ran full test suite
- **Result**: All 392 tests pass (6 skipped, 0 failed)
- **Status**: Completed

---

## Phase 3: Spec 5.7 - Repositioning Fix (Tasks 11-17)

**Goal**: Implement windowID caching and multi-tier icon matching.

### Task 11: Add windowIDCache State [COMPLETED]
- **File**: `Drawer/UI/Settings/SettingsMenuBarLayoutView.swift`
- **Action**: Added `@State private var windowIDCache: [UUID: CGWindowID] = [:]` at line 105
- **Status**: Completed

### Task 12: Update ReconciliationResult Struct [COMPLETED]
- **File**: `Drawer/UI/Settings/LayoutReconciler.swift`
- **Action**: `ReconciliationResult` struct already includes `windowIDCache` at line 21
- **Status**: Completed (already existed in `LayoutReconciler.swift`)

### Task 13: Populate windowIDCache in reconcileLayout() [COMPLETED]
- **File**: `Drawer/UI/Settings/LayoutReconciler.swift`
- **Action**: Lines 151-154 populate the cache during reconciliation
- **Status**: Completed (already implemented in `LayoutReconciler`)

### Task 14: Update refreshItems() to Use windowIDCache [COMPLETED]
- **File**: `Drawer/UI/Settings/SettingsMenuBarLayoutView.swift`
- **Action**: Line 644 now stores `reconciled.windowIDCache` to the state variable
- **Status**: Completed

### Task 15: Rewrite findIconItem() - Fast Path (WindowID)
- **File**: `Drawer/UI/Settings/SettingsMenuBarLayoutView.swift`
- **Lines**: 410-418
- **Action**:
  1. Check windowIDCache first for fast lookup
  2. If found, use `IconItem.find(byWindowID:)` or equivalent
  3. Add debug log: `[Match] Fast path: windowID \(id) found`
- **Scope**: Fast path implementation

### Task 16: Rewrite findIconItem() - Fallback Tiers
- **File**: `Drawer/UI/Settings/SettingsMenuBarLayoutView.swift`
- **Lines**: 410-418
- **Action**: Implement fallback chain:
  1. Tier 1: Exact match (bundle ID + title)
  2. Tier 2: Bundle ID match with empty/nil title
  3. Tier 3: Bundle ID match ignoring title
  4. Tier 4: Owner name match (for apps without bundle ID)
- **Scope**: Multi-tier matching logic

### Task 17: Verify Spec 5.7 Tests Pass
- **Action**: Run `testFindIconItem_*` tests
- **Expected**: All matching tests pass
- **Scope**: Test execution and any final fixes

---

## Phase 4: Integration & Verification (Tasks 18-19)

**Goal**: Full system verification.

### Task 18: Run Full Test Suite
- **Action**: Execute all tests in `DrawerTests/`
- **Command**: `XcodeBuildMCP_test_sim` or `XcodeBuildMCP_test_macos`
- **Expected**: All tests pass with no regressions

### Task 19: Manual Verification
- **Action**: Build and run app, verify:
  1. Click reload button - icons stay in same order (not switching)
  2. Cmd+drag icon in menu bar, click reload - new order reflected
  3. Drag icon to different section - section override preserved after reopen
  4. Drag icon between sections - physical movement occurs
  5. Control Center/Clock - show lock icon, cannot be dragged
- **Scope**: Manual testing per spec acceptance criteria

---

## Risk Assessment

| Risk | Mitigation |
|------|------------|
| CGWindowID may be stale | Multi-tier fallback ensures match even if windowID fails |
| Test isolation | Use mocks to avoid actual menu bar interaction in unit tests |
| Regression in existing functionality | Run full test suite after each phase |
| Debug logging performance | Use `os.log` with appropriate log levels (debug only) |

---

## Dependencies

```
Phase 1 (Tests) 
    └── Phase 2 (Spec 5.6) 
            └── Phase 3 (Spec 5.7) 
                    └── Phase 4 (Integration)
```

Phases must be completed in order. Tasks within each phase can be done sequentially.

---

## Files Modified

| File | Phases |
|------|--------|
| `Drawer/UI/Settings/SettingsMenuBarLayoutView.swift` | 2, 3 |
| `Drawer/UI/Settings/LayoutReconciler.swift` | 1 (new) |
| `Drawer/UI/Settings/IconMatcher.swift` | 1 (new) |
| `Drawer/Models/IconItem.swift` | 1 (modified - added test initializer) |
| `DrawerTests/UI/Settings/SettingsMenuBarLayoutViewTests.swift` | 1 (new) |
| `DrawerTests/Mocks/MockCapturedIconFactory.swift` | 1 (new) |

---

## Success Criteria

- [ ] All 4 ordering tests pass (Spec 5.6)
- [ ] All 3 matching tests pass (Spec 5.7)
- [ ] Full test suite passes with no regressions
- [ ] Manual verification confirms expected behavior
- [ ] Debug logging visible in Console.app when enabled
