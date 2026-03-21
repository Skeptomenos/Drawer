# Spec: A11Y-001 - Accessible Icon Interactions

## Context
The project must adhere to strict accessibility standards (macOS 14+). Interactive elements must use semantically correct controls (`Button`) rather than raw gestures (`onTapGesture`) to support VoiceOver, keyboard navigation, and eye-tracking.

## Problem
The icons in the drawer panel use `.onTapGesture` for interaction. This makes them invisible to screen readers and unreachable via keyboard navigation.

**Location:** `Drawer/UI/Panels/DrawerContentView.swift` (Lines 177, 288)
```swift
DrawerItemView(item: item)
    .onTapGesture {
        onItemTap?(item)
    }
```

## Mitigation Plan
1. **Replace Gesture with Button:** Wrap the `DrawerItemView` in a `Button`.
2. **Apply Plain Style:** Use `.buttonStyle(.plain)` to maintain the current visual appearance without standard button styling.
3. **Add Accessibility Labels:** Ensure each button has a meaningful `accessibilityLabel` (e.g., the app name the icon belongs to).
4. **Coordinate Mapping:** Ensure the button hit target correctly covers the icon area.

## How to Test
1. **VoiceOver Test:** Enable VoiceOver (⌘+F5). Navigate into the Drawer.
2. **Verification:** Ensure VoiceOver can focus each icon individually and announces its name.
3. **Keyboard Test:** Ensure the icons can be reached via Tab key (if Full Keyboard Access is enabled) and activated with Space/Enter.
4. **Functional Test:** Click an icon and verify it still triggers the "click-through" action to the real menu bar item.

## References
- `rules/rules_swift.md` Section 3 - Accessibility rules.
- `Drawer/UI/Panels/DrawerContentView.swift`
