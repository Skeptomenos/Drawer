# Drawer Implementation Plan

> Generated: 2026-01-17
> Status: Active Development
> Source Directory: `Drawer/`

## Executive Summary

Drawer is a macOS menu bar utility (forked from Hidden Bar) in **mature development state**. The core "10k pixel hack" mechanism, icon capture engine, and click-through simulation are fully implemented and tested. The primary remaining work is implementing the **Gesture Controls** feature (specs/prd-gesture-controls.md).

**Active Focus:** Gesture Controls (Phases 1-5 below)
**Future Work:** Architecture improvements (see `docs/IMPLEMENTATION_PLAN_ARCHITECTURE_IMPROVEMENTS.md`), Always Hidden section, Overlay Mode

> **Related Documents:**
> - `docs/IMPLEMENTATION_PLAN_ARCHITECTURE_IMPROVEMENTS.md` - Detailed architecture refactor plan
> - `docs/ROOT_CAUSE_INVISIBLE_ICONS.md` - Phase 0 bug analysis and fix
> - `docs/ARCHITECTURE_COMPARISON.md` - Hidden Bar vs Ice analysis

---

## Specs Analysis Summary

| Spec File | Status | Priority (This Plan) | Priority (Arch Plan) |
|-----------|--------|----------------------|----------------------|
| `prd-gesture-controls.md` | **In Progress** | P0 - Active | N/A (Feature) |
| `phase1-reactive-state-binding.md` | Not Started | P3 - Future | P1 - High |
| `phase2a-core-models.md` | Not Started | P3 - Future | P1 - High |
| `phase2b-section-architecture.md` | Not Started | P3 - Future | P1-P2 |
| `phase2c-unit-tests.md` | Partial (26 tests exist) | P3 - Future | P2 |
| `phase3-always-hidden-section.md` | Partial (setting exists) | P3 - Future | P2 |
| `phase4a-overlay-panel-infrastructure.md` | Not Started | P4 - Future | P3 |
| `phase4b-overlay-mode-integration.md` | Not Started | P4 - Future | P3 |

> **Note:** This plan uses a "Feature-First" strategy - delivering user value (Gesture Controls) before refactoring. The "Arch Plan" column shows priorities from `docs/IMPLEMENTATION_PLAN_ARCHITECTURE_IMPROVEMENTS.md` for reference.

---

## Current State Assessment

### Architecture: MVVM (Working)
- **AppState.swift**: Central coordinator owning all managers
- **Managers**: MenuBarManager, DrawerManager, PermissionManager, SettingsManager, HoverManager
- **Engines**: IconCapturer (ScreenCaptureKit + window-based detection)
- **UI**: SwiftUI views with AppKit integration (NSPanel, NSStatusItem)

### Implementation Status

| Component | Status | Notes |
|-----------|--------|-------|
| 10k Pixel Hack | Complete | RTL support, position validation |
| Initial State Bug | **Fixed** | Phase 0 - separator now respects `isCollapsed` on startup |
| Icon Capture | Complete | Dual-mode: window-based + SCKit fallback |
| Click-Through | Complete | CGEvent simulation with Accessibility |
| Drawer Panel | Complete | NSPanel with animations, materials |
| Permissions | Complete | Screen Recording + Accessibility flows |
| Settings UI | Partial | Missing gesture trigger options |
| Hover-to-Show | Complete | HoverManager with debouncing |
| Gesture Controls | **In Progress** | Task 1.1-1.2, 2.2 complete, remaining tasks pending |
| Test Suite | Complete | 26 test files covering all managers |

### Known Issues
1. ~~**BUG**: Drawer disappears unexpectedly~~ - Fixed in Task 1.1 (v0.3.5)
2. ~~**BUG**: Initial state desync (separator 20px when isCollapsed=true)~~ - Fixed in Phase 0 (see `docs/ROOT_CAUSE_INVISIBLE_ICONS.md`)
3. **AGENTS.md outdated**: Claims no test target exists, but DrawerTests/ is comprehensive

---

## Implementation Phases

### Phase 1: Bug Fix & Foundation (Priority: Critical)

#### Task 1.1: Fix Drawer Frame Tracking Bug
**File**: `Drawer/App/AppState.swift`
**Effort**: ~15 min
**Description**: The drawer disappears because `HoverManager` doesn't know the panel's frame position.

**Changes**: Call `hoverManager.updateDrawerFrame()` after showing drawer.

**Verification**: Code confirmed at line 232:
```swift
hoverManager.updateDrawerFrame(drawerController.panelFrame)
```

**Acceptance Criteria**:
- [x] Drawer stays visible when mouse moves within drawer area
- [x] Drawer only hides when mouse leaves both menu bar AND drawer (with debounce)
- [x] Build passes
- [ ] Manual test: Open drawer, move mouse around inside - drawer stays open

**Status**: ✅ COMPLETE (v0.3.5) - Implementation done, awaiting manual verification

**Note**: The error path (lines 243-249) does not call `updateDrawerFrame()` when showing drawer with error state. Consider adding this for consistency.

---

#### Task 1.2: Add Gesture Settings Properties
**File**: `Drawer/Core/Managers/SettingsManager.swift`
**Effort**: ~20 min
**Description**: Add the new preference properties for gesture triggers.

**Implementation** (v0.3.6):
- Added 4 `@AppStorage` properties: `showOnScrollDown`, `hideOnScrollUp`, `hideOnClickOutside`, `hideOnMouseAway`
- Added 4 corresponding `PassthroughSubject` publishers for reactive bindings
- Updated `registerDefaults()` with all 4 settings defaulting to `true`
- Updated `resetToDefaults()` to reset all gesture settings

**Acceptance Criteria**:
- [x] All 4 new properties persist across app restarts
- [x] All default to `true`
- [x] `resetToDefaults()` resets them
- [x] Unit tests pass (211 tests, 0 failures)

**Status**: ✅ COMPLETE (v0.3.6)

---

### Phase 2: Gesture Infrastructure (Priority: High)

#### Task 2.1: Add Scroll Event Monitoring to GlobalEventMonitor
**File**: `Drawer/Utilities/GlobalEventMonitor.swift`
**Effort**: ~10 min
**Description**: The existing `GlobalEventMonitor` already supports any `NSEvent.EventTypeMask`. No code changes needed - just document that `.scrollWheel` is supported.

**Verification**:
- [ ] Confirm `GlobalEventMonitor(mask: .scrollWheel, handler:)` works
- [ ] Add test case in `GlobalEventMonitorTests.swift`

---

#### Task 2.2: Implement Scroll Gesture Detection in HoverManager
**File**: `Drawer/Core/Managers/HoverManager.swift`
**Effort**: ~45 min
**Description**: Extend HoverManager to detect scroll gestures in the menu bar zone.

**Implementation** (v0.3.7):
- Added `scrollMonitor: GlobalEventMonitor?` property
- Added `accumulatedScrollDelta: CGFloat` for threshold tracking
- Added `scrollThreshold: CGFloat = 30` constant
- Added `lastScrollDirection: ScrollDirection` enum for direction change detection
- Implemented `handleScrollEvent(_ event: NSEvent)`:
  - Checks if mouse is in menu bar trigger zone or drawer area
  - Accounts for `event.isDirectionInvertedFromDevice` (natural scrolling)
  - Accumulates `event.scrollingDeltaY` with direction-aware reset
  - Triggers show/hide when threshold exceeded
  - Resets on direction change or `event.phase == .ended/.cancelled`
- Wired scroll monitor into `startMonitoring()`/`stopMonitoring()`

**Acceptance Criteria**:
- [x] Scroll down in menu bar area triggers `onShouldShowDrawer`
- [x] Scroll up (when drawer visible) triggers `onShouldHideDrawer`
- [x] Works with both trackpad and mouse wheel
- [x] Respects natural scrolling preference
- [x] Threshold prevents accidental triggers
- [ ] Unit tests added (Task 5.1)

**Status**: ✅ COMPLETE (v0.3.7) - Implementation done, unit tests pending Task 5.1

---

#### Task 2.3: Implement Click-Outside Detection
**File**: `Drawer/Core/Managers/HoverManager.swift`
**Effort**: ~30 min
**Description**: Add global mouse click monitoring to dismiss drawer.

**Changes**:
- Add `clickMonitor: GlobalEventMonitor?` for `.leftMouseDown, .rightMouseDown`
- In handler: check if click is outside `drawerFrame`
- If outside and `hideOnClickOutside` enabled, trigger hide

**Acceptance Criteria**:
- [ ] Clicking outside drawer dismisses it
- [ ] Clicking inside drawer does NOT dismiss it
- [ ] Respects `hideOnClickOutside` setting
- [ ] Unit tests added

---

#### Task 2.4: Implement App Deactivation Detection
**File**: `Drawer/Core/Managers/HoverManager.swift`
**Effort**: ~20 min
**Description**: Hide drawer when user switches to another app.

**Changes**:
- Subscribe to `NSWorkspace.didDeactivateApplicationNotification`
- When received and `hideOnClickOutside` enabled, trigger hide

**Acceptance Criteria**:
- [ ] Cmd+Tab to another app hides drawer
- [ ] Clicking another app's window hides drawer
- [ ] Respects `hideOnClickOutside` setting

---

### Phase 3: Settings UI (Priority: Medium)

#### Task 3.1: Add Gesture Triggers Section to GeneralSettingsView
**File**: `Drawer/UI/Settings/GeneralSettingsView.swift`
**Effort**: ~30 min
**Description**: Add UI for configuring gesture triggers.

**UI Layout**:
```
Triggers
--------
Show Drawer when:
  [x] Hover over menu bar
  [x] Scroll down in menu bar

Hide Drawer when:
  [x] Scroll up
  [x] Click outside or switch apps
  [x] Move mouse away from drawer
```

**Acceptance Criteria**:
- [ ] All 5 toggles visible and functional
- [ ] Changes take effect immediately (no restart)
- [ ] Matches existing Settings UI style
- [ ] SwiftUI Preview works

---

### Phase 4: Integration & Polish (Priority: Medium)

#### Task 4.1: Wire Up Gesture Settings in AppState
**File**: `Drawer/App/AppState.swift`
**Effort**: ~30 min
**Description**: Update `setupHoverBindings()` to handle all gesture triggers.

**Changes**:
- Subscribe to all new settings subjects
- Start/stop appropriate monitors based on settings
- Ensure monitors are cleaned up properly

**Acceptance Criteria**:
- [ ] Toggling any setting immediately affects behavior
- [ ] No memory leaks (monitors properly stopped)
- [ ] All gesture combinations work correctly

---

#### Task 4.2: Update AGENTS.md Documentation
**File**: `AGENTS.md`
**Effort**: ~10 min
**Description**: Fix outdated documentation about test suite.

**Changes**:
- Update "Note: No test target exists yet" to reflect actual test suite
- Add reference to DrawerTests/ directory

---

### Phase 5: Testing & Verification (Priority: High)

#### Task 5.1: Add Unit Tests for Gesture Features
**Files**: `DrawerTests/Core/Managers/HoverManagerTests.swift`
**Effort**: ~45 min
**Description**: Comprehensive tests for new gesture functionality.

**Test Cases**:
- [ ] Scroll down triggers show when in menu bar zone
- [ ] Scroll up triggers hide when drawer visible
- [ ] Click outside triggers hide
- [ ] Click inside does NOT trigger hide
- [ ] Natural scrolling direction is respected
- [ ] Threshold accumulation works correctly
- [ ] Settings toggles enable/disable features

---

#### Task 5.2: Manual Verification Checklist
**Effort**: ~20 min

**Verification Steps**:
1. [ ] Build and run app
2. [ ] Swipe down with two fingers on menu bar - drawer opens
3. [ ] Swipe up - drawer closes
4. [ ] Click outside drawer - drawer closes
5. [ ] Cmd+Tab to another app - drawer closes
6. [ ] Hover over menu bar (if enabled) - drawer opens
7. [ ] Move mouse away from drawer - drawer closes
8. [ ] Toggle each setting in Preferences - behavior changes immediately
9. [ ] Quit and relaunch - settings persist
10. [ ] Test with natural scrolling ON and OFF

---

## Task Priority Matrix

| Priority | Task | Effort | Dependencies |
|----------|------|--------|--------------|
| P0 | 1.1 Fix Drawer Frame Bug | 15 min | None |
| P0 | 1.2 Add Settings Properties | 20 min | None |
| P1 | 2.2 Scroll Gesture Detection | 45 min | 1.2 |
| P1 | 2.3 Click-Outside Detection | 30 min | 1.2 |
| P1 | 2.4 App Deactivation Detection | 20 min | 1.2 |
| P2 | 3.1 Settings UI | 30 min | 1.2 |
| P2 | 4.1 Wire Up in AppState | 30 min | 2.2, 2.3, 2.4 |
| P3 | 4.2 Update AGENTS.md | 10 min | None |
| P1 | 5.1 Unit Tests | 45 min | 2.2, 2.3, 2.4 |
| P1 | 5.2 Manual Verification | 20 min | All above |

**Total Estimated Effort**: ~4.5 hours

---

## Implementation Order (Recommended)

1. **Task 1.1** - Fix bug (quick win, unblocks testing)
2. **Task 1.2** - Add settings properties (foundation)
3. **Task 2.2** - Scroll gesture detection (core feature)
4. **Task 2.3** - Click-outside detection
5. **Task 2.4** - App deactivation detection
6. **Task 3.1** - Settings UI (can parallel with 2.x)
7. **Task 4.1** - Wire up in AppState
8. **Task 5.1** - Unit tests
9. **Task 5.2** - Manual verification
10. **Task 4.2** - Update docs

---

## Files to Modify

| File | Tasks |
|------|-------|
| `Drawer/App/AppState.swift` | 1.1, 4.1 |
| `Drawer/Core/Managers/SettingsManager.swift` | 1.2 |
| `Drawer/Core/Managers/HoverManager.swift` | 2.2, 2.3, 2.4 |
| `Drawer/UI/Settings/GeneralSettingsView.swift` | 3.1 |
| `DrawerTests/Core/Managers/HoverManagerTests.swift` | 5.1 |
| `AGENTS.md` | 4.2 |

---

## Non-Goals (Out of Scope for Gesture Controls)

- Three-finger or four-finger gestures (system-reserved)
- Custom gesture thresholds in UI
- Haptic feedback
- Pinch-to-zoom or complex gestures
- Multi-monitor gesture support (future phase)

---

## Success Criteria (Gesture Controls)

- [ ] All acceptance criteria for each task met
- [ ] `swiftlint lint` passes with no errors
- [ ] All existing tests pass
- [ ] New tests pass
- [ ] Manual verification checklist complete
- [ ] No regressions in existing functionality

---

## Future Work: Architecture Improvements

The following specs define architecture improvements that would provide a cleaner foundation. These are **not blocking** current features but would reduce technical debt.

### Spec: phase1-reactive-state-binding.md
**Status:** Not Started | **Priority:** P3 | **Effort:** ~30 min

**Goal:** Add Combine-based reactive bindings to `MenuBarManager` so `isCollapsed` changes automatically update separator length and toggle image.

**Current State:** `MenuBarManager` uses manual state synchronization in `expand()`/`collapse()` methods with 3 assignments each.

**Tasks:**
- [ ] Add `setupStateBindings()` method with `$isCollapsed` Combine publisher
- [ ] Use `.dropFirst()` to skip initial value
- [ ] Simplify `expand()` to only set `isCollapsed = false`
- [ ] Simplify `collapse()` to only set `isCollapsed = true`
- [ ] Remove duplicate length/image assignments

**Files:** `Drawer/Core/Managers/MenuBarManager.swift`

---

### Spec: phase2a-core-models.md
**Status:** Not Started | **Priority:** P3 | **Effort:** ~30 min | **Depends on:** Phase 1

**Goal:** Create foundational `ControlItem` and `ControlItemImage` types that encapsulate NSStatusItem management.

**Current State:** No model files exist. Using raw `NSStatusItem` directly.

**Tasks:**
- [ ] Create `Drawer/Core/Models/` directory
- [ ] Create `ControlItemState.swift` - enum with `expanded`, `collapsed`, `hidden`
- [ ] Create `ControlItemImage.swift` - enum for SF Symbols, BezierPath, assets
- [ ] Create `ControlItem.swift` - `@MainActor` wrapper around `NSStatusItem` with reactive state

**Files to Create:**
- `Drawer/Core/Models/ControlItemState.swift`
- `Drawer/Core/Models/ControlItemImage.swift`
- `Drawer/Core/Models/ControlItem.swift`

---

### Spec: phase2b-section-architecture.md
**Status:** Not Started | **Priority:** P3 | **Effort:** ~40 min | **Depends on:** Phase 2A

**Goal:** Create `MenuBarSection` model and refactor `MenuBarManager` to use section-based architecture.

**Current State:** `MenuBarManager` uses raw `toggleItem`/`separatorItem` NSStatusItem properties.

**Tasks:**
- [ ] Create `MenuBarSection.swift` with `MenuBarSectionType` enum (`visible`, `hidden`, `alwaysHidden`)
- [ ] Refactor `MenuBarManager` to use `hiddenSection` and `visibleSection` properties
- [ ] Implement `setupSections()` method
- [ ] Add section-based state bindings

**Files:**
- Create: `Drawer/Core/Models/MenuBarSection.swift`
- Modify: `Drawer/Core/Managers/MenuBarManager.swift`

---

### Spec: phase2c-unit-tests.md
**Status:** Partial | **Priority:** P3 | **Effort:** ~30 min | **Depends on:** Phase 2A, 2B

**Goal:** Create unit tests for new architecture models.

**Current State:** 26 test files exist. Missing model tests for ControlItem/MenuBarSection.

**Tasks:**
- [ ] Create `ControlItemStateTests.swift`
- [ ] Create `ControlItemImageTests.swift`
- [ ] Create `ControlItemTests.swift`
- [ ] Create `MenuBarSectionTests.swift`
- [ ] Add Phase 0 regression test for initial separator length

**Files to Create:**
- `DrawerTests/Models/ControlItemStateTests.swift`
- `DrawerTests/Models/ControlItemImageTests.swift`
- `DrawerTests/Models/ControlItemTests.swift`
- `DrawerTests/Models/MenuBarSectionTests.swift`

---

## Future Work: Always Hidden Section

### Spec: phase3-always-hidden-section.md
**Status:** Partial | **Priority:** P3 | **Effort:** ~45 min | **Depends on:** Phase 2B

**Goal:** Add a third menu bar section for icons that are NEVER visible in the menu bar, only in the Drawer panel.

**Current State:**
- `alwaysHiddenEnabled` setting EXISTS in SettingsManager (line 42)
- Third separator NOT implemented
- Section headers in Drawer NOT implemented
- Settings UI toggle NOT implemented

**Tasks:**
- [ ] Create third separator with distinct icon (`line.3.horizontal`)
- [ ] Third separator never expands (always 10k length)
- [ ] Add section detection in IconCapturer based on X position
- [ ] Add `sectionType` property to DrawerItem
- [ ] Add section headers to DrawerContentView
- [ ] Add toggle in GeneralSettingsView "Advanced" section

**Files:**
- `Drawer/Core/Managers/MenuBarManager.swift`
- `Drawer/Core/Engines/IconCapturer.swift`
- `Drawer/Models/DrawerItem.swift`
- `Drawer/UI/Panels/DrawerContentView.swift`
- `Drawer/UI/Settings/GeneralSettingsView.swift`

---

## Future Work: Overlay Mode

### Spec: phase4a-overlay-panel-infrastructure.md
**Status:** Not Started | **Priority:** P4 | **Effort:** ~40 min

**Goal:** Create infrastructure for "Overlay Mode" - floating NSPanel at menu bar level as alternative to expand mode. Solves MacBook Notch problem.

**Current State:** `UI/Overlay/` directory does not exist. No overlay components implemented.

**Tasks:**
- [ ] Create `Drawer/UI/Overlay/` directory
- [ ] Create `OverlayPanel.swift` - NSPanel at menu bar level
- [ ] Create `OverlayContentView.swift` - Horizontal icon strip (SwiftUI)
- [ ] Create `OverlayPanelController.swift` - Lifecycle management
- [ ] Add `overlayModeEnabled` setting to SettingsManager

**Files to Create:**
- `Drawer/UI/Overlay/OverlayPanel.swift`
- `Drawer/UI/Overlay/OverlayContentView.swift`
- `Drawer/UI/Overlay/OverlayPanelController.swift`

---

### Spec: phase4b-overlay-mode-integration.md
**Status:** Not Started | **Priority:** P4 | **Effort:** ~45 min | **Depends on:** Phase 4A

**Goal:** Integrate Overlay Panel with toggle flow, IconCapturer, and EventSimulator.

**Current State:** No overlay integration exists.

**Tasks:**
- [ ] Create `OverlayModeManager.swift` to orchestrate overlay flow
- [ ] Modify `AppState.toggleMenuBar()` to respect overlay mode setting
- [ ] Add `onTogglePressed` callback to MenuBarManager
- [ ] Add radio picker in GeneralSettingsView for expand vs overlay mode

**Files:**
- Create: `Drawer/Core/Managers/OverlayModeManager.swift`
- Modify: `Drawer/App/AppState.swift`
- Modify: `Drawer/Core/Managers/MenuBarManager.swift`
- Modify: `Drawer/UI/Settings/GeneralSettingsView.swift`

---

## Architecture Decision: Why Gesture Controls First?

The current plan prioritizes **Gesture Controls** over architecture improvements because:

1. **User Value:** Gesture controls provide immediate UX improvements
2. **Working Code:** The current architecture functions correctly despite lacking elegance
3. **Risk Mitigation:** Architecture refactors could introduce regressions
4. **Incremental Delivery:** Complete features before refactoring

The architecture phases (1, 2A, 2B, 2C) can be tackled after gesture controls are complete, as a focused refactoring effort with proper test coverage.

---

## Relationship Between Planning Documents

| Document | Focus | Use When |
|----------|-------|----------|
| **This file** (`IMPLEMENTATION_PLAN.md`) | Active development roadmap, Gesture Controls | Day-to-day implementation tasks |
| `docs/IMPLEMENTATION_PLAN_ARCHITECTURE_IMPROVEMENTS.md` | Architecture refactoring strategy | Planning Section-based refactor |
| `specs/prd-gesture-controls.md` | Gesture feature requirements | Understanding gesture UX goals |
| `specs/phase*.md` | Detailed implementation specs | Executing specific architecture tasks |

**Execution Strategy:**
1. Complete Gesture Controls (this plan, Phases 1-5)
2. Verify and stabilize
3. Begin Architecture Improvements (phase1 → phase2c)
4. Implement Always Hidden (phase3)
5. Implement Overlay Mode (phase4a → phase4b)
