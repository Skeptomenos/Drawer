# PRD: Drag-to-Reposition Menu Bar Icons

## Introduction

Enable users to physically reposition menu bar icons by dragging them in the Settings > Menu Bar Layout view. When a user moves an icon from one section to another (e.g., from "Hidden Items" to "Shown Items") or reorders icons within a section, the actual macOS menu bar reflects this change immediately.

This feature solves a critical usability issue: the current Settings UI allows users to organize icons visually, but changes are purely cosmetic and don't affect the real menu bar. Users expect drag-and-drop to work as advertised.

### Problem Statement

The "Always Hidden" section is currently broken because:
1. A 10,000px spacer pushes icons off-screen permanently
2. Users cannot physically Command+Drag icons past an invisible spacer
3. The Settings UI appears to let users organize icons, but nothing actually moves

This feature makes the Settings UI the **control surface** for real menu bar repositioning.

## Goals

- Move menu bar icons between sections (Shown, Hidden, Always Hidden) via Settings drag-and-drop
- Reorder icons within the same section via Settings drag-and-drop
- Persist user's preferred icon positions across app restarts
- Provide clear feedback when repositioning fails or when icons are immovable
- Achieve 90%+ success rate for repositioning attempts
- Complete repositioning within 500ms (perceived instant)

## User Stories

### US-001: Create MenuBarItem Model
**Description:** As a developer, I need a model representing menu bar items with their window IDs so I can target them for repositioning.

**Acceptance Criteria:**
- [ ] Create `MenuBarItem.swift` in `Drawer/Models/`
- [ ] Properties: `windowID: CGWindowID`, `frame: CGRect`, `ownerPID: pid_t`, `ownerName: String?`, `title: String?`, `isMovable: Bool`
- [ ] Static method `getMenuBarItems(onScreenOnly:activeSpaceOnly:)` returns all menu bar items
- [ ] Items sorted by X position (left to right)
- [ ] `isMovable` returns false for system items (Control Center, Clock, Siri)
- [ ] Typecheck passes with `xcodebuild -scheme Drawer build`

### US-002: Create MenuBarItemInfo Model
**Description:** As a developer, I need a way to uniquely identify menu bar items across captures so I can track them reliably.

**Acceptance Criteria:**
- [ ] Create `MenuBarItemInfo.swift` in `Drawer/Models/`
- [ ] Properties: `namespace: String` (bundle identifier), `title: String`
- [ ] Conforms to `Hashable` and `Equatable`
- [ ] Static properties for known control items: `.hiddenControlItem`, `.alwaysHiddenControlItem`
- [ ] Static property `immovableItems` listing system items that cannot be moved
- [ ] Typecheck passes

### US-003: Extend Bridging for Window Operations
**Description:** As a developer, I need low-level window APIs to get menu bar item windows and their frames.

**Acceptance Criteria:**
- [ ] Add `getWindowFrame(for windowID: CGWindowID) -> CGRect?` to `Bridging.swift`
- [ ] Add `getMenuBarWindowList() -> [CGWindowID]` to get all menu bar item windows
- [ ] Add `isWindowOnActiveSpace(_ windowID: CGWindowID) -> Bool`
- [ ] All functions use existing CGS connection pattern
- [ ] Typecheck passes

### US-004: Create IconRepositioner Engine
**Description:** As a developer, I need a core engine that moves menu bar icons using CGEvent simulation.

**Acceptance Criteria:**
- [ ] Create `IconRepositioner.swift` in `Drawer/Core/Engines/`
- [ ] `MoveDestination` enum: `.leftOfItem(MenuBarItem)`, `.rightOfItem(MenuBarItem)`
- [ ] `move(item:to:)` async throws function that repositions an icon
- [ ] Uses CGEvent with `.maskCommand` flag to simulate Command+Drag
- [ ] Sets `windowID`, `mouseEventWindowUnderMousePointer` fields on events
- [ ] Hides mouse cursor during operation, restores after
- [ ] Typecheck passes

### US-005: Add Retry Logic and Error Handling
**Description:** As a developer, I need robust error handling so repositioning recovers from transient failures.

**Acceptance Criteria:**
- [ ] Define `RepositionError` enum with cases: `notMovable`, `invalidItem`, `timeout`, `eventCreationFailed`
- [ ] Retry up to 5 times on failure before throwing
- [ ] Wait for frame change after each move attempt (50ms timeout)
- [ ] "Wake up" unresponsive items with a click before retry
- [ ] Log all attempts and failures via `os.log`
- [ ] Typecheck passes

### US-006: Add Frame Change Detection
**Description:** As a developer, I need to verify that an icon actually moved before considering the operation successful.

**Acceptance Criteria:**
- [ ] `waitForFrameChange(of item:initialFrame:timeout:)` async function
- [ ] Polls `Bridging.getWindowFrame()` until frame differs from initial
- [ ] Throws timeout error if frame unchanged after timeout
- [ ] Uses 10ms polling interval
- [ ] Typecheck passes

### US-007: Integrate Repositioner with Settings UI
**Description:** As a user, I want icons to move in the real menu bar when I drag them in Settings.

**Acceptance Criteria:**
- [ ] Hook `IconRepositioner.move()` into `SettingsMenuBarLayoutView` drop handler
- [ ] Determine target destination based on drop position and adjacent icons
- [ ] Show alert dialog on final failure after all retries exhausted
- [ ] Disable dragging for immovable items (show lock icon)
- [ ] Typecheck passes
- [ ] Verify in app: drag icon between sections, observe real menu bar change

### US-008: Handle Immovable Icons
**Description:** As a user, I want clear feedback when I try to move a system icon that cannot be repositioned.

**Acceptance Criteria:**
- [ ] System icons (Control Center, Clock, Siri, Spotlight) show lock overlay
- [ ] Attempting to drag shows tooltip: "This item cannot be moved by macOS"
- [ ] Immovable icons have reduced opacity (0.5) in Settings view
- [ ] Drag gesture is blocked for immovable items
- [ ] Typecheck passes
- [ ] Verify in app: try to drag Control Center icon, see lock indicator

### US-009: Persist Icon Positions
**Description:** As a user, I want my icon arrangement to persist across app restarts.

**Acceptance Criteria:**
- [ ] Save icon order per section to UserDefaults after successful move
- [ ] Key: `menuBarIconOrder` storing `[String: [MenuBarItemInfo]]` (section -> items)
- [ ] On app launch, compare saved order to current menu bar
- [ ] If icons are out of order, reposition them to match saved order
- [ ] Handle missing icons gracefully (app uninstalled)
- [ ] Typecheck passes

### US-010: Add Position Restoration on Launch
**Description:** As a user, I want my menu bar to restore to my preferred layout when Drawer launches.

**Acceptance Criteria:**
- [ ] `SettingsManager` loads saved positions on `init`
- [ ] `IconRepositioner.restorePositions()` called from `AppDelegate.applicationDidFinishLaunching`
- [ ] Restoration runs async, does not block app launch
- [ ] Skips restoration if no saved positions exist
- [ ] Logs restoration results
- [ ] Typecheck passes

### US-011: Support Within-Section Reordering
**Description:** As a user, I want to reorder icons within the same section (e.g., rearrange visible icons).

**Acceptance Criteria:**
- [ ] Dragging icon within same section triggers reposition
- [ ] Target position calculated based on drop X coordinate
- [ ] Icon moves to left or right of nearest neighbor
- [ ] Animation in Settings UI shows new position
- [ ] Typecheck passes
- [ ] Verify in app: reorder two visible icons, see real menu bar change

## Functional Requirements

- **FR-1:** The system must create CGEvents with Command modifier flag to simulate Command+Drag
- **FR-2:** The system must set `windowID`, `mouseEventWindowUnderMousePointer`, and `mouseEventWindowUnderMousePointerThatCanHandleThisEvent` fields on move events
- **FR-3:** The system must hide the mouse cursor during repositioning and restore it afterward
- **FR-4:** The system must retry failed moves up to 5 times with a "wake up" click between attempts
- **FR-5:** The system must wait for the target window's frame to change before considering a move successful
- **FR-6:** The system must prevent dragging of immovable system icons (Control Center, Clock, Siri, Spotlight)
- **FR-7:** The system must save icon positions to UserDefaults after successful repositioning
- **FR-8:** The system must restore saved icon positions on app launch
- **FR-9:** The system must show an alert dialog when repositioning fails after all retries
- **FR-10:** The system must support moving icons between all three sections: Shown, Hidden, Always Hidden

## Non-Goals

- No repositioning of icons from apps that are not currently running
- No custom icon groups or folders
- No icon appearance customization (size, color, visibility toggle)
- No cross-display icon management (multi-monitor)
- No undo/redo system (use Command+Drag to manually revert)
- No bulk selection and move (single icon at a time)
- No keyboard shortcuts for repositioning

## Technical Considerations

### Dependencies
- Existing `Bridging.swift` for CGS APIs
- Existing `SettingsMenuBarLayoutView.swift` for UI integration
- Accessibility permission (already required for click-through)

### CGEvent Approach (from Ice)
The implementation uses CGEvent simulation rather than Accessibility API:
1. Create mouse down event at arbitrary point (20000, 20000) with Command flag
2. Set window ID fields to target specific menu bar item
3. Post event to app PID, then to session event tap
4. Create mouse up event at destination point
5. Verify frame changed before returning

### Key CGEvent Fields
```swift
event.setIntegerValueField(.eventTargetUnixProcessID, value: targetPID)
event.setIntegerValueField(.mouseEventWindowUnderMousePointer, value: windowID)
event.setIntegerValueField(.mouseEventWindowUnderMousePointerThatCanHandleThisEvent, value: windowID)
event.setIntegerValueField(.windowID, value: windowID) // Field 0x33
```

### Event Tap Synchronization
Use dual event taps to ensure events are received:
1. Listen-only tap at session level to confirm receipt
2. Timeout after 50ms if event not received

### Performance
- Target < 500ms for single icon move
- Mouse cursor hidden during operation to prevent visual glitch
- Frame polling at 10ms intervals

## Success Metrics

- 90%+ of repositioning attempts succeed on first try
- Average repositioning time < 300ms
- < 5% of users report repositioning issues
- Zero crashes related to repositioning
- Settings UI accurately reflects real menu bar state

## Open Questions

1. Should we add a "Reset to Default" button to restore macOS default icon order?
2. Should position restoration on launch be configurable (on/off in Settings)?
3. How should we handle apps that spawn multiple menu bar icons (e.g., Bartender)?
