# Phase 2: The Drawer Engine Specification

**Goal**: Implement the "Bartender Bar" (Drawer) feature. This is the core differentiator. It requires creating a secondary window that floats below the menu bar and displays "ghost" images of the hidden items.

## Task 2.1: The Drawer Window (NSPanel)
- **Objective**: Create the floating window that will hold the hidden icons.
- **Steps**:
  1.  Create `DrawerPanel.swift` inheriting from `NSPanel`.
  2.  Configure flags: `.borderless`, `.nonactivatingPanel` (doesn't steal focus), `.floating` (always on top).
  3.  Implement `position(below: NSRect)` logic to align it perfectly under the menu bar.
  4.  Create a `DrawerView.swift` (SwiftUI) and host it in the panel.
- **Acceptance Criteria**: Triggering "Open Drawer" shows a floating, transparent window anchored to the top of the screen.

## Task 2.2: Screen Capture Implementation (ScreenCaptureKit)
- **Objective**: Capture the visual state of the hidden menu bar items.
- **Steps**:
  1.  Create `IconCapturer.swift`.
  2.  Use `SCShareableContent` to find the menu bar window ID.
  3.  Implement logic to:
      - Temporarily "Show" the hidden section (separator length = normal).
      - Wait 1 frame (for rendering).
      - Capture the menu bar image via `SCScreenshotManager`.
      - "Hide" the section again (separator length = 10000).
  4.  Slice the captured image into individual icon sprites (based on standard icon width/spacing).
  5.  **Visual Reference**: Use `look_at` on `specs/reference_images/icon-drawer.jpg`. Note the background material, spacing between icons, and corner radius. Replicate this exact aesthetic in `DrawerView`.
- **Acceptance Criteria**: App can generate a `CGImage` of the hidden menu bar section.

## Task 2.3: Icon Proxy Logic
- **Objective**: Map the captured images to interactive elements in the Drawer.
- **Steps**:
  1.  Define `DrawerItem` struct (id, image, originalPosition).
  2.  Update `DrawerManager` to populate `[DrawerItem]` from the capture process.
  3.  Render these items in `DrawerView` using a `HStack`.
- **Acceptance Criteria**: The Drawer displays a static screenshot of the hidden icons.

## Task 2.4: Interaction & Click-Through
- **Objective**: Make the "ghost" icons interactive.
- **Steps**:
  1.  Add `onTapGesture` to `DrawerItem` views.
  2.  Implement the click handler:
      - When clicking Item X in Drawer...
      - Immediately hide Drawer.
      - Expand Menu Bar (real items appear).
      - Programmatically move mouse cursor to Item X's *real* screen coordinate.
      - Simulate `CGEvent.leftMouseDown/Up`.
      - (Optional) Restore state after interaction.
- **Acceptance Criteria**: Clicking a fake icon in the Drawer opens the actual menu of the target app.

## Task 2.5: Hover & Auto-Show (Event Monitor)
- **Objective**: Show the Drawer when mouse enters the menu bar area.
- **Steps**:
  1.  Create `EventManager.swift` with `NSEvent.addGlobalMonitorForEvents`.
  2.  Track mouse location.
  3.  If `Mouse.y > Screen.height - MenuBarHeight`: Trigger `DrawerManager.show()`.
  4.  If `Mouse.y` leaves Drawer area: Trigger `DrawerManager.hide()`.
- **Acceptance Criteria**: Moving mouse to top of screen reveals Drawer; moving away hides it.
