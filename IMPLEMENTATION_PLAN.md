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
| 5.3 | IconRepositioner Engine | **100%** | All tasks complete: MouseCursor, Skeleton, CGEvent Move, Frame Detection, Retry/Wake-Up, Tests |
| 5.4 | Settings UI Integration | **100%** | All tasks complete (5.4.1-5.4.3) |
| 5.5 | Persistence | 50% | Tasks 5.5.1-5.5.3 complete - SettingsManager storage + IconPositionRestorer + Position Saving |

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

#### Task 5.3.4: Implement Frame Change Detection [COMPLETE]
- **File**: `Drawer/Core/Engines/IconRepositioner.swift` (modify)
- **Scope**: Verification that move succeeded
- **Details**:
  - `waitForFrameChange(of item: IconItem, initialFrame: CGRect) async throws`
    - Uses `ContinuousClock` for timing
    - Polls every 10ms (`frameChangePollInterval`) until frame differs from initial
    - Throws `.timeout` if 50ms (`frameChangeTimeout`) deadline exceeded
    - Throws `.invalidItem` if frame cannot be retrieved
  - `performMove` updated to be async and call `waitForFrameChange` after both mouse down and mouse up events
  - `itemHasCorrectPosition(item:for:) throws -> Bool` - verify final position (already existed)
- **Dependencies**: Task 5.3.3
- **Verification**: Build passed, 358 tests pass, committed as feat(5.3.4), tagged v0.5.1-alpha.7

#### Task 5.3.5: Implement Retry and Wake-Up Logic [COMPLETE]
- **File**: `Drawer/Core/Engines/IconRepositioner.swift` (modify)
- **Scope**: Reliability improvements for unresponsive apps
- **Details**:
  - `wakeUpItem(_:) async throws` - click without Command modifier to wake unresponsive apps
  - Complete `move(item:to:)` implementation with retry loop:
    1. Check isMovable (throw .notMovable if false)
    2. Check if already in correct position (early return)
    3. Save cursor location, hide cursor
    4. Get initial frame
    5. Retry loop (up to 5 attempts):
       - performMove → waitForFrameChange
       - On failure: wakeUpItem → retry
    6. Restore cursor position and show cursor (via defer)
  - Full os.log logging for all operations (info, debug, warning, error levels)
- **Dependencies**: Task 5.3.4
- **Verification**: Build passed, 358 tests pass, committed as feat(5.3.5), tagged v0.5.1-alpha.8

#### Task 5.3.6: Create IconRepositioner Tests [COMPLETE]
- **File**: `DrawerTests/Core/Engines/IconRepositionerTests.swift`
- **Scope**: Unit tests for repositioner
- **Details**:
  - Test that immovable items throw `.notMovable` error
  - Test MoveDestination.targetItem computed property
  - Test RepositionError localized descriptions (all 7 cases)
  - Test singleton pattern and createForTesting()
  - Note: Actual CGEvent moves cannot be tested in unit tests (manual verification required)
- **Dependencies**: Task 5.3.5
- **Verification**: `xcodebuild test -scheme Drawer -only-testing:DrawerTests/IconRepositionerTests` - PASSED (14 tests)
- **Note**: Also added IconRepositioner.swift and MouseCursor.swift to Xcode project (they were on filesystem but not in project)

---

### Phase 5.4: Settings UI Integration

#### Task 5.4.1: Add Lock Indicators for Immovable Icons [COMPLETE]
- **Files Modified**:
  - `Drawer/Models/SettingsLayoutItem.swift` - Added `isImmovable` computed property
  - `Drawer/UI/Settings/SettingsMenuBarLayoutView.swift` - Updated `LayoutItemView` and `LayoutSectionView`
- **Scope**: Visual feedback for system icons
- **Details**:
  - Added `isImmovable` property to `SettingsLayoutItem` using `IconIdentifier.immovableItems`
  - Added lock icon (`lock.fill` SF Symbol, 8pt) in top-trailing corner of immovable items
  - Applied 50% opacity to immovable icons
  - Added tooltip: "This item cannot be moved by macOS"
  - Added `itemView(for:)` method to conditionally apply `.draggable()` for movable items only
  - Added 8 unit tests for `isImmovable` property (SLI-041 to SLI-048)
- **Dependencies**: Tasks 5.1.1, 5.1.2
- **Verification**: Build passed, 380 tests pass (8 new tests added)

#### Task 5.4.2: Integrate Repositioner into Drop Handler [COMPLETE]
- **File**: `Drawer/UI/Settings/SettingsMenuBarLayoutView.swift` (modified)
- **Scope**: Connect drag-drop to real repositioning
- **Details**:
  - Added `performReposition(item:to:at:) async` method that triggers physical repositioning
  - Added `findIconItem(for:)` to match SettingsLayoutItem to IconItem via IconIdentifier
  - Added `calculateDestination(for:at:excludingItem:)` to compute MoveDestination based on:
    - Section boundaries defined by `hiddenControlItem` and `alwaysHiddenControlItem`
    - Insert position within the section
  - Added `getSectionItems(for:from:...)` helper to filter items by section based on X position
  - Added `showRepositionError(_:)` to display NSAlert on failure (basic error UI)
  - Modified `moveItem(_:to:at:)` to trigger `performReposition` in a Task for non-spacer, movable items
  - Added safe array subscript extension for bounds-safe access
  - Calls `IconRepositioner.shared.move(item:to:)` and refreshes icons on success
- **Dependencies**: Tasks 5.3.5, 5.4.1
- **Verification**: Build passed, 380 tests pass

#### Task 5.4.3: Add Error Handling UI [COMPLETE]
- **File**: `Drawer/UI/Settings/SettingsMenuBarLayoutView.swift` (modified)
- **Scope**: User feedback on repositioning failures
- **Details**:
  - `showRepositionError(_ error: RepositionError)` method (lines 534-542)
  - NSAlert with `.warning` style
  - Title: "Could Not Move Icon"
  - Body: `error.localizedDescription`
  - Single "OK" button via `.runModal()`
  - Called from `performReposition` catch block (line 375)
- **Dependencies**: Task 5.4.2
- **Verification**: Build passed, 380 tests pass
- **Note**: Implementation was added as part of Task 5.4.2 since error handling is integral to the drop handler integration

---

### Phase 5.5: Persistence

#### Task 5.5.1: Add Icon Position Storage to SettingsManager [COMPLETE]
- **File**: `Drawer/Core/Managers/SettingsManager.swift` (modified)
- **Scope**: UserDefaults storage for icon positions
- **Details**:
  - Added `savedIconPositions: [String: [IconIdentifier]]` computed property
  - UserDefaults key: `menuBarIconPositions` (via `iconPositionsStorageKey`)
  - Added `loadIconPositions() -> [String: [IconIdentifier]]` method
  - Saving is handled by computed property setter (follows existing `menuBarLayout` pattern)
  - Added `updateSavedPositions(for section: MenuBarSectionType, icons: [IconIdentifier])` method
  - Added `clearSavedPositions()` method
  - Added `iconPositionsChangedSubject` for Combine integration
  - Added `Codable` conformance to `MenuBarSectionType` enum (removed redundant extension from SettingsLayoutItem.swift)
- **Dependencies**: Task 5.1.1
- **Verification**: Build passed, 380 tests pass

#### Task 5.5.2: Create IconPositionRestorer [COMPLETE]
- **File**: `Drawer/Core/Managers/IconPositionRestorer.swift`
- **Scope**: Restore saved positions on app launch
- **Details**:
  - `@MainActor final class` with singleton pattern (`IconPositionRestorer.shared`)
  - Dependency injection: `init(settingsManager:repositioner:)` with defaults
  - `restorePositions() async` - main restoration method:
    - Loads saved positions from SettingsManager
    - Gets current menu bar items via `IconItem.getMenuBarItems()`
    - Finds control items for section boundary detection
    - Restores sections in order: alwaysHidden → hidden → visible
  - `restoreSection(_:savedIcons:targetItem:destination:currentItems:) async` - per-section restoration:
    - Skips immovable items
    - Finds IconItem for each saved IconIdentifier
    - Checks if already in correct section
    - Moves via IconRepositioner with 100ms delay between moves
  - `isItemInSection(_:section:currentItems:) -> Bool` - position verification using control item X positions
  - Full os.log logging (info, debug, warning levels)
  - Graceful degradation: missing icons logged and skipped, failed moves logged but don't stop process
- **Dependencies**: Tasks 5.3.5, 5.5.1
- **Verification**: Build passed, 380 tests pass

#### Task 5.5.3: Integrate Position Saving After Moves [COMPLETE]
- **File**: `Drawer/UI/Settings/SettingsMenuBarLayoutView.swift` (modified)
- **Scope**: Save positions after successful repositioning
- **Details**:
  - Added `saveCurrentPositions(for:) async` method (lines 546-588):
    - 100ms delay to let menu bar settle after move
    - Gets current menu bar items via `IconItem.getMenuBarItems()`
    - Finds control items for section boundary detection
    - Iterates all sections (visible, hidden, alwaysHidden)
    - Extracts IconItems per section using existing `getSectionItems(for:from:...)` helper
    - Converts to `[IconIdentifier]` (left-to-right order)
    - Saves via `SettingsManager.shared.updateSavedPositions(for:icons:)`
  - Modified `performReposition` to call `saveCurrentPositions` after successful move (line 372)
- **Dependencies**: Tasks 5.4.2, 5.5.1
- **Verification**: Build passed, 380 tests pass, committed as feat(5.5.3), tagged v0.5.1-alpha.15

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
