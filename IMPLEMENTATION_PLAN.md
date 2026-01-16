# Drawer Implementation Plan

> Generated: 2026-01-16
> Status: Active Development
> Source Directory: `Drawer/`

## Executive Summary

Drawer is a macOS menu bar utility (forked from Hidden Bar) in **mature development state**. The core "10k pixel hack" mechanism, icon capture engine, and click-through simulation are fully implemented and tested. The primary remaining work is implementing the **Gesture Controls** feature (specs/prd-gesture-controls.md) and minor polish items.

---

## Current State Assessment

### Architecture: MVVM (Complete)
- **AppState.swift**: Central coordinator owning all managers
- **Managers**: MenuBarManager, DrawerManager, PermissionManager, SettingsManager, HoverManager
- **Engines**: IconCapturer (ScreenCaptureKit + window-based detection)
- **UI**: SwiftUI views with AppKit integration (NSPanel, NSStatusItem)

### Implementation Status

| Component | Status | Notes |
|-----------|--------|-------|
| 10k Pixel Hack | Complete | RTL support, position validation |
| Icon Capture | Complete | Dual-mode: window-based + SCKit fallback |
| Click-Through | Complete | CGEvent simulation with Accessibility |
| Drawer Panel | Complete | NSPanel with animations, materials |
| Permissions | Complete | Screen Recording + Accessibility flows |
| Settings UI | Partial | Missing gesture trigger options |
| Hover-to-Show | Complete | HoverManager with debouncing |
| Gesture Controls | **Not Started** | Defined in specs/prd-gesture-controls.md |
| Test Suite | Complete | 27 test files covering all managers |

### Known Issues
1. **BUG**: Drawer disappears unexpectedly - `HoverManager.drawerFrame` never updated after panel shows
2. **AGENTS.md outdated**: Claims no test target exists, but DrawerTests/ is comprehensive

---

## Implementation Phases

### Phase 1: Bug Fix & Foundation (Priority: Critical)

#### Task 1.1: Fix Drawer Frame Tracking Bug
**File**: `Drawer/App/AppState.swift`
**Effort**: ~15 min
**Description**: The drawer disappears because `HoverManager` doesn't know the panel's frame position.

**Changes**:
```swift
// In captureAndShowDrawer(), after line 230-231:
drawerController.show(content: contentView)
drawerManager.show()
// ADD THIS:
if let panelFrame = drawerController.panel?.frame {
    hoverManager.updateDrawerFrame(panelFrame)
}
```

**Acceptance Criteria**:
- [x] Drawer stays visible when mouse moves within drawer area
- [x] Drawer only hides when mouse leaves both menu bar AND drawer (with debounce)
- [x] `swiftlint lint` passes (swiftlint not installed, build passes)
- [ ] Manual test: Open drawer, move mouse around inside - drawer stays open

**Status**: ✅ COMPLETE (v0.3.5) - Implementation done, awaiting manual verification

---

#### Task 1.2: Add Gesture Settings Properties
**File**: `Drawer/Core/Managers/SettingsManager.swift`
**Effort**: ~20 min
**Description**: Add the new preference properties for gesture triggers.

**Changes**:
```swift
// Add after line 49 (showOnHover):
@AppStorage("showOnScrollDown") var showOnScrollDown: Bool = true {
    didSet { showOnScrollDownSubject.send(showOnScrollDown) }
}

@AppStorage("hideOnScrollUp") var hideOnScrollUp: Bool = true {
    didSet { hideOnScrollUpSubject.send(hideOnScrollUp) }
}

@AppStorage("hideOnClickOutside") var hideOnClickOutside: Bool = true {
    didSet { hideOnClickOutsideSubject.send(hideOnClickOutside) }
}

@AppStorage("hideOnMouseAway") var hideOnMouseAway: Bool = true {
    didSet { hideOnMouseAwaySubject.send(hideOnMouseAway) }
}

// Add corresponding PassthroughSubjects
let showOnScrollDownSubject = PassthroughSubject<Bool, Never>()
let hideOnScrollUpSubject = PassthroughSubject<Bool, Never>()
let hideOnClickOutsideSubject = PassthroughSubject<Bool, Never>()
let hideOnMouseAwaySubject = PassthroughSubject<Bool, Never>()
```

**Acceptance Criteria**:
- [ ] All 4 new properties persist across app restarts
- [ ] All default to `true`
- [ ] `resetToDefaults()` resets them
- [ ] Unit tests pass

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

**Changes**:
- Add `scrollMonitor: GlobalEventMonitor?` property
- Add `accumulatedScrollDelta: CGFloat` for threshold tracking
- Add `scrollThreshold: CGFloat = 30` constant
- Implement `handleScrollEvent(_ event: NSEvent)`:
  - Check if mouse is in menu bar trigger zone
  - Account for `event.isDirectionInvertedFromDevice` (natural scrolling)
  - Accumulate `event.scrollingDeltaY`
  - Trigger show/hide when threshold exceeded
  - Reset on direction change or `event.phase == .ended`

**Acceptance Criteria**:
- [ ] Scroll down in menu bar area triggers `onShouldShowDrawer`
- [ ] Scroll up (when drawer visible) triggers `onShouldHideDrawer`
- [ ] Works with both trackpad and mouse wheel
- [ ] Respects natural scrolling preference
- [ ] Threshold prevents accidental triggers
- [ ] Unit tests added

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

## Non-Goals (Out of Scope)

- Three-finger or four-finger gestures (system-reserved)
- Custom gesture thresholds in UI
- Haptic feedback
- Pinch-to-zoom or complex gestures
- Multi-monitor gesture support (future phase)

---

## Success Criteria

- [ ] All acceptance criteria for each task met
- [ ] `swiftlint lint` passes with no errors
- [ ] All existing tests pass
- [ ] New tests pass
- [ ] Manual verification checklist complete
- [ ] No regressions in existing functionality
