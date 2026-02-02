# Drawer Agent Guide

Drawer is a macOS 14+ menu bar utility that hides icons using the "10k pixel hack" - a separator NSStatusItem expands to 10,000px, pushing icons off-screen.

## Dev Standards

**Role:** Senior Engineer. **Manager:** User (Architect).  
**Goal:** Production-Ready, Type-Safe, Modular.

### Hard Constraints
1. **NO SPEC = NO CODE:** Demand `specs/*.md` before implementation.
2. **ZERO TOLERANCE:** No build warnings. No force unwraps. No failing tests.
3. **ATOMICITY:** One feature at a time. No "while I'm here" refactoring.
4. **SAFETY:** All I/O wrapped in `do/catch`. Secrets via Keychain/ENV.
5. **TIMEOUT:** Commands > 5 min → stop and report.

### Git Safety
- **Read-Only:** `git status`, `git diff`, `git log`, `git show`, `git branch`.
- **NEVER:** `git reset --hard`, `git push --force`, `git clean -fd`.
- **Commits:** Only on explicit user request.
- **Conflicts:** Report to user; do not auto-resolve.

### Rule Activation
*Apply rules from `rules/` based on task context:*

| Task Context        | Rules                                                                          |
| ------------------- | ------------------------------------------------------------------------------ |
| All code changes    | `rules/architecture.md`, `rules/workflow.md`, `rules/testing.md`               |
| Swift / SwiftUI     | `rules/rules_swift.md`, `rules/rules_swift_concurrency.md`, `rules/logging.md` |
| iOS/macOS Agentic   | `rules/rules_ios_agentic.md`                                                   |
| API / Design        | `rules/api_design.md`, `rules/security.md`                                     |
| DevOps / CI         | `rules/devops.md`                                                              |
| Documentation       | `rules/documentation.md`                                                       |

### Workflow Loop
1. **READ:** `docs/` + relevant `specs/*.md`.
2. **PLAN:** Review spec for gaps; clarify before coding.
3. **TDD:** Write failing test → validate failure.
4. **CODE:** Pass test → refactor → type check.
5. **HALT:** If build/test fails, fix immediately.

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
