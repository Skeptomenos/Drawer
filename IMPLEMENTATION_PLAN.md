# Implementation Plan: Drawer

> **Generated**: 2026-01-18
> **Status**: Active
> **Based on**: `specs/review-fixes.md`, `PRD.md`, code review findings, architecture analysis

---

## Executive Summary

| Metric | Value |
|--------|-------|
| **Source Files** | 40 (~6,463 lines) |
| **Test Files** | 31 (278 tests) |
| **Review Status** | Complete (0 critical, 0 high, 2 medium, 17 low) |
| **Architecture** | MVVM, Section-based (Phase 0-3 complete) |

**Goal**: Eliminate crash risks, achieve comprehensive test coverage, and prepare for advanced Settings UI.

---

## Phase 1: Stability & Code Hygiene (Review Fixes)

**Priority**: CRITICAL (Safety)  
**Source**: `specs/review-fixes.md`  
**Effort**: 2-3 hours  

This phase addresses 2 potential crashes and 13 code quality issues identified during code review.

### 1.1 Medium Severity Fixes (Crash Prevention)

| Task | File | Issue | Status |
|------|------|-------|--------|
| 1.1.1 | `Drawer/UI/Overlay/OverlayPanelController.swift:76` | Force unwrap `NSScreen.screens.first!` can crash on headless/screen-change | [x] |
| 1.1.2 | `Drawer/Bridging/Bridging.swift:74-95` | TOCTOU race condition in window list allocation | [x] |

**Verification**: Build and run; test overlay mode on single/multi-monitor setups.

### 1.2 Low Severity Fixes (Code Quality)

| Task | File | Issue | Status |
|------|------|-------|--------|
| 1.2.1 | `Drawer/Core/Managers/DrawerManager.swift:48` | Remove unused `cancellables` | [x] |
| 1.2.2 | `Drawer/Core/Managers/HoverManager.swift:30` | Remove unused `cancellables` | [x] |
| 1.2.3 | `Drawer/UI/Panels/DrawerPanelController.swift:49` | Remove unused `cancellables` | [x] |
| 1.2.4 | `Drawer/App/AppState.swift:79-87` | Fix NotificationCenter observer cleanup in deinit | [x] |
| 1.2.5 | `Drawer/Core/Engines/IconCapturer.swift:418` | Fix off-by-one: `> 50` → `>= 50` | [x] |
| 1.2.6 | `Drawer/Core/Engines/IconCapturer.swift:381-382` | Make `standardIconWidth` and `iconSpacing` private | [x] |
| 1.2.7 | `Drawer/Utilities/WindowInfo.swift:41` | Replace force cast with safe unwrap | [x] |
| 1.2.8 | `Drawer/UI/Settings/AboutView.swift:43` | Extract URL to static constant | [ ] |
| 1.2.9 | `Drawer/UI/Panels/DrawerContentView.swift:189` | Add debug logging for capture errors | [ ] |
| 1.2.10 | `Drawer/Utilities/ScreenCapture.swift:110-111` | Use integer comparison instead of float | [ ] |
| 1.2.11 | `Drawer/Core/Managers/SettingsManager.swift` + `GeneralSettingsView.swift` | Extract slider range constants | [ ] |
| 1.2.12 | `Drawer/UI/Onboarding/OnboardingView.swift` | Add MARK section comments | [ ] |
| 1.2.13 | `Drawer/UI/Panels/DrawerPanel.swift:26,39` | Remove unused `menuBarHeight` and `cornerRadius` | [ ] |
| 1.2.14 | `Drawer/UI/Overlay/OverlayContentView.swift:62` | Extract magic number `2.0` to constant | [ ] |
| 1.2.15 | `Drawer/UI/Overlay/OverlayPanel.swift:76` | Extract magic number `2` for menu bar gap | [ ] |

### 1.3 Branding & Housekeeping

| Task | File | Issue | Status |
|------|------|-------|--------|
| 1.3.1 | `LauncherApplication/Info.plist` | Update copyright to "Drawer", use build variables | [ ] |
| 1.3.2 | `LauncherApplication/AppDelegate.swift:34` | Update app name from "Hidden Bar" to "Drawer" | [ ] |
| 1.3.3 | `LauncherApplication/AppDelegate.swift:20` | Update bundle identifier to match main app | [ ] |
| 1.3.4 | `hidden/Info.plist` | Remove empty `CFBundleIconFile`, update copyright year | [ ] |

**Exit Criteria**:
- [ ] `xcodebuild test -scheme Drawer` passes (all 278 tests)
- [ ] `swiftlint lint Drawer/` - no errors
- [ ] Launch-at-login works with updated bundle ID
- [ ] Manual verification on multi-monitor setup

---

## Phase 2: Test Coverage Gaps

**Priority**: HIGH (Reliability)  
**Effort**: 3-4 hours  

The codebase has excellent coverage (278 tests) but two components lack tests.

### 2.1 OverlayModeManager Tests

**Target**: `Drawer/Core/Managers/OverlayModeManager.swift` (252 lines, 0 tests)

| Task | Description | Status |
|------|-------------|--------|
| 2.1.1 | Create `DrawerTests/Core/Managers/OverlayModeManagerTests.swift` | [ ] |
| 2.1.2 | Test initial state (`isOverlayActive = false`) | [ ] |
| 2.1.3 | Test `showOverlay()` sets `isOverlayActive = true` | [ ] |
| 2.1.4 | Test `hideOverlay()` sets `isOverlayActive = false` | [ ] |
| 2.1.5 | Test `toggleOverlay()` toggles state | [ ] |
| 2.1.6 | Test auto-hide timer integration | [ ] |
| 2.1.7 | Test item tap handling | [ ] |
| 2.1.8 | Test icon capture integration (mock IconCapturer) | [ ] |

**Mock Requirements**: Create `MockOverlayPanelController` similar to existing mock patterns.

### 2.2 ScreenCapture Utility Tests

**Target**: `Drawer/Utilities/ScreenCapture.swift` (146 lines, 0 tests)

| Task | Description | Status |
|------|-------------|--------|
| 2.2.1 | Create `DrawerTests/Utilities/ScreenCaptureTests.swift` | [ ] |
| 2.2.2 | Test `captureRegion()` with mock screen | [ ] |
| 2.2.3 | Test composite image creation | [ ] |
| 2.2.4 | Test width comparison logic (after Phase 1 fix) | [ ] |

**Exit Criteria**:
- [ ] OverlayModeManager test coverage > 80%
- [ ] Total project test count > 290
- [ ] All new tests pass

---

## Phase 3: Documentation & Cleanup

**Priority**: MEDIUM (Maintainability)  
**Effort**: 1-2 hours  

### 3.1 Update Test for Off-by-One Fix

| Task | File | Description | Status |
|------|------|-------------|--------|
| 3.1.1 | `DrawerTests/Core/Engines/IconCapturerTests.swift` | Update test `ICN-007` to expect exactly 50 icons (after 1.2.5) | [ ] |

### 3.2 Archive Completed Plans

| Task | Description | Status |
|------|-------------|--------|
| 3.2.1 | Move `docs/IMPLEMENTATION_PLAN_ARCHITECTURE_IMPROVEMENTS.md` to `archive/` (Phase 0-3 complete) | [ ] |
| 3.2.2 | Move `docs/IMPLEMENTATION-PLAN-DRAWER-AND-ALWAYS-HIDDEN.md` to `archive/` (complete) | [ ] |

---

## Phase 4: Advanced Settings UI (Future)

**Priority**: LOW (Feature Enhancement)  
**Effort**: 1-2 weeks  
**Dependencies**: Phases 1-3 complete

This phase implements the drag-and-drop Settings UI shown in `specs/reference_images/settings-layout.jpg`.

### 4.1 Settings Architecture

| Task | Description | Status |
|------|-------------|--------|
| 4.1.1 | Design data model for settings icon representation | [ ] |
| 4.1.2 | Create `SettingsMenuBarLayoutView.swift` | [ ] |
| 4.1.3 | Implement icon drag-drop between sections | [ ] |

### 4.2 Menu Bar Layout View

| Task | Description | Status |
|------|-------------|--------|
| 4.2.1 | Display three sections: Shown, Hidden, Always Hidden | [ ] |
| 4.2.2 | Enable drag-and-drop reordering | [ ] |
| 4.2.3 | Sync changes to `MenuBarManager` | [ ] |
| 4.2.4 | Add spacer insertion capability | [ ] |

### 4.3 Sidebar Navigation

| Task | Description | Status |
|------|-------------|--------|
| 4.3.1 | Update `SettingsView.swift` with sidebar navigation | [ ] |
| 4.3.2 | Add "Menu Bar Layout" tab | [ ] |
| 4.3.3 | Match reference image styling | [ ] |

**Exit Criteria**:
- [ ] Users can visually reorder icons in Settings
- [ ] Changes persist across app restart
- [ ] UI matches `specs/reference_images/settings-layout.jpg`

---

## Verification Checklist

After completing all phases:

### Build & Test
- [ ] `xcodebuild -scheme Drawer -configuration Debug build` - no warnings
- [ ] `xcodebuild test -scheme Drawer -destination 'platform=macOS'` - all tests pass
- [ ] `swiftlint lint Drawer/` - no errors

### Manual Verification
- [ ] Toggle drawer open/close
- [ ] Test overlay mode on notched MacBook
- [ ] Verify permissions flow (revoke and re-grant)
- [ ] Test launch-at-login with updated bundle ID
- [ ] Verify settings persist across restart
- [ ] Test on multi-monitor setup

---

## Files Modified Summary

| Phase | Files |
|-------|-------|
| 1.1 | `OverlayPanelController.swift`, `Bridging.swift` |
| 1.2 | 15 files (see detailed table above) |
| 1.3 | `LauncherApplication/Info.plist`, `LauncherApplication/AppDelegate.swift`, `hidden/Info.plist` |
| 2.1 | New: `OverlayModeManagerTests.swift` |
| 2.2 | New: `ScreenCaptureTests.swift` |
| 3.1 | `IconCapturerTests.swift` |
| 4.x | New: `SettingsMenuBarLayoutView.swift`, modify `SettingsView.swift` |

---

## Notes

- All changes follow existing patterns in the codebase (see `AGENTS.md`)
- No new dependencies required for Phases 1-3
- Phase 4 may require additional UI components
- Test coverage already exists for most affected components
- Estimated total effort: ~8-10 hours for Phases 1-3
