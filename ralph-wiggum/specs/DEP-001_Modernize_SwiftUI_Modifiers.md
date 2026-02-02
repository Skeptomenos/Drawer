# Spec: DEP-001 & DEP-002 - Modernize SwiftUI Modifiers

## Context
Project rules require using the latest SwiftUI APIs. Legacy modifiers like `foregroundColor()` and `cornerRadius()` are deprecated in favor of more flexible alternatives.

## Problem
Multiple files use outdated modifiers that generate build warnings and deviate from current best practices.

**Violations (DEP-001):** `foregroundColor()` should be `foregroundStyle()`.
- Found in: `SettingsMenuBarLayoutView.swift`, `DrawerContentView.swift`.

**Violations (DEP-002):** `cornerRadius()` should be `clipShape(.rect(cornerRadius:))`.
- Found in: `GeneralSettingsView.swift` (Line 103).

## Mitigation Plan
1. **Batch Replace:** Use global find and replace for `.foregroundColor(` to `.foregroundStyle(`.
2. **Refactor Corner Radius:** In `GeneralSettingsView.swift`, replace `.cornerRadius(4)` with `.clipShape(.rect(cornerRadius: 4))`.
3. **Verify Layout:** Ensure no visual regressions occur after replacement (the behavior should be identical).

## How to Test
1. **Build:** Verify the project builds without warnings related to these modifiers.
2. **Visual Inspection:** Open Settings and the Drawer panel.
3. **Verification:** Ensure all icons and text still have correct colors and rounded corners.

## References
- `rules/rules_swift.md` Section 1 - Deprecated API replacements.
- `UI/Settings/SettingsMenuBarLayoutView.swift`
- `UI/Panels/DrawerContentView.swift`
- `UI/Settings/GeneralSettingsView.swift`
