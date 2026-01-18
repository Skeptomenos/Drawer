# Drawer Phase 5: Drag-to-Reposition Implementation Plan

> Generated from specs/* analysis on 2026-01-18

## Overview

Phase 5 implements the ability to physically reposition menu bar icons by dragging them in the Settings > Menu Bar Layout view. The implementation uses CGEvent simulation (based on Ice's proven approach) to programmatically move icons.

**Goal**: Make the Settings UI the control surface for real menu bar repositioning.

## Current State

| Phase | Description | Status | Notes |
|-------|-------------|--------|-------|
| 5.1 | Core Models | **100%** | Complete - IconIdentifier & IconItem models + tests |
| 5.2 | Bridging Extensions | **100%** | getWindowList, getWindowFrame, activeSpaceID all exist |
| 5.3 | IconRepositioner Engine | **50%** | MouseCursor + Skeleton + CGEvent Move complete (3/6 tasks) |
| 5.4 | Settings UI Integration | 0% | Drag-drop UI exists but no repositioner hook |
| 5.5 | Persistence | 10% | Basic layout save exists, needs icon position persistence |

## Task List

### Phase 5.1: Core Models [COMPLETE]

Phase 5.1 is fully complete. The core models for icon identification and representation have been implemented and tested.

- **IconIdentifier**: `Drawer/Models/IconIdentifier.swift` - Identifies menu bar items by namespace/title
- **IconItem**: `Drawer/Models/IconItem.swift` - Full menu bar item representation with window info
- **Tests**: `DrawerTests/Models/MenuBarItemTests.swift` - 28 tests covering both models
- **Verification**: `xcodebuild test -scheme Drawer -only-testing:DrawerTests/MenuBarItemTests` - PASSED (28 tests)

---

### Phase 5.3: IconRepositioner Engine

#### Task 5.3.1: Create MouseCursor Utility [COMPLETE]
- **File**: `Drawer/Utilities/MouseCursor.swift` (new)
- **Scope**: Cursor management during repositioning
- **Details**:
  - Enum with static methods
  - `static var location: CGPoint?` - current cursor location
  - `static func hide()` - CGDisplayHideCursor
  - `static func show()` - CGDisplayShowCursor
  - `static func warp(to point: CGPoint)` - CGWarpMouseCursorPosition
- **Verification**: Build passed, committed as feat(5.3.1), tagged v0.5.1-alpha.4

#### Task 5.3.2: Create IconRepositioner Skeleton [COMPLETE]
- **File**: `Drawer/Core/Engines/IconRepositioner.swift`
- **Scope**: Core engine class structure and error types
- **Details**:
  - `RepositionError` enum with 7 cases and `LocalizedError` conformance
  - `MoveDestination` enum with `.leftOfItem`/`.rightOfItem` and `targetItem` property
  - `IconRepositioner` class: `@MainActor`, `final`, singleton pattern
  - Configuration constants: `maxRetries = 5`, `frameChangeTimeout = 50ms`, `frameChangePollInterval = 10ms`
  - `CGEventField.windowID` extension for undocumented field 0x33
  - Public method stub: `func move(item: IconItem, to destination: MoveDestination) async throws`
  - DEBUG testing support with `createForTesting()`
- **Verification**: Build passed, committed as feat(5.3.2), tagged v0.5.1-alpha.5

#### Task 5.3.3: Implement CGEvent Move Logic [COMPLETE]
- **File**: `Drawer/Core/Engines/IconRepositioner.swift` (modify)
- **Scope**: Core CGEvent simulation for Command+Drag
- **Details**:
  - `createMoveEvent(type:location:item:source:isDown:) -> CGEvent?`
    - Set `.maskCommand` flag on mouse down only
    - Set `.eventTargetUnixProcessID`, `.mouseEventWindowUnderMousePointer`
    - Set undocumented field 0x33 for windowID
  - `postEvent(_:to:)` - post to PID and session tap
  - `performMove(item:to:) throws` - execute single move attempt (sync for now)
  - `permitAllEvents(for:)` - configure event source permissions
  - `getEndPoint(for:) throws -> CGPoint` - calculate target position
  - `itemHasCorrectPosition(item:for:) throws -> Bool` - verify item is already positioned
  - Updated `move(item:to:)` to use new methods with basic implementation
- **Dependencies**: Task 5.3.2
- **Verification**: Build passed, 358 tests pass, committed as feat(5.3.3)

#### Task 5.3.4: Implement Frame Change Detection
- **File**: `Drawer/Core/Engines/IconRepositioner.swift` (modify)
- **Scope**: Verification that move succeeded
- **Details**:
  - `waitForFrameChange(of item: IconItem, initialFrame: CGRect) async throws`
    - Use `ContinuousClock` for timing
    - Poll every 10ms until frame differs from initial
    - Throw `.timeout` if 50ms deadline exceeded
    - Throw `.invalidItem` if frame cannot be retrieved
  - `itemHasCorrectPosition(item:for:) throws -> Bool` - verify final position
- **Dependencies**: Task 5.3.3
- **Verification**: `xcodebuild -scheme Drawer build`

#### Task 5.3.5: Implement Retry and Wake-Up Logic
- **File**: `Drawer/Core/Engines/IconRepositioner.swift` (modify)
- **Scope**: Reliability improvements for unresponsive apps
- **Details**:
  - `wakeUpItem(_:) async throws` - click without Command modifier
  - Complete `move(item:to:)` implementation:
    1. Check isMovable (throw .notMovable if false)
    2. Check if already in correct position (early return)
    3. Save cursor location, hide cursor
    4. Get initial frame
    5. Retry loop (up to 5 attempts):
       - performMove → waitForFrameChange
       - On failure: wakeUpItem → retry
    6. Restore cursor position and show cursor (via defer)
  - Add os.log logging for all operations
- **Dependencies**: Task 5.3.4
- **Verification**: `xcodebuild -scheme Drawer build`

#### Task 5.3.6: Create IconRepositioner Tests
- **File**: `DrawerTests/Engines/IconRepositionerTests.swift` (new)
- **Scope**: Unit tests for repositioner
- **Details**:
  - Test that immovable items throw `.notMovable` error
  - Test MoveDestination.targetItem computed property
  - Test RepositionError localized descriptions
  - Note: Actual CGEvent moves cannot be tested in unit tests (manual verification required)
- **Dependencies**: Task 5.3.5
- **Verification**: `xcodebuild test -scheme Drawer -only-testing:DrawerTests/IconRepositionerTests`

---

### Phase 5.4: Settings UI Integration

#### Task 5.4.1: Add Lock Indicators for Immovable Icons
- **File**: `Drawer/UI/Settings/SettingsMenuBarLayoutView.swift` (modify)
- **Scope**: Visual feedback for system icons
- **Details**:
  - Add lock icon (`lock.fill` SF Symbol, 8pt) in top-right corner of immovable items
  - Apply 50% opacity to immovable icons
  - Add tooltip: "This item cannot be moved by macOS"
  - Disable `.draggable()` modifier for immovable items
- **Dependencies**: Tasks 5.1.1, 5.1.2
- **Verification**: Build and run, verify Control Center shows lock icon

#### Task 5.4.2: Integrate Repositioner into Drop Handler
- **File**: `Drawer/UI/Settings/SettingsMenuBarLayoutView.swift` (modify)
- **Scope**: Connect drag-drop to real repositioning
- **Details**:
  - Create `performReposition(icon:toSection:atIndex:) async` method
  - Find IconItem matching dropped icon (by bundleIdentifier or ownerName)
  - Calculate destination using control items as section boundaries:
    - Visible section: right of `hiddenControlItem`
    - Hidden section: left of `hiddenControlItem`
    - Always Hidden: left of `alwaysHiddenControlItem`
  - Call `IconRepositioner.shared.move(item:to:)`
  - Trigger `iconCapturer.captureMenuBarIcons()` on success
- **Dependencies**: Tasks 5.3.5, 5.4.1
- **Verification**: Build and run, drag icon between sections

#### Task 5.4.3: Add Error Handling UI
- **File**: `Drawer/UI/Settings/SettingsMenuBarLayoutView.swift` (modify)
- **Scope**: User feedback on repositioning failures
- **Details**:
  - Create `showRepositionError(_ error: RepositionError)` method
  - Display NSAlert with warning style
  - Title: "Could Not Move Icon"
  - Body: Error's localizedDescription
  - Single "OK" button
- **Dependencies**: Task 5.4.2
- **Verification**: Build and run, test error handling (simulate failure)

---

### Phase 5.5: Persistence

#### Task 5.5.1: Add Icon Position Storage to SettingsManager
- **File**: `Drawer/Core/Managers/SettingsManager.swift` (modify)
- **Scope**: UserDefaults storage for icon positions
- **Details**:
  - Add `savedIconPositions: [String: [IconIdentifier]]` property
  - UserDefaults key: `menuBarIconPositions`
  - Add `loadIconPositions() -> [String: [IconIdentifier]]` method
  - Add private `saveIconPositions()` method (called from didSet)
  - Add `updateSavedPositions(for section: String, icons: [IconIdentifier])` method
  - Add `clearSavedPositions()` method
- **Dependencies**: Task 5.1.1
- **Verification**: `xcodebuild -scheme Drawer build`

#### Task 5.5.2: Create IconPositionRestorer
- **File**: `Drawer/Core/Managers/IconPositionRestorer.swift` (new)
- **Scope**: Restore saved positions on app launch
- **Details**:
  - `@MainActor` class with singleton pattern
  - Dependencies: SettingsManager, IconRepositioner
  - `restorePositions() async` - main restoration method
  - `restoreSection(_:) async` - per-section restoration
  - `isItemInSection(_:section:) -> Bool` - position verification
  - Process order: alwaysHidden -> hidden -> visible
  - 100ms pause between moves
  - Skip missing icons gracefully with logging
- **Dependencies**: Tasks 5.3.5, 5.5.1
- **Verification**: `xcodebuild -scheme Drawer build`

#### Task 5.5.3: Integrate Position Saving After Moves
- **File**: `Drawer/UI/Settings/SettingsMenuBarLayoutView.swift` (modify)
- **Scope**: Save positions after successful repositioning
- **Details**:
  - After successful `IconRepositioner.move()` call:
    - Get current menu bar items
    - Extract items for affected section
    - Convert to `[IconIdentifier]`
    - Call `settingsManager.updateSavedPositions(for:icons:)`
- **Dependencies**: Tasks 5.4.2, 5.5.1
- **Verification**: Move icon, check UserDefaults with `defaults read`

#### Task 5.5.4: Hook Position Restoration into App Launch
- **File**: `Drawer/App/AppDelegate.swift` (modify)
- **Scope**: Restore positions on app startup
- **Details**:
  - In `applicationDidFinishLaunching`:
    - Add 2-second delay (let menu bar stabilize)
    - Call `IconPositionRestorer.shared.restorePositions()` asynchronously
    - Non-blocking (use Task { })
- **Dependencies**: Task 5.5.2
- **Verification**: Arrange icons, quit, relaunch, verify positions restored

#### Task 5.5.5: Add Reset Positions Button
- **File**: `Drawer/UI/Settings/SettingsMenuBarLayoutView.swift` or `GeneralSettingsView.swift` (modify)
- **Scope**: Allow users to clear saved positions
- **Details**:
  - Add "Reset Icon Positions" button
  - Call `settingsManager.clearSavedPositions()` on click
  - Show confirmation or inline feedback
- **Dependencies**: Task 5.5.1
- **Verification**: Click reset, verify cleared with `defaults read`

#### Task 5.5.6: Add Persistence Tests
- **File**: `DrawerTests/Managers/SettingsManagerTests.swift` (modify)
- **Scope**: Test save/load round-trip
- **Details**:
  - `testSaveAndLoadPositions()` - verify round-trip persistence
  - `testClearPositions()` - verify reset functionality
- **Dependencies**: Task 5.5.1
- **Verification**: `xcodebuild test -scheme Drawer -only-testing:DrawerTests/SettingsManagerTests`

---

## Implementation Order (Recommended)

```
Phase 5.1: Core Models (Foundation) [COMPLETE]
└── IconIdentifier + IconItem models with 28 tests

Phase 5.3: IconRepositioner Engine (Core Logic)
├── 5.3.1 MouseCursor Utility
├── 5.3.2 IconRepositioner Skeleton
├── 5.3.3 CGEvent Move Logic
├── 5.3.4 Frame Change Detection
├── 5.3.5 Retry and Wake-Up Logic
└── 5.3.6 IconRepositioner Tests

Phase 5.4: Settings UI Integration (User-Facing)
├── 5.4.1 Lock Indicators for Immovable Icons
├── 5.4.2 Integrate Repositioner into Drop Handler
└── 5.4.3 Add Error Handling UI

Phase 5.5: Persistence (Polish)
├── 5.5.1 Icon Position Storage in SettingsManager
├── 5.5.2 IconPositionRestorer
├── 5.5.3 Integrate Position Saving After Moves
├── 5.5.4 Hook Position Restoration into App Launch
├── 5.5.5 Add Reset Positions Button
└── 5.5.6 Add Persistence Tests
```

## Success Criteria

- [ ] Dragging icon in Settings moves it in real menu bar
- [ ] Works for all three sections (Shown, Hidden, Always Hidden)
- [ ] Within-section reordering works
- [ ] System icons show lock and cannot be moved
- [ ] Positions persist across app restart
- [ ] 90%+ success rate for moves
- [ ] < 500ms per move operation

## Notes

- **Phase 5.1 is complete** - Core models implemented and tested (28 tests passing)
- **Phase 5.2 is already complete** - Bridging APIs exist and are tested

### Type Renaming (CRITICAL)

The spec-defined type names conflicted with existing types in `WindowInfo.swift`. The following renames were applied:

| Spec Name | Actual Name | File |
|-----------|-------------|------|
| `MenuBarItemInfo` | `IconIdentifier` | `Drawer/Models/IconIdentifier.swift` |
| `MenuBarItem` | `IconItem` | `Drawer/Models/IconItem.swift` |

Additional changes:
- The `info` property on `IconItem` was renamed to `identifier` to match the new type name
- The `find(matching:)` method now takes an `IconIdentifier` parameter
- This renaming was required to avoid conflicts with existing `MenuBarItem`/`MenuBarItemInfo` types in `WindowInfo.swift` used by the capture system

**All future tasks should use `IconIdentifier` and `IconItem` instead of the spec names.**

### Other Notes

- Existing `MenuBarItem`/`MenuBarItemInfo` in `WindowInfo.swift` are still used by capture system - do not modify
- New models in `Drawer/Models/` are spec-compliant and used only by repositioning system
- Manual testing required for CGEvent operations (cannot unit test actual moves)
