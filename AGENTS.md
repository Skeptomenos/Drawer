# Drawer Agent Guide

Drawer is a macOS 14+ menu bar utility that hides icons using the "10k pixel hack" - a separator NSStatusItem expands to 10,000px, pushing icons off-screen.

## Critical Components

Modify these with extreme caution. Always verify menu bar behavior after changes.

| Component             | File                        | Risk     |
| --------------------- | --------------------------- | -------- |
| 10k Pixel Hack        | `MenuBarManager.swift`        | CRITICAL |
| Screen Capture        | `IconCapturer.swift`          | HIGH     |
| Icon Repositioning    | `IconRepositioner.swift`      | HIGH     |
| TCC Permissions       | `PermissionManager.swift`     | HIGH     |

## Key Files

- `AppState.swift` - Central state coordinator
- `MenuBarManager.swift` - Core hiding mechanism
- `IconCapturer.swift` - ScreenCaptureKit capture logic
- `DrawerPanelController.swift` - Panel presentation

## Testing (Required)

Use **XcodeBuildMCP tools** for all building and testing. Do not use manual xcodebuild commands.

```
XcodeBuildMCP_session-set-defaults  → Set scheme, simulator
XcodeBuildMCP_build_sim             → Build for simulator
XcodeBuildMCP_test_sim              → Run tests
XcodeBuildMCP_build_run_macos       → Build & run macOS app
XcodeBuildMCP_describe_ui           → Get UI hierarchy
XcodeBuildMCP_screenshot            → Capture screen
```

See `docs/TESTING.md` for complete reference.

## Do Not

- Use Storyboards/XIBs - SwiftUI only
- Force unwrap (`!`) - use `guard let`
- Use `DispatchQueue.main` - use `@MainActor`
- Bypass TCC permissions - use `PermissionManager`
- Remove debug logs - they're preserved intentionally
- Use manual `xcodebuild` commands - use XcodeBuildMCP tools

## Documentation

| Topic              | Location                  |
| ------------------ | ------------------------- |
| Architecture       | `docs/ARCHITECTURE.md`      |
| Build/Test         | `docs/BUILDING.md`          |
| XcodeBuildMCP      | `docs/TESTING.md`           |
| Code Style         | `docs/CODE_STYLE.md`        |
| Logging            | `docs/LOGGING.md`           |
| Specs              | `specs/*.md`                |
| Reference Images   | `specs/reference_images/`   |
