# Spec: ARCH-001 - File De-bundling (Multiple Types)

## Context
The project architecture requires strict modularity. One of the core mandates is "One type per file" to improve build times, readability, and maintainability.

## Problem
Several large UI files contain multiple View structs and helper types, violating the single-responsibility principle for files.

**Target Files:**
- `UI/Settings/SettingsMenuBarLayoutView.swift` (>1000 lines, contains `LayoutSectionView`, `LayoutItemView`, etc.)
- `UI/Panels/DrawerContentView.swift` (contains `DrawerItemView`, `SectionHeader`, `IconRow`)
- `UI/Overlay/OverlayContentView.swift` (contains `OverlayIconView`, `OverlayBackground`, etc.)
- `UI/Components/PermissionStatusView.swift` (contains `PermissionRow`, `PermissionBadge`)
- `UI/Onboarding/*.swift` (multiple internal private views)

## Mitigation Plan
1. **Identify Types:** List all distinct `View` structs or helper types in each target file.
2. **Create Files:** Create new Swift files for each type, following the naming convention `TypeName.swift`.
3. **Move Code:** Relocate the code to the new files.
4. **Visibility:** Ensure types are marked `internal` (default) so they remain accessible within the module.
5. **Clean Up Imports:** Add necessary imports (`SwiftUI`, `AppKit`) to each new file.

## How to Test
1. **Build:** Verify the project builds without errors.
2. **Functional Check:** Open the relevant UI sections (Settings, Drawer, Overlay) and verify they still render and function exactly as before.
3. **Project Structure:** Verify the file navigator shows the new files in the appropriate directories.

## References
- `rules/architecture.md` Section 2 - Feature-Sliced Design.
- `rules/rules_swift.md` Section 2 - SwiftUI Architecture.
