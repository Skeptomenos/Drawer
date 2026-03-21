# Spec: ARCH-002 & DOC-ALL - Logic Extraction and Documentation

## Context
Maintain clean architecture by separating business logic from views and ensure all public/module APIs are well-documented following the project's standards.

## Problem
1. **ARCH-002:** `SettingsMenuBarLayoutView.swift` contains logic for icon repositioning and coordinate calculation that should be in a ViewModel.
2. **DOC-003:** Multiple core methods in `IconCapturer` and `PermissionManager` lack `///` documentation blocks.
3. **DOC-001/002:** Stale comments and "what not why" comments clutter the codebase.

## Mitigation Plan
1. **Extract ViewModel:** Create `MenuBarLayoutViewModel.swift`. Move methods like `performReposition`, `calculateDestination`, and `getSectionItems` from `SettingsMenuBarLayoutView` to this new class.
2. **Document APIs:** Add comprehensive `///` documentation to:
   - `IconCapturer`: `captureHiddenIcons`, `captureMenuBarRegion`, `clearLastCapture`.
   - `PermissionManager`: `refreshAllStatuses`, `refreshAccessibilityStatus`, `refreshScreenRecordingStatus`, `request`.
3. **Clean Up Comments:**
   - Remove sequential "what" comments in `IconRepositioner.swift` and `MenuBarManager.swift`.
   - Update the stale "Phase 2" comment in `PermissionManager.swift` to reflect current reality.
4. **Fix print():** Replace the `print()` in `DrawerContentView.swift` with `logger.debug()`.

## How to Test
1. **Build:** Verify no errors.
2. **Documentation:** Check that Option-clicking the documented methods shows the new doc comments in Xcode.
3. **Logic:** Ensure reordering icons in Settings still works perfectly.
4. **Logs:** Check `Console.app` to verify that "Tapped item" logs now appear in the debug stream, not standard output.

## References
- `rules/architecture.md`
- `rules/documentation.md`
- `rules/logging.md`
- `UI/Settings/SettingsMenuBarLayoutView.swift`
