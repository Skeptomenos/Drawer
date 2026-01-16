# Drawer Test Plan

## Progress Summary

| Priority | Category | Total | Done | Remaining | Progress |
|----------|----------|-------|------|-----------|----------|
| P0 | Test Infrastructure | 8 | 7 | 1 | 88% |
| P1 | Manager State Tests (CRITICAL) | 71 | 71 | 0 | 100% |
| P2 | Pure Logic Tests | 41 | 41 | 0 | 100% |
| P3 | Integration Tests | 40 | 10 | 30 | 25% |
| P4 | App Coordination Tests | 11 | 0 | 11 | 0% |
| **TOTAL** | | **171** | **129** | **42** | **75%** |

### Status Legend
- `[ ]` - Not started
- `[~]` - In progress
- `[x]` - Complete
- `[!]` - Blocked / Needs clarification

---

## Current State

- **Test Target**: Does not exist (needs to be created as `DrawerTests`)
- **Test Files**: None
- **Test Coverage**: 0%

---

## Test Structure

```
DrawerTests/
├── Core/
│   ├── Managers/
│   │   ├── MenuBarManagerTests.swift
│   │   ├── SettingsManagerTests.swift
│   │   ├── DrawerManagerTests.swift
│   │   ├── PermissionManagerTests.swift
│   │   ├── HoverManagerTests.swift
│   │   └── LaunchAtLoginManagerTests.swift
│   └── Engines/
│       └── IconCapturerTests.swift
├── Models/
│   ├── DrawerItemTests.swift
│   └── GlobalHotkeyConfigTests.swift
├── Utilities/
│   ├── EventSimulatorTests.swift
│   ├── WindowInfoTests.swift
│   ├── MenuBarMetricsTests.swift
│   └── GlobalEventMonitorTests.swift
├── App/
│   └── AppStateTests.swift
└── Mocks/
    ├── MockSettingsManager.swift
    ├── MockPermissionManager.swift
    ├── MockMenuBarManager.swift
    └── MockIconCapturer.swift
```

---

## 0. Priority 0: Test Infrastructure (PREREQUISITE)

> **MUST complete before any other tests.**

### 0.1 Test Target Setup

**File:** `DrawerTests/` target in Xcode project

| Status | Test ID | Test Case | Expected Result | Notes |
|--------|---------|-----------|-----------------|-------|
| [x] | SETUP-001 | Create DrawerTests target in Xcode project | Target exists and builds | Required for all tests |
| [x] | SETUP-002 | Configure test scheme for DrawerTests | Tests can be run via xcodebuild | |
| [x] | SETUP-003 | Create test directory structure | All directories from Test Structure exist | |

### 0.2 Mock Infrastructure

**Files:** `DrawerTests/Mocks/`

| Status | Test ID | Test Case | Expected Result | Notes |
|--------|---------|-----------|-----------------|-------|
| [x] | SETUP-004 | Create MockSettingsManager | Mock compiles and can be instantiated | |
| [x] | SETUP-005 | Create MockPermissionManager | Mock compiles and can be instantiated | |
| [x] | SETUP-006 | Create MockMenuBarManager | Mock compiles and can be instantiated | |
| [x] | SETUP-007 | Create MockIconCapturer | Mock compiles and can be instantiated | |

### 0.3 Test Verification

**File:** `DrawerTests/SetupVerificationTests.swift`

| Status | Test ID | Test Case | Expected Result | Notes |
|--------|---------|-----------|-----------------|-------|
| [x] | SETUP-008 | Verify test target runs | Simple assertion passes (1+1=2) | Smoke test |

---

## 1. Priority 1: Manager State Tests (CRITICAL)

> Core business logic validation. These tests verify the fundamental behavior of all managers.

### 1.1 MenuBarManager (`Drawer/Core/Managers/MenuBarManager.swift`)

**File:** `DrawerTests/Core/Managers/MenuBarManagerTests.swift`

| Status | Test ID | Test Case | Expected Result | Notes |
|--------|---------|-----------|-----------------|-------|
| [x] | MBM-001 | Initial state isCollapsed is true | isCollapsed == true on init | CRITICAL |
| [x] | MBM-002 | Initial state isToggling is false | isToggling == false on init | CRITICAL |
| [x] | MBM-003 | Toggle from collapsed expands | toggle() when collapsed sets isCollapsed=false | CRITICAL |
| [x] | MBM-004 | Toggle from expanded collapses | toggle() when expanded sets isCollapsed=true | CRITICAL |
| [x] | MBM-005 | Expand when already expanded is no-op | expand() when !isCollapsed does nothing | CRITICAL |
| [x] | MBM-006 | Collapse when already collapsed is no-op | collapse() when isCollapsed does nothing | CRITICAL |
| [x] | MBM-007 | isToggling prevents double toggle | Rapid toggle() calls are debounced | CRITICAL |
| [x] | MBM-008 | Expand sets correct separator length | Separator length is 20 after expand | HIGH |
| [x] | MBM-009 | Collapse sets correct separator length | Separator length is 10000 after collapse | HIGH |
| [x] | MBM-010 | Auto-collapse timer starts on expand | Timer starts when autoCollapseEnabled | HIGH |
| [x] | MBM-011 | Auto-collapse timer does not start when disabled | No timer when autoCollapseEnabled=false | HIGH |
| [x] | MBM-012 | Auto-collapse timer cancels on collapse | Timer cancelled on collapse | HIGH |
| [x] | MBM-013 | Auto-collapse timer restarts on settings change | Timer restarts when delay changes | MEDIUM |
| [x] | MBM-014 | Expand image is correct for LTR | chevron.left for LTR expand | MEDIUM |
| [x] | MBM-015 | Collapse image is correct for LTR | chevron.right for LTR collapse | MEDIUM |
| [x] | MBM-016 | Expand image is correct for RTL | chevron.right for RTL expand | MEDIUM |
| [x] | MBM-017 | Collapse image is correct for RTL | chevron.left for RTL collapse | MEDIUM |

### 1.2 SettingsManager (`Drawer/Core/Managers/SettingsManager.swift`)

**File:** `DrawerTests/Core/Managers/SettingsManagerTests.swift`

| Status | Test ID | Test Case | Expected Result | Notes |
|--------|---------|-----------|-----------------|-------|
| [x] | SET-001 | Default autoCollapseEnabled is true | autoCollapseEnabled == true | CRITICAL |
| [x] | SET-002 | Default autoCollapseDelay is 10.0 | autoCollapseDelay == 10.0 | CRITICAL |
| [x] | SET-003 | Default launchAtLogin is false | launchAtLogin == false | CRITICAL |
| [x] | SET-004 | Default hideSeparators is false | hideSeparators == false | CRITICAL |
| [x] | SET-005 | Default alwaysHiddenEnabled is false | alwaysHiddenEnabled == false | CRITICAL |
| [x] | SET-006 | Default useFullStatusBarOnExpand is false | useFullStatusBarOnExpand == false | CRITICAL |
| [x] | SET-007 | Default showOnHover is false | showOnHover == false | CRITICAL |
| [x] | SET-008 | Default hasCompletedOnboarding is false | hasCompletedOnboarding == false | CRITICAL |
| [x] | SET-009 | resetToDefaults restores all settings | All settings reset to defaults | CRITICAL |
| [x] | SET-010 | autoCollapseEnabled subject fires on change | Subject fires on change | HIGH |
| [x] | SET-011 | autoCollapseDelay subject fires on change | Subject fires on change | HIGH |
| [x] | SET-012 | showOnHover subject fires on change | Subject fires on change | HIGH |
| [x] | SET-013 | autoCollapseSettingsChanged publisher fires | Combined publisher fires | HIGH |
| [x] | SET-014 | globalHotkey get/set roundtrip | globalHotkey can be set and retrieved | MEDIUM |
| [x] | SET-015 | globalHotkey set nil removes from defaults | Setting nil removes key | MEDIUM |

### 1.3 DrawerManager (`Drawer/Core/Managers/DrawerManager.swift`)

**File:** `DrawerTests/Core/Managers/DrawerManagerTests.swift`

| Status | Test ID | Test Case | Expected Result | Notes |
|--------|---------|-----------|-----------------|-------|
| [x] | DRM-001 | Initial items is empty | items.isEmpty == true on init | CRITICAL |
| [x] | DRM-002 | Initial isVisible is false | isVisible == false on init | CRITICAL |
| [x] | DRM-003 | Initial isLoading is false | isLoading == false on init | CRITICAL |
| [x] | DRM-004 | Initial lastError is nil | lastError == nil on init | CRITICAL |
| [x] | DRM-005 | updateItems from MenuBarCaptureResult | Items updated from MenuBarCaptureResult | CRITICAL |
| [x] | DRM-006 | updateItems from [CapturedIcon] array | Items updated from [CapturedIcon] | CRITICAL |
| [x] | DRM-007 | updateItems clears lastError | lastError set to nil on update | HIGH |
| [x] | DRM-008 | clearItems removes all | clearItems() empties items array | CRITICAL |
| [x] | DRM-009 | clearItems clears lastError | clearItems() sets lastError to nil | HIGH |
| [x] | DRM-010 | setLoading(true) sets isLoading true | isLoading == true | HIGH |
| [x] | DRM-011 | setLoading(false) sets isLoading false | isLoading == false | HIGH |
| [x] | DRM-012 | setError stores error | Error is stored | HIGH |
| [x] | DRM-013 | setError(nil) clears error | Error is cleared | HIGH |
| [x] | DRM-014 | show() sets isVisible true | isVisible == true | CRITICAL |
| [x] | DRM-015 | hide() sets isVisible false | isVisible == false | CRITICAL |
| [x] | DRM-016 | toggle() from hidden shows | toggle() when hidden shows | CRITICAL |
| [x] | DRM-017 | toggle() from visible hides | toggle() when visible hides | CRITICAL |
| [x] | DRM-018 | hasItems true when not empty | hasItems returns true with items | HIGH |
| [x] | DRM-019 | hasItems false when empty | hasItems returns false when empty | HIGH |
| [x] | DRM-020 | itemCount returns correct count | itemCount matches items.count | HIGH |
| [x] | DRM-021 | isEmpty true when no items and not loading | isEmpty logic correct | HIGH |
| [x] | DRM-022 | isEmpty false when loading | isEmpty false during loading | HIGH |
| [x] | DRM-023 | isEmpty false when has items | isEmpty false with items | HIGH |

### 1.4 HoverManager (`Drawer/Core/Managers/HoverManager.swift`)

**File:** `DrawerTests/Core/Managers/HoverManagerTests.swift`

| Status | Test ID | Test Case | Expected Result | Notes |
|--------|---------|-----------|-----------------|-------|
| [x] | HVM-001 | Initial isMonitoring is false | isMonitoring == false on init | MEDIUM |
| [x] | HVM-002 | Initial isMouseInTriggerZone is false | isMouseInTriggerZone == false | MEDIUM |
| [x] | HVM-003 | Initial isMouseInDrawerArea is false | isMouseInDrawerArea == false | MEDIUM |
| [x] | HVM-004 | startMonitoring sets isMonitoring true | isMonitoring == true | MEDIUM |
| [x] | HVM-005 | stopMonitoring sets isMonitoring false | isMonitoring == false | MEDIUM |
| [x] | HVM-006 | startMonitoring twice is no-op | No multiple monitors created | MEDIUM |
| [x] | HVM-007 | updateDrawerFrame stores frame | Frame is stored | MEDIUM |
| [x] | HVM-008 | setDrawerVisible(true) works | Visibility set correctly | MEDIUM |
| [x] | HVM-009 | setDrawerVisible(false) clears mouse in drawer area | Mouse state cleared | MEDIUM |
| [x] | HVM-010 | isInMenuBarTriggerZone at top of screen | Point at screen top is in zone | MEDIUM |
| [x] | HVM-011 | isInMenuBarTriggerZone below menu bar | Point below menu bar is not in zone | MEDIUM |
| [x] | HVM-012 | isInDrawerArea inside frame | Point inside frame returns true | MEDIUM |
| [x] | HVM-013 | isInDrawerArea outside frame | Point outside frame returns false | MEDIUM |
| [x] | HVM-014 | isInDrawerArea with expanded hit area | 10px expansion works | MEDIUM |

### 1.5 LaunchAtLoginManager (`Drawer/Core/Managers/LaunchAtLoginManager.swift`)

**File:** `DrawerTests/Core/Managers/LaunchAtLoginManagerTests.swift`

| Status | Test ID | Test Case | Expected Result | Notes |
|--------|---------|-----------|-----------------|-------|
| [x] | LAL-001 | Initial lastError is nil | lastError == nil on init | MEDIUM |
| [x] | LAL-002 | refreshStatus updates isEnabled | refreshStatus() updates state | MEDIUM |

---

## 2. Priority 2: Pure Logic Tests (No Mocking Required)

> Simple unit tests for models and utilities with no external dependencies.

### 2.1 DrawerItem (`Drawer/Models/DrawerItem.swift`)

**File:** `DrawerTests/Models/DrawerItemTests.swift`

| Status | Test ID | Test Case | Expected Result | Notes |
|--------|---------|-----------|-----------------|-------|
| [x] | DRI-001 | Init from CapturedIcon | DrawerItem correctly initializes from CapturedIcon | LOW |
| [x] | DRI-002 | Init direct with image, frame, index | Direct initialization works | LOW |
| [x] | DRI-003 | clickTarget returns frame center | clickTarget returns CGPoint at frame center | LOW |
| [x] | DRI-004 | originalCenterX calculation | originalCenterX returns frame.midX | LOW |
| [x] | DRI-005 | originalCenterY calculation | originalCenterY returns frame.midY | LOW |
| [x] | DRI-006 | Equatable compares by ID | Two items with same ID are equal | LOW |
| [x] | DRI-007 | Equatable different IDs not equal | Two items with different IDs are not equal | LOW |
| [x] | DRI-008 | toDrawerItems extension converts correctly | [CapturedIcon].toDrawerItems() converts correctly | LOW |
| [x] | DRI-009 | toDrawerItems preserves order | Converted items maintain original order via index | LOW |
| [x] | DRI-010 | toDrawerItems empty array | Empty array returns empty result | LOW |

### 2.2 GlobalHotkeyConfig (`Drawer/Models/GlobalHotkeyConfig.swift`)

**File:** `DrawerTests/Models/GlobalHotkeyConfigTests.swift`

| Status | Test ID | Test Case | Expected Result | Notes |
|--------|---------|-----------|-----------------|-------|
| [x] | GHK-001 | Description with command modifier | Description shows ⌘ for command modifier | LOW |
| [x] | GHK-002 | Description with shift modifier | Description shows ⇧ for shift modifier | LOW |
| [x] | GHK-003 | Description with option modifier | Description shows ⌥ for option modifier | LOW |
| [x] | GHK-004 | Description with control modifier | Description shows ⌃ for control modifier | LOW |
| [x] | GHK-005 | Description with multiple modifiers | Correct order: Fn⌃⌥⌘⇧⇪ | LOW |
| [x] | GHK-006 | Description with return key | keyCode 36 shows ⏎ | LOW |
| [x] | GHK-007 | Description with delete key | keyCode 51 shows ⌫ | LOW |
| [x] | GHK-008 | Description with space key | keyCode 49 shows ⎵ | LOW |
| [x] | GHK-009 | Description with character | Characters are uppercased | LOW |
| [x] | GHK-010 | Encoding/decoding roundtrip | Codable roundtrip preserves all properties | LOW |
| [x] | GHK-011 | fromLegacy valid data | Legacy format conversion works | LOW |
| [x] | GHK-012 | fromLegacy invalid data | Invalid data returns nil | LOW |
| [x] | GHK-013 | Equatable | Two identical configs are equal | LOW |

### 2.3 CaptureError (`Drawer/Core/Engines/IconCapturer.swift`)

**File:** `DrawerTests/Core/Engines/CaptureErrorTests.swift`

| Status | Test ID | Test Case | Expected Result | Notes |
|--------|---------|-----------|-----------------|-------|
| [x] | CAP-001 | permissionDenied description | Error description correct | LOW |
| [x] | CAP-002 | menuBarNotFound description | Error description correct | LOW |
| [x] | CAP-003 | captureFailedNoImage description | Error description correct | LOW |
| [x] | CAP-004 | screenNotFound description | Error description correct | LOW |
| [x] | CAP-005 | invalidRegion description | Error description correct | LOW |
| [x] | CAP-006 | noMenuBarItems description | Error description correct | LOW |
| [x] | CAP-007 | systemError description includes wrapped error | Error description includes wrapped error | LOW |

### 2.4 EventSimulatorError (`Drawer/Utilities/EventSimulator.swift`)

**File:** `DrawerTests/Utilities/EventSimulatorErrorTests.swift`

| Status | Test ID | Test Case | Expected Result | Notes |
|--------|---------|-----------|-----------------|-------|
| [x] | ESE-001 | accessibilityNotGranted description | Error description correct | LOW |
| [x] | ESE-002 | eventCreationFailed description | Error description correct | LOW |
| [x] | ESE-003 | eventPostingFailed description | Error description correct | LOW |
| [x] | ESE-004 | invalidCoordinates description | Error description correct | LOW |

### 2.5 PermissionType (`Drawer/Core/Managers/PermissionManager.swift`)

**File:** `DrawerTests/Core/Managers/PermissionTypeTests.swift`

| Status | Test ID | Test Case | Expected Result | Notes |
|--------|---------|-----------|-----------------|-------|
| [x] | PRT-001 | Accessibility displayName | displayName is "Accessibility" | LOW |
| [x] | PRT-002 | ScreenRecording displayName | displayName is "Screen Recording" | LOW |
| [x] | PRT-003 | Accessibility description | Description text correct | LOW |
| [x] | PRT-004 | ScreenRecording description | Description text correct | LOW |
| [x] | PRT-005 | Accessibility systemSettingsURL | URL is correct | LOW |
| [x] | PRT-006 | ScreenRecording systemSettingsURL | URL is correct | LOW |
| [x] | PRT-007 | allCases includes both cases | CaseIterable includes both cases | LOW |

---

## 3. Priority 3: Integration Tests (Mocking Required)

> Tests that require mocking system APIs or external dependencies.

### 3.1 PermissionManager (`Drawer/Core/Managers/PermissionManager.swift`)

**File:** `DrawerTests/Core/Managers/PermissionManagerTests.swift`

| Status | Test ID | Test Case | Expected Result | Notes |
|--------|---------|-----------|-----------------|-------|
| [x] | PRM-001 | hasAccessibility returns correct value | Matches AXIsProcessTrusted | HIGH |
| [x] | PRM-002 | hasScreenRecording returns correct value | Matches CGPreflightScreenCaptureAccess | HIGH |
| [x] | PRM-003 | hasAllPermissions when both granted | hasAllPermissions logic correct | HIGH |
| [x] | PRM-004 | hasAllPermissions when one missing | hasAllPermissions returns false | HIGH |
| [x] | PRM-005 | isMissingPermissions is inverse | isMissingPermissions is inverse of hasAllPermissions | HIGH |
| [x] | PRM-006 | status for accessibility | status(for: .accessibility) returns correct status | HIGH |
| [x] | PRM-007 | status for screenRecording | status(for: .screenRecording) returns correct status | HIGH |
| [x] | PRM-008 | isGranted accessibility | isGranted(.accessibility) works | HIGH |
| [x] | PRM-009 | isGranted screenRecording | isGranted(.screenRecording) works | HIGH |
| [x] | PRM-010 | permissionStatusChanged publisher | Publisher fires on status change | MEDIUM |
| [ ] | PRM-011 | refreshAllStatuses updates published state | Refresh updates @Published properties | MEDIUM |

### 3.2 IconCapturer (`Drawer/Core/Engines/IconCapturer.swift`)

**File:** `DrawerTests/Core/Engines/IconCapturerTests.swift`

| Status | Test ID | Test Case | Expected Result | Notes |
|--------|---------|-----------|-----------------|-------|
| [ ] | ICN-001 | Initial isCapturing is false | isCapturing == false on init | HIGH |
| [ ] | ICN-002 | Initial lastCaptureResult is nil | lastCaptureResult == nil on init | HIGH |
| [ ] | ICN-003 | Initial lastError is nil | lastError == nil on init | HIGH |
| [ ] | ICN-004 | Capture without permission throws | permissionDenied error thrown | HIGH |
| [ ] | ICN-005 | clearLastCapture resets state | Clears both result and error | HIGH |
| [ ] | ICN-006 | sliceIconsUsingFixedWidth creates icons | Slicing algorithm creates icons | HIGH |
| [ ] | ICN-007 | sliceIconsUsingFixedWidth limits to 50 | Max 50 icons limit | MEDIUM |
| [ ] | ICN-008 | sliceIconsUsingFixedWidth correct spacing | 22px width + 4px spacing | MEDIUM |
| [ ] | ICN-009 | createCompositeImage from icons | Composite image creation works | MEDIUM |
| [ ] | ICN-010 | createCompositeImage empty returns nil | Empty icons returns nil | MEDIUM |
| [ ] | ICN-011 | Capture already in progress skips | Concurrent capture is prevented | MEDIUM |

### 3.3 EventSimulator (`Drawer/Utilities/EventSimulator.swift`)

**File:** `DrawerTests/Utilities/EventSimulatorTests.swift`

| Status | Test ID | Test Case | Expected Result | Notes |
|--------|---------|-----------|-----------------|-------|
| [ ] | EVS-001 | hasAccessibilityPermission returns correct value | Permission check works | HIGH |
| [ ] | EVS-002 | simulateClick without permission throws | accessibilityNotGranted error | HIGH |
| [ ] | EVS-003 | simulateClick with invalid coordinates throws | invalidCoordinates error | HIGH |
| [ ] | EVS-004 | isValidScreenPoint inside screen | Point inside screen returns true | HIGH |
| [ ] | EVS-005 | isValidScreenPoint outside all screens | Point outside returns false | HIGH |
| [ ] | EVS-006 | isValidScreenPoint in menu bar area | Menu bar area is valid | HIGH |
| [ ] | EVS-007 | saveCursorPosition returns current location | Cursor position saved | MEDIUM |
| [ ] | EVS-008 | convertToScreenCoordinates | Coordinate conversion works | MEDIUM |

### 3.4 GlobalEventMonitor (`Drawer/Utilities/GlobalEventMonitor.swift`)

**File:** `DrawerTests/Utilities/GlobalEventMonitorTests.swift`

| Status | Test ID | Test Case | Expected Result | Notes |
|--------|---------|-----------|-----------------|-------|
| [ ] | GEM-001 | Initial isRunning is false | isRunning == false on init | LOW |
| [ ] | GEM-002 | start sets isRunning true | start() sets isRunning=true | LOW |
| [ ] | GEM-003 | stop sets isRunning false | stop() sets isRunning=false | LOW |
| [ ] | GEM-004 | start twice is no-op | Double start doesn't create multiple monitors | LOW |
| [ ] | GEM-005 | stop when not running is no-op | Stop when not running is safe | LOW |
| [ ] | GEM-006 | deinit stops monitor | deinit calls stop | LOW |

### 3.5 LocalEventMonitor (`Drawer/Utilities/GlobalEventMonitor.swift`)

**File:** `DrawerTests/Utilities/LocalEventMonitorTests.swift`

| Status | Test ID | Test Case | Expected Result | Notes |
|--------|---------|-----------|-----------------|-------|
| [ ] | LEM-001 | Initial isRunning is false | isRunning == false on init | LOW |
| [ ] | LEM-002 | start sets isRunning true | start() sets isRunning=true | LOW |
| [ ] | LEM-003 | stop sets isRunning false | stop() sets isRunning=false | LOW |

### 3.6 WindowInfo (`Drawer/Utilities/WindowInfo.swift`)

**File:** `DrawerTests/Utilities/WindowInfoTests.swift`

| Status | Test ID | Test Case | Expected Result | Notes |
|--------|---------|-----------|-----------------|-------|
| [ ] | WIN-001 | isMenuBarItem with status window level | Layer check works | LOW |
| [ ] | WIN-002 | isMenuBarItem with other level | Non-status window returns false | LOW |
| [ ] | WIN-003 | init from dictionary valid data | Initialization from CFDictionary works | LOW |
| [ ] | WIN-004 | init from dictionary invalid data | nil returned for invalid data | LOW |

### 3.7 MenuBarMetrics (`Drawer/Utilities/MenuBarMetrics.swift`)

**File:** `DrawerTests/Utilities/MenuBarMetricsTests.swift`

| Status | Test ID | Test Case | Expected Result | Notes |
|--------|---------|-----------|-----------------|-------|
| [ ] | MBR-001 | fallbackHeight is 24 | fallbackHeight constant is 24 | LOW |
| [ ] | MBR-002 | height calculation | Height calculation from screen works | LOW |

---

## 4. Priority 4: App Coordination Tests

> Tests for the main app state coordinator.

### 4.1 AppState (`Drawer/App/AppState.swift`)

**File:** `DrawerTests/App/AppStateTests.swift`

| Status | Test ID | Test Case | Expected Result | Notes |
|--------|---------|-----------|-----------------|-------|
| [ ] | APP-001 | Initial isCollapsed is true | Initial state correct | HIGH |
| [ ] | APP-002 | Initial isDrawerVisible is false | Initial state correct | HIGH |
| [ ] | APP-003 | Initial isCapturing is false | Initial state correct | HIGH |
| [ ] | APP-004 | toggleMenuBar delegates to manager | Delegation works | HIGH |
| [ ] | APP-005 | toggleDrawer shows when hidden | Toggle logic correct | HIGH |
| [ ] | APP-006 | toggleDrawer hides when visible | Toggle logic correct | HIGH |
| [ ] | APP-007 | hideDrawer updates all state | Hide updates controller, manager, and flag | HIGH |
| [ ] | APP-008 | completeOnboarding sets flag | Onboarding completion works | MEDIUM |
| [ ] | APP-009 | hasCompletedOnboarding reads from settings | Settings integration works | MEDIUM |
| [ ] | APP-010 | Permission bindings update state | Permission status syncs | MEDIUM |
| [ ] | APP-011 | Hover bindings configured | Hover callbacks set up | MEDIUM |

---

## Mock Objects Required

### MockSettingsManager

```swift
@MainActor
final class MockSettingsManager: ObservableObject {
    var autoCollapseEnabled: Bool = true
    var autoCollapseDelay: Double = 10.0
    var launchAtLogin: Bool = false
    var showOnHover: Bool = false
    var hasCompletedOnboarding: Bool = false
    // ... other properties
}
```

### MockPermissionManager

```swift
@MainActor
final class MockPermissionManager: ObservableObject {
    var hasAccessibility: Bool = true
    var hasScreenRecording: Bool = true
    var hasAllPermissions: Bool { hasAccessibility && hasScreenRecording }
    
    var requestAccessibilityCalled = false
    var requestScreenRecordingCalled = false
}
```

### MockMenuBarManager

```swift
@MainActor
final class MockMenuBarManager: ObservableObject {
    @Published var isCollapsed: Bool = true
    @Published var isToggling: Bool = false
    
    var toggleCalled = false
    var expandCalled = false
    var collapseCalled = false
}
```

### MockIconCapturer

```swift
@MainActor
final class MockIconCapturer: ObservableObject {
    var isCapturing: Bool = false
    var shouldThrowError: CaptureError?
    var mockResult: MenuBarCaptureResult?
    
    func captureHiddenIcons(menuBarManager: MenuBarManager) async throws -> MenuBarCaptureResult {
        if let error = shouldThrowError { throw error }
        return mockResult!
    }
}
```

---

## Test Execution Commands

```bash
# Run all tests
xcodebuild test -scheme Drawer -destination 'platform=macOS'

# Run specific test class
xcodebuild test -scheme Drawer -destination 'platform=macOS' \
  -only-testing:DrawerTests/MenuBarManagerTests

# Run single test method
xcodebuild test -scheme Drawer -destination 'platform=macOS' \
  -only-testing:DrawerTests/MenuBarManagerTests/testToggleFromCollapsedExpands
```

---

## Summary

| Phase | Test Count | Priority | Estimated Effort |
|-------|------------|----------|------------------|
| Phase 0: Test Infrastructure | 8 tests | P0 | ~1 hour |
| Phase 1: Manager State | 55 tests | P1 (CRITICAL) | ~4 hours |
| Phase 2: Pure Logic | 35 tests | P2 | ~2 hours |
| Phase 3: Integration | 40 tests | P3 | ~6 hours |
| Phase 4: App Coordination | 11 tests | P4 | ~2 hours |
| **Total** | **149 tests** | - | **~15 hours** |

### Recommended Implementation Order

1. **P0**: Create `DrawerTests` target and mock infrastructure
2. **P1**: Implement Manager State tests (core business logic validation)
3. **P2**: Implement Pure Logic tests (quick wins, no dependencies)
4. **P3**: Implement Integration tests (system integration)
5. **P4**: Implement App Coordination tests
