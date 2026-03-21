# Spec: BUG-001 - Drawer Panel Alignment

## Context
The Drawer is a macOS menu bar utility that displays hidden icons in a floating panel. Currently, the panel appears centered on the screen when revealed, rather than being anchored to the position of the separator icon in the menu bar. This creates a disjointed user experience.

## Problem
In `AppState.swift`, the code that triggers the drawer show animation does not provide an alignment X-coordinate to the `DrawerPanelController`.

**Location:** `Drawer/App/AppState.swift` (Lines 276, 294)
```swift
// Current implementation
drawerController.show(content: contentView)
```

**Target Method:** `Drawer/UI/Panels/DrawerPanelController.swift`
```swift
func show<Content: View>(content: Content, alignedTo xPosition: CGFloat? = nil, on screen: NSScreen? = nil)
```

## Mitigation Plan
1. **Retrieve Separator Position:** Obtain the current screen position of the separator icon from `MenuBarManager`.
2. **Calculate Anchor Point:** Determine the appropriate X coordinate so the drawer's right edge aligns with the separator's left or center (depending on visual preference).
3. **Pass to Controller:** Update `AppState` to pass this coordinate to the `show` method.
4. **Verify Clamping:** Ensure the drawer doesn't go off-screen if the separator is too close to the screen edge (the controller already handles some clamping, verify its logic).

## How to Test
1. Launch Drawer.
2. Ensure there are hidden icons.
3. Click the toggle button to show the drawer.
4. **Verification:** The drawer panel should appear directly below the menu bar, with its right side horizontally aligned with the separator/toggle icon region, NOT centered on the screen.
5. Move the separator (⌘+drag) and toggle again to ensure it follows the new position.

## References
- `Drawer/Core/Managers/MenuBarManager.swift` - Source of separator position.
- `Drawer/App/AppState.swift` - Caller logic.
- `Drawer/UI/Panels/DrawerPanelController.swift` - Panel positioning logic.
