# Review: DrawerPanel.swift

**File**: `Drawer/UI/Panels/DrawerPanel.swift`  
**Reviewer**: Ralphus  
**Date**: 2026-01-18  
**Result**: PASSED (0 critical, 0 high, 0 medium, 0 low, 2 info)

---

## Summary

DrawerPanel is an NSPanel subclass that provides the floating, non-activating window for displaying hidden menu bar icons. It handles window configuration, positioning below the menu bar, and size management.

The implementation is clean, focused, and follows project conventions. The panel correctly configures all necessary window behaviors for a non-intrusive, always-visible utility panel. No security or correctness issues found.

---

## Findings

### [INFO] Unused static property `menuBarHeight`

> Defined property is never used in the file

**File**: `Drawer/UI/Panels/DrawerPanel.swift:26`  
**Category**: Maintainability  
**Severity**: Info  

#### Description

The static computed property `menuBarHeight` is defined but never used within the class. The actual menu bar height calculation is done inline in both `position(on:)` (line 94) and `position(alignedTo:on:)` (line 121) using `fullFrame.maxY - visibleFrame.maxY`.

This is dead code that could be removed to reduce confusion, or the inline calculations could use this property for consistency.

#### Current Code

```swift
private static var menuBarHeight: CGFloat { MenuBarMetrics.height }  // Line 26

// Later, in position() methods:
let menuBarHeight = fullFrame.maxY - visibleFrame.maxY  // Line 94, 121
```

#### Suggested Fix

Option 1 - Remove the unused property:

```swift
// Remove line 26 entirely
```

Option 2 - Use the property instead of inline calculation:

```swift
func position(on screen: NSScreen? = nil) {
    guard let targetScreen = screen ?? NSScreen.main else { return }
    
    let fullFrame = targetScreen.frame
    // Use the existing static property instead of inline calculation
    let panelHeight = frame.height
    let y = fullFrame.maxY - Self.menuBarHeight - Self.menuBarGap - panelHeight
    ...
}
```

Note: The inline calculation `fullFrame.maxY - visibleFrame.maxY` may differ from `MenuBarMetrics.height` in edge cases (different screens, notch handling). Review whether the inline approach or the centralized `MenuBarMetrics` approach is preferred for consistency.

#### Verification

1. Search for `menuBarHeight` usage in the file
2. Confirm the inline calculation is intentional or should use the property
3. Remove dead code or consolidate calculation approach

---

### [INFO] Duplicate constant for corner radius

> Two different corner radius values exist across related files

**File**: `Drawer/UI/Panels/DrawerPanel.swift:39` vs `Drawer/UI/Panels/DrawerContentView.swift:28`  
**Category**: Maintainability  
**Severity**: Info  

#### Description

`DrawerPanel` defines `cornerRadius = 10` at line 39, while `DrawerDesign.cornerRadius = 11` is defined in `DrawerContentView.swift` and used by `DrawerContainerView` for the actual visual rendering.

Since `DrawerPanel` itself is transparent (`backgroundColor = .clear`) and the visual corner radius comes from the content view, the `DrawerPanel.cornerRadius` constant is unused. However, having two different values (10 vs 11) could cause confusion.

#### Current Code

```swift
// DrawerPanel.swift:39
static let cornerRadius: CGFloat = 10

// DrawerContentView.swift:28
static let cornerRadius: CGFloat = 11
```

#### Suggested Fix

Remove the unused constant from `DrawerPanel`:

```swift
// Remove line 39 from DrawerPanel.swift
// static let cornerRadius: CGFloat = 10  // DELETE
```

Or align values if the constant is intended for future use:

```swift
static let cornerRadius: CGFloat = DrawerDesign.cornerRadius
```

#### Verification

1. Confirm `DrawerPanel.cornerRadius` is not used anywhere
2. Remove or align the duplicate constant
3. Visual test to confirm corner radius renders correctly

---

## Checklist Results

### Security (P0)
- [x] Input validation present and correct (guards for nil screen, clamped X position)
- [x] No injection vulnerabilities (N/A - no string handling)
- [x] Authentication/authorization (N/A - UI panel)
- [x] No hardcoded secrets
- [x] Sensitive data handled correctly (DEBUG-only logging)

### Correctness (P1)
- [x] Logic matches intended behavior (proper menu bar positioning)
- [x] Edge cases handled (nil screen guard, X position clamping)
- [x] Error handling appropriate (graceful nil handling)
- [x] No obvious bugs
- [x] Types used correctly (NSPanel, CGFloat, NSScreen)

### Performance (P2)
- [x] No N+1 queries or unbounded loops (N/A)
- [x] Appropriate data structures
- [x] No memory leaks (no subscriptions or closures)
- [x] Caching considered (N/A)

### Maintainability (P3)
- [x] Code is readable and self-documenting
- [x] Functions are focused (single responsibility)
- [ ] No dead code (unused `menuBarHeight` property - INFO)
- [x] Consistent with project conventions

### Test Coverage (P4)
- [ ] Tests exist for functionality (no tests for DrawerPanel)
- [ ] Tests cover happy path
- [ ] Tests are meaningful

---

## Positive Observations

1. **Correct NSPanel configuration**: All window behavior flags are properly set for a non-activating, non-focus-stealing panel
2. **Proper window level**: Uses `.statusBar` level, appropriate for menu bar companion windows
3. **Space behavior**: `canJoinAllSpaces` and `fullScreenAuxiliary` allow the panel to work across Spaces and with full-screen apps
4. **Position clamping**: The `position(alignedTo:on:)` method properly clamps X position to screen bounds
5. **DEBUG-only logging**: Detailed positioning logs are properly gated for debug builds only
6. **Width management**: `updateWidth` preserves horizontal center while resizing
7. **Final class**: Properly marked as `final` since no subclassing is intended
