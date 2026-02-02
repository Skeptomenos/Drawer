# Implementation Plan

> **Generated:** 2026-02-02  
> **Source:** `ralph-wiggum/specs/*.md` + `CODE_REVIEW_ISSUES.md`  
> **Total Issues:** 72 (consolidated into 16 cohesive tasks)  
> **Estimated Effort:** 8-10 hours

---

## Tasks

| Status | Task | Spec Reference | Notes |
|--------|------|----------------|-------|
| | **Phase 1: Critical Stability** | | |
| [x] | **Task 1.1**: Fix drawer panel alignment to separator position | `specs/BUG-001_Drawer_Alignment.md` | Done in v0.5.1-alpha.25 |
| [x] | **Task 1.2**: Concurrency hardening - debounce & cancellation | `specs/CONC-001_DispatchQueue_main.md`, `specs/CONC-003_Cancellation_Checks.md` | Done in v0.5.1-alpha.26: Replaced DispatchQueue.main.asyncAfter with Task in MenuBarManager toggle(), added Task.isCancelled/checkCancellation in IconCapturer slicing loop and IconRepositioner polling/retry loops |
| [x] | **Task 1.3**: Accessibility - replace onTapGesture with Button | `specs/A11Y-001_onTapGesture_Accessibility.md` | Done in v0.5.1-alpha.27: Replaced onTapGesture with Button in flatItemsView and IconRow, applied .buttonStyle(.plain) and accessibilityLabel/Hint |
| | **Phase 2: Safety & Modernization** | | |
| [x] | **Task 2.1**: Safety sweep - eliminate force unwraps & IUOs | `specs/SEC-003_MenuBarManager_IUOs.md`, `specs/CODE_REVIEW_ISSUES.md:SEC-001,SEC-002` | Done in v0.5.1-alpha.28: Converted MenuBarManager IUOs to computed properties with fatalError safety, wrapped CGEventField rawValue in safe closure, wrapped URL literal in safe closure |
| [x] | **Task 2.2**: UI modernization - deprecated SwiftUI modifiers | `specs/DEP-001_Modernize_SwiftUI_Modifiers.md`, `specs/DEP-004_Dynamic_Type.md` | Done in v0.5.1-alpha.29: Replaced 15x foregroundColor→foregroundStyle, 1x cornerRadius→clipShape, 17x hardcoded fonts→Dynamic Type (kept 8pt lockIconSize as decorative) |
| [x] | **Task 2.3**: GeometryReader cleanup | `specs/CODE_REVIEW_ISSUES.md:DEP-005` | Evaluated: GeometryReader on line 816 is used to collect item frames for drag-and-drop position tracking via PreferenceKey. This is the correct pattern—neither containerRelativeFrame() nor visualEffect() can replace it. Usage is minimal and justified. No changes needed. |
| | **Phase 3: Architecture** | | |
| [x] | **Task 3.1**: File structure debundling | `specs/ARCH-001_File_Debundling.md` | Done in v0.5.1-alpha.31: Verified all nested types already debundled (LayoutSectionView, LayoutItemView, DrawerItemView, SectionHeader, IconRow, OverlayIconView, OverlayBackground, PermissionRow, PermissionBadge) |
| [ ] | **Task 3.2**: Logic extraction - ViewModels | `specs/ARCH-002_Docs_and_Logic.md` | Move business logic from SettingsMenuBarLayoutView to MenuBarLayoutViewModel |
| [ ] | **Task 3.3**: Migration to @Observable macro | `specs/DEP-003_Observable_Migration.md` | Convert 13 ObservableObject classes to @Observable; update @Published, @ObservedObject, @EnvironmentObject |
| [x] | **Task 3.4**: Animation context async wrapper | `specs/CODE_REVIEW_ISSUES.md:CONC-002` | Done in v0.5.1-alpha.30: Created NSAnimationContext+Async.swift, refactored DrawerPanelController and OverlayPanelController to use async/await pattern |
| | **Phase 4: Testing & Documentation** | | |
| [ ] | **Task 4.1**: Test infrastructure - create UI test target | `specs/CODE_REVIEW_ISSUES.md:TEST-001` | Create DrawerUITests target with app launch smoke test |
| [ ] | **Task 4.2**: Unit tests - UI panels | `specs/CODE_REVIEW_ISSUES.md:TEST-002` | Add tests for DrawerPanelController state transitions and positioning |
| [ ] | **Task 4.3**: Unit tests - mock boundary fixes | `specs/CODE_REVIEW_ISSUES.md:TEST-003` | Create protocol-based abstractions for SCStream/SCShareableContent |
| [ ] | **Task 4.4**: Unit tests - post @Observable updates | `specs/CODE_REVIEW_ISSUES.md:TEST-005` | Update tests to use new observation patterns after Task 3.3 |
| [ ] | **Task 4.5**: Logging standardization | `specs/ARCH-002_Docs_and_Logic.md:LOG-001` | Replace print() with logger.debug(), fix stale comments |
| [ ] | **Task 4.6**: API documentation | `specs/ARCH-002_Docs_and_Logic.md:DOC-003` | Add /// documentation to IconCapturer and PermissionManager public methods |

---

## Legend

- `[ ]` Pending
- `[x]` Complete
- `[!]` Blocked

---

## Dependencies

```
Phase 1 (no dependencies)
  Task 1.1, 1.2, 1.3 can be done in parallel

Phase 2 (depends on Phase 1 completion)
  Task 2.1, 2.2, 2.3 can be done in parallel

Phase 3 (sequential)
  Task 3.1 -> Task 3.2 (debundle before extracting logic)
  Task 3.3 depends on 3.1, 3.2 (cleaner migration with separated files)
  Task 3.4 independent

Phase 4 (depends on Phase 3)
  Task 4.1 independent (infrastructure)
  Task 4.2, 4.3 depend on Task 3.1-3.2
  Task 4.4 BLOCKED by Task 3.3 (@Observable migration)
  Task 4.5, 4.6 independent
```

---

## Priority Rationale

### Phase 1: Critical Stability (Tasks 1.1-1.3)
- **BUG-001**: Visible bug affecting user experience - drawer appears in wrong position
- **CONC-001/003/004**: Race conditions and resource leaks from missing cancellation
- **A11Y-001**: VoiceOver users cannot interact with drawer icons

### Phase 2: Safety & Modernization (Tasks 2.1-2.3)
- **SEC-***: Force unwraps risk runtime crashes
- **DEP-001/002/004**: Deprecated APIs generate warnings and may break in future macOS
- **DEP-005**: GeometryReader overuse impacts layout performance

### Phase 3: Architecture (Tasks 3.1-3.4)
- **ARCH-001**: Large files impede maintainability and review
- **ARCH-002**: Business logic in Views violates separation of concerns
- **DEP-003**: @Observable migration must happen BEFORE adding new tests
- **CONC-002**: Completion handlers in animation context violate concurrency rules

### Phase 4: Testing & Documentation (Tasks 4.1-4.6)
- **TEST-***: Lock in behavior after architectural changes
- **LOG/DOC-***: Improve maintainability and debugging capability

---

## Implementation Notes

### Task 1.1: Fix Panel Alignment
```swift
// In AppState.swift, change:
drawerController.show(content: contentView)

// To:
let separatorX = menuBarManager.separatorPosition.x
drawerController.show(content: contentView, alignedTo: separatorX)
```

### Task 1.2: Concurrency Hardening
Key files:
- `MenuBarManager.swift:473` - Replace DispatchQueue.main.asyncAfter with Task
- `IconCapturer.swift:402` - Add Task.isCancelled guard in slicing loop
- `IconRepositioner.swift:479` - Add Task.isCancelled guard in polling loop

### Task 2.1: Safety Sweep
Files requiring changes:
- `MenuBarManager.swift:38,41` - Convert IUOs to non-optional with init
- `IconRepositioner.swift:86` - CGEventField force unwrap -> fatalError pattern
- `AboutView.swift:13` - URL force unwrap -> optional handling

### Task 2.2: UI Modernization
Global replacements:
- `.foregroundColor(` -> `.foregroundStyle(`
- `.cornerRadius(N)` -> `.clipShape(.rect(cornerRadius: N))`
- `.font(.system(size: N))` -> `.font(.caption)` (etc. per size mapping)

### Task 3.3: @Observable Migration
13 classes to migrate:
1. AppState
2. SettingsManager
3. MenuBarManager
4. PermissionManager
5. DrawerManager
6. HoverManager
7. OverlayModeManager
8. LaunchAtLoginManager
9. IconCapturer
10. ControlItem
11. MenuBarSection
12. DrawerPanelController
13. OverlayPanelController

---

## Verification Checklist

For each task:
- [ ] Code compiles without errors
- [ ] No new warnings introduced
- [ ] Existing tests pass
- [ ] Manual verification of affected functionality
- [ ] XcodeBuildMCP tools used for building/testing

---

## Risk Assessment

| Task | Risk | Mitigation |
|------|------|------------|
| Task 1.1 | Low | Simple parameter passing; verify visually |
| Task 1.2 | Medium | Test concurrency under rapid user actions |
| Task 3.3 | High | @Observable migration affects 13 classes; incremental migration recommended |
| Task 4.4 | Low | Blocked until 3.3 complete; do not start early |

---

*Plan generated by OpenCode implementation analysis.*
