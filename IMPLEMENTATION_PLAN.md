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

### Task 4: Write Icon Matching Tests (Spec 5.7)
- **File**: `DrawerTests/UI/Settings/SettingsMenuBarLayoutViewTests.swift`  
- **Action**: Implement tests:
  - `testFindIconItem_UsesWindowIDCache()` - Verifies windowID cache is used first
  - `testFindIconItem_FallsBackToBundleID()` - Verifies fallback matching
  - `testFindIconItem_ReturnsNilForSpacers()` - Verifies spacer handling
- **Expected**: Tests will fail until Phase 3 implementation

---

## Phase 2: Spec 5.6 - Ordering Fix (Tasks 5-10)

**Goal**: Fix `reconcileLayout()` to use captured X-positions as source of truth.

### Task 5: Add Debug Logger for Layout View
- **File**: `Drawer/UI/Settings/SettingsMenuBarLayoutView.swift`
- **Action**: Add `os.log` subsystem/category for layout debugging
- **Scope**: Logger setup only

### Task 6: Refactor reconcileLayout() - Sort by X-Position
- **File**: `Drawer/UI/Settings/SettingsMenuBarLayoutView.swift`
- **Lines**: 667-680
- **Action**: 
  1. Sort `capturedIcons` by `originalFrame.minX` at start of function
  2. Add debug log: `[Layout] Sorted \(count) icons by X-position`
- **Scope**: Add sorting before main loop

### Task 7: Refactor reconcileLayout() - Section from Capture
- **File**: `Drawer/UI/Settings/SettingsMenuBarLayoutView.swift`
- **Lines**: 680-710
- **Action**:
  1. Determine section from captured icon's position relative to separators
  2. Check saved layout ONLY for section overrides (user moved item)
  3. Add debug log: `[Layout] Icon \(id): captured=\(section), override=\(hasOverride)`
- **Scope**: Section determination logic

### Task 8: Refactor reconcileLayout() - Order from Position
- **File**: `Drawer/UI/Settings/SettingsMenuBarLayoutView.swift`
- **Lines**: 686-707
- **Action**:
  1. Assign `order` based on position within each section (not saved order)
  2. Track order per section: `sectionOrderCounters: [SectionType: Int]`
  3. Add debug log: `[Layout] Icon \(id): order=\(order) in section \(section)`
- **Scope**: Order assignment logic

### Task 9: Update normalizeOrders() for New Algorithm
- **File**: `Drawer/UI/Settings/SettingsMenuBarLayoutView.swift`
- **Lines**: 728-743
- **Action**: Verify normalization works with new ordering approach
- **Scope**: Validation and potential adjustment

### Task 10: Verify Spec 5.6 Tests Pass
- **Action**: Run `testReconcileLayout_*` tests
- **Expected**: All ordering tests pass
- **Scope**: Test execution and any final fixes

---

## Phase 3: Spec 5.7 - Repositioning Fix (Tasks 11-17)

**Goal**: Implement windowID caching and multi-tier icon matching.

### Task 11: Add windowIDCache State
- **File**: `Drawer/UI/Settings/SettingsMenuBarLayoutView.swift`
- **Lines**: 86-92
- **Action**: Add `@State private var windowIDCache: [UUID: CGWindowID] = [:]`
- **Scope**: State variable addition

### Task 12: Update ReconciliationResult Struct
- **File**: `Drawer/UI/Settings/SettingsMenuBarLayoutView.swift`
- **Lines**: 17-26
- **Action**: Add `let windowIDCache: [UUID: CGWindowID]` to struct
- **Scope**: Struct modification

### Task 13: Populate windowIDCache in reconcileLayout()
- **File**: `Drawer/UI/Settings/SettingsMenuBarLayoutView.swift`
- **Lines**: 667-724
- **Action**:
  1. Extract `windowID` from `capturedIcon.itemInfo?.windowID`
  2. Map layout item UUID to window ID
  3. Return populated cache in `ReconciliationResult`
- **Scope**: Cache population logic

### Task 14: Update refreshItems() to Use windowIDCache
- **File**: `Drawer/UI/Settings/SettingsMenuBarLayoutView.swift`
- **Lines**: 632-635
- **Action**: Extract and store windowIDCache from reconciliation result
- **Scope**: Result handling update

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
| `DrawerTests/UI/Settings/SettingsMenuBarLayoutViewTests.swift` | 1 (new) |
| `DrawerTests/Mocks/MockCapturedIconFactory.swift` | 1 (new) |

---

## Success Criteria

- [ ] All 4 ordering tests pass (Spec 5.6)
- [ ] All 3 matching tests pass (Spec 5.7)
- [ ] Full test suite passes with no regressions
- [ ] Manual verification confirms expected behavior
- [ ] Debug logging visible in Console.app when enabled
