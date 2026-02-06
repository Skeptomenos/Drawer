# Drawer Code Review Issues Report

> **Generated:** 2026-02-02  
> **Reviewed By:** OpenCode Agent  
> **Rules Reference:** `rules/*.md`  
> **Total Issues Found:** 72

---

## Executive Summary

This report documents all code issues discovered during a comprehensive review of the Drawer codebase against the project's defined rules in `rules/`. Issues are categorized by severity and include detailed mitigation strategies with effort estimates.

| Category                      | Count | Severity |
| ----------------------------- | ----- | -------- |
| Swift Concurrency             | 6     | HIGH     |
| Accessibility                 | 2     | HIGH     |
| Type Safety / Security        | 4     | MEDIUM   |
| Swift/SwiftUI Deprecated APIs | 28    | MEDIUM   |
| Architecture / Code Hygiene   | 12    | MEDIUM   |
| Testing Gaps                  | 5     | MEDIUM   |
| Bugs (Functional)             | 1     | HIGH     |
| Logging / Documentation       | 14    | LOW      |

---

## Table of Contents

1. [Bugs (Functional Issues)](#1-bugs-functional-issues)
2. [Swift Concurrency Violations](#2-swift-concurrency-violations)
3. [Accessibility Violations](#3-accessibility-violations)
4. [Type Safety / Security Violations](#4-type-safety--security-violations)
5. [Swift/SwiftUI Deprecated APIs](#5-swiftswiftui-deprecated-apis)
6. [Architecture / Code Hygiene](#6-architecture--code-hygiene)
7. [Testing Gaps](#7-testing-gaps)
8. [Logging / Documentation](#8-logging--documentation)
9. [Remediation Priority Matrix](#9-remediation-priority-matrix)

---

## 1. Bugs (Functional Issues)

### BUG-001: Drawer Panel Not Aligned to Separator Position

| Property    | Value                                                                                  |
| ----------- | -------------------------------------------------------------------------------------- |
| **Severity**  | HIGH                                                                                   |
| **File**      | `App/AppState.swift:276, 294`                                                            |
| **Rule**      | Functional correctness                                                                 |
| **Status**    | Open                                                                                   |

**Description:**  
The drawer panel appears centered on the screen instead of being anchored to the right edge of the separator icon (where hidden icons are located). This creates a visual disconnect between the menu bar icons and the drawer.

**Root Cause:**  
In `AppState.swift`, the `drawerController.show(content:)` is called without the `alignedTo: xPosition` parameter:

```swift
// Current (incorrect):
drawerController.show(content: contentView)

// Should be:
let separatorX = menuBarManager.separatorPosition.x
drawerController.show(content: contentView, alignedTo: separatorX)
```

The `DrawerPanelController.show()` method supports alignment via the `alignedTo` parameter, but it's not being used.

**Mitigation Strategy:**
1. Get the separator's screen position from `MenuBarManager`
2. Pass the X coordinate to `drawerController.show(content:, alignedTo:)`
3. Ensure the drawer's right edge aligns with the separator icon

**Effort Estimate:** 2 hours

---

## 2. Swift Concurrency Violations

> **Rule Reference:** `rules/rules_swift_concurrency.md`

### CONC-001: DispatchQueue.main.asyncAfter Usage

| Property    | Value                                  |
| ----------- | -------------------------------------- |
| **Severity**  | HIGH                                   |
| **File**      | `Core/Managers/MenuBarManager.swift:473` |
| **Rule**      | "DispatchQueue.main → @MainActor"      |

**Current Code:**
```swift
DispatchQueue.main.asyncAfter(deadline: .now() + debounceDelay) { [weak self] in
    // debounced work
}
```

**Mitigation:**
```swift
Task { @MainActor in
    try? await Task.sleep(for: .seconds(debounceDelay))
    // debounced work
}
```

**Effort Estimate:** 30 minutes

---

### CONC-002: Completion Handlers in Animation Context

| Property    | Value                                            |
| ----------- | ------------------------------------------------ |
| **Severity**  | MEDIUM                                           |
| **Files**     | `UI/Panels/DrawerPanelController.swift:119, 148` |
|             | `UI/Overlay/OverlayPanelController.swift:126`    |
| **Rule**      | "Completion handlers → async/await"              |

**Current Code:**
```swift
NSAnimationContext.runAnimationGroup({ context in
    // animation
}, completionHandler: { [weak self] in
    // completion
})
```

**Mitigation:**
Create an async wrapper extension:
```swift
extension NSAnimationContext {
    static func runAnimationGroup(_ changes: @escaping () -> Void) async {
        await withCheckedContinuation { continuation in
            runAnimationGroup(changes) { continuation.resume() }
        }
    }
}
```

**Effort Estimate:** 1 hour

---

### CONC-003: Missing Task.isCancelled Check in IconCapturer

| Property    | Value                              |
| ----------- | ---------------------------------- |
| **Severity**  | HIGH                               |
| **File**      | `Core/Engines/IconCapturer.swift:402` |
| **Rule**      | "Always check Task.isCancelled"    |

**Current Code:**
```swift
while currentX + iconWidthPixels <= imageWidth {
    // slicing loop - no cancellation check
}
```

**Mitigation:**
```swift
while currentX + iconWidthPixels <= imageWidth {
    guard !Task.isCancelled else { break }
    // slicing loop
}
```

**Effort Estimate:** 15 minutes

---

### CONC-004: Missing Task.isCancelled Check in IconRepositioner

| Property    | Value                                 |
| ----------- | ------------------------------------- |
| **Severity**  | HIGH                                  |
| **File**      | `Core/Engines/IconRepositioner.swift:479` |
| **Rule**      | "Always check Task.isCancelled"       |

**Current Code:**
```swift
while ContinuousClock.now < deadline {
    // polling loop - no cancellation check
}
```

**Mitigation:**
```swift
while ContinuousClock.now < deadline {
    guard !Task.isCancelled else { break }
    // polling loop
}
```

**Effort Estimate:** 15 minutes

---

## 3. Accessibility Violations

> **Rule Reference:** `rules/rules_swift.md` Section 3

### A11Y-001: onTapGesture Without Button Alternative

| Property    | Value                              |
| ----------- | ---------------------------------- |
| **Severity**  | HIGH                               |
| **File**      | `UI/Panels/DrawerContentView.swift:177, 288` |
| **Rule**      | "Replace onTapGesture with Button" |

**Current Code:**
```swift
DrawerItemView(item: item)
    .onTapGesture {
        onItemTap?(item)
    }
```

**Issue:**  
`onTapGesture` does not support VoiceOver, keyboard navigation, or eye-tracking. Interactive elements must use `Button`.

**Mitigation:**
```swift
Button {
    onItemTap?(item)
} label: {
    DrawerItemView(item: item)
}
.buttonStyle(.plain)
.accessibilityLabel(item.name ?? "Menu bar icon \(item.index)")
```

**Effort Estimate:** 1 hour

---

## 4. Type Safety / Security Violations

> **Rule Reference:** `rules/rules_swift.md` Section 4, `rules/security.md`

### SEC-001: Force Unwrap of CGEventField

| Property    | Value                                 |
| ----------- | ------------------------------------- |
| **Severity**  | MEDIUM                                |
| **File**      | `Core/Engines/IconRepositioner.swift:86` |
| **Rule**      | "NO force unwraps in production"      |

**Current Code:**
```swift
static let windowID = CGEventField(rawValue: 0x33)!
```

**Mitigation:**
```swift
static let windowID: CGEventField = {
    guard let field = CGEventField(rawValue: 0x33) else {
        fatalError("CGEventField windowID (0x33) unavailable on this system")
    }
    return field
}()
```

**Effort Estimate:** 15 minutes

---

### SEC-002: Force Unwrap of URL

| Property    | Value                       |
| ----------- | --------------------------- |
| **Severity**  | LOW                         |
| **File**      | `UI/Settings/AboutView.swift:13` |
| **Rule**      | "NO force unwraps"          |

**Current Code:**
```swift
private static let githubURL = URL(string: "https://github.com/dwarvesf/hidden")!
```

**Mitigation:**
```swift
private static let githubURL = URL(string: "https://github.com/dwarvesf/hidden")
// Handle optional in usage, or use static fatalError pattern
```

**Effort Estimate:** 10 minutes

---

### SEC-003: Implicitly Unwrapped Optionals in MenuBarManager

| Property    | Value                              |
| ----------- | ---------------------------------- |
| **Severity**  | MEDIUM                             |
| **File**      | `Core/Managers/MenuBarManager.swift:38, 41` |
| **Rule**      | "NO force unwraps"                 |

**Current Code:**
```swift
private(set) var hiddenSection: MenuBarSection!
private(set) var visibleSection: MenuBarSection!
```

**Mitigation:**
Convert to non-optional with guaranteed initialization:
```swift
private(set) var hiddenSection: MenuBarSection
private(set) var visibleSection: MenuBarSection

init() {
    hiddenSection = MenuBarSection(type: .hidden)
    visibleSection = MenuBarSection(type: .visible)
    // ... rest of init
}
```

**Effort Estimate:** 1 hour

---

## 5. Swift/SwiftUI Deprecated APIs

> **Rule Reference:** `rules/rules_swift.md` Section 1

### DEP-001: foregroundColor() Usage (15 instances)

| Property    | Value                                                                                              |
| ----------- | -------------------------------------------------------------------------------------------------- |
| **Severity**  | MEDIUM                                                                                             |
| **Files**     | `UI/Settings/SettingsMenuBarLayoutView.swift:151, 155, 183, 192, 216, 230, 792, 796, 908, 1031`   |
|             | `UI/Panels/DrawerContentView.swift:192, 205, 209, 233, 272`                                        |
| **Rule**      | "foregroundColor() → foregroundStyle()"                                                            |

**Mitigation:**
Global find/replace: `.foregroundColor(` → `.foregroundStyle(`

**Effort Estimate:** 30 minutes

---

### DEP-002: cornerRadius() Usage (1 instance)

| Property    | Value                                    |
| ----------- | ---------------------------------------- |
| **Severity**  | LOW                                      |
| **File**      | `UI/Settings/GeneralSettingsView.swift:103` |
| **Rule**      | "cornerRadius() → clipShape()"           |

**Current Code:**
```swift
.cornerRadius(4)
```

**Mitigation:**
```swift
.clipShape(.rect(cornerRadius: 4))
```

**Effort Estimate:** 10 minutes

---

### DEP-003: ObservableObject / @Published Usage (13 classes)

| Property    | Value                                           |
| ----------- | ----------------------------------------------- |
| **Severity**  | MEDIUM                                          |
| **Rule**      | "ObservableObject → @Observable macro"          |

**Affected Classes:**

| File                                     | Class                  |
| ---------------------------------------- | ---------------------- |
| `App/AppState.swift`                       | `AppState`               |
| `Core/Managers/SettingsManager.swift`      | `SettingsManager`        |
| `Core/Managers/MenuBarManager.swift`       | `MenuBarManager`         |
| `Core/Managers/PermissionManager.swift`    | `PermissionManager`      |
| `Core/Managers/DrawerManager.swift`        | `DrawerManager`          |
| `Core/Managers/HoverManager.swift`         | `HoverManager`           |
| `Core/Managers/OverlayModeManager.swift`   | `OverlayModeManager`     |
| `Core/Managers/LaunchAtLoginManager.swift` | `LaunchAtLoginManager`   |
| `Core/Engines/IconCapturer.swift`          | `IconCapturer`           |
| `Core/Models/ControlItem.swift`            | `ControlItem`            |
| `Core/Models/MenuBarSection.swift`         | `MenuBarSection`         |
| `UI/Panels/DrawerPanelController.swift`    | `DrawerPanelController`  |
| `UI/Overlay/OverlayPanelController.swift`  | `OverlayPanelController` |

**Mitigation Strategy:**
This is a significant refactoring effort that requires a dedicated spec. Changes include:
1. Replace `ObservableObject` protocol with `@Observable` macro
2. Remove `@Published` property wrappers
3. Update `@ObservedObject` to use new property wrapper patterns
4. Update `@EnvironmentObject` to `@Environment`

**Effort Estimate:** 8 hours (requires separate spec)

---

### DEP-004: Hardcoded Font Sizes (18 instances)

| Property    | Value                                                                                                        |
| ----------- | ------------------------------------------------------------------------------------------------------------ |
| **Severity**  | MEDIUM                                                                                                       |
| **Files**     | `UI/Settings/SettingsMenuBarLayoutView.swift:154, 182, 215, 229, 237, 246, 791, 795, 907, 1030`             |
|             | `UI/Panels/DrawerContentView.swift:191, 204, 208, 232, 271`                                                  |
|             | `UI/Onboarding/TutorialStepView.swift:29`                                                                    |
|             | `UI/Onboarding/CompletionStepView.swift:42`                                                                  |
|             | `UI/Onboarding/PermissionsStepView.swift:33`                                                                 |
| **Rule**      | "NO hardcoded fonts - use Dynamic Type"                                                                      |

**Current Code Examples:**
```swift
.font(.system(size: 12))
.font(.system(size: 11, weight: .medium))
.font(.system(size: 48))
```

**Mitigation:**
Replace with Dynamic Type styles:

| Hardcoded Size | Dynamic Type Replacement |
| -------------- | ------------------------ |
| 10-11          | `.caption2`                |
| 12             | `.caption`                 |
| 13             | `.footnote`                |
| 14-15          | `.subheadline`             |
| 16-17          | `.body`                    |
| 18-20          | `.title3`                  |
| 24-28          | `.title2`                  |
| 34+            | `.title` or `.largeTitle`    |
| 48+            | `.largeTitle`              |

**Effort Estimate:** 3 hours

---

### DEP-005: GeometryReader Usage (1 instance)

| Property    | Value                                        |
| ----------- | -------------------------------------------- |
| **Severity**  | LOW                                          |
| **File**      | `UI/Settings/SettingsMenuBarLayoutView.swift:816` |
| **Rule**      | "Prefer visualEffect() or containerRelativeFrame()" |

**Mitigation:**
Evaluate if `containerRelativeFrame()` or `visualEffect()` can replace the `GeometryReader`. If spatial layout is truly needed, document the exception.

**Effort Estimate:** 1 hour (investigation)

---

## 6. Architecture / Code Hygiene

> **Rule Reference:** `rules/architecture.md`

### ARCH-001: Multiple Types Per File (8 files)

| Property    | Value                                        |
| ----------- | -------------------------------------------- |
| **Severity**  | MEDIUM                                       |
| **Rule**      | "One type per file"                          |

**Affected Files:**

| File                                        | Types                                              | Lines |
| ------------------------------------------- | -------------------------------------------------- | ----- |
| `UI/Settings/SettingsMenuBarLayoutView.swift` | 5+ (LayoutSectionView, ItemFramePreferenceKey, etc.) | 1081  |
| `UI/Panels/DrawerContentView.swift`           | 5+ (DrawerItemView, SectionHeader, IconRow, etc.)  | 350+  |
| `UI/Overlay/OverlayContentView.swift`         | 5+ (OverlayIconView, OverlayBackground, etc.)      | 200+  |
| `UI/Components/PermissionStatusView.swift`    | 3 (PermissionRow, PermissionBadge)                 | 100+  |
| `UI/Onboarding/*.swift`                       | 2+ each (internal private structs)                 | Varies |

**Mitigation:**
Extract sub-views to separate files:
- `SettingsMenuBarLayoutView.swift` → `LayoutSectionView.swift`, `LayoutItemView.swift`, `DropPositionDelegate.swift`
- `DrawerContentView.swift` → `DrawerItemView.swift`, `SectionHeader.swift`, `IconRow.swift`

**Effort Estimate:** 6 hours

---

### ARCH-002: Business Logic in Views

| Property    | Value                                            |
| ----------- | ------------------------------------------------ |
| **Severity**  | MEDIUM                                           |
| **File**      | `UI/Settings/SettingsMenuBarLayoutView.swift:351-571` |
| **Rule**      | "Views contain only UI, logic in Services"       |

**Issue:**
The view contains repositioning and destination calculation logic (`performReposition`, `calculateDestination`, `getSectionItems`) that should be in a ViewModel or Service.

**Mitigation:**
Create `MenuBarLayoutViewModel.swift` and move business logic there.

**Effort Estimate:** 4 hours

---

## 7. Testing Gaps

> **Rule Reference:** `rules/testing.md`

### TEST-001: Missing DrawerUITests Target

| Property    | Value                       |
| ----------- | --------------------------- |
| **Severity**  | MEDIUM                      |
| **Issue**     | No UI test target exists    |
| **Rule**      | "E2E (10%): Critical flows" |

**Mitigation:**
1. Create `DrawerUITests/` target in Xcode project
2. Add XCUITest for critical flows:
   - App launch → permissions check
   - Toggle drawer visibility
   - Click-through behavior

**Effort Estimate:** 4 hours

---

### TEST-002: Missing Tests for UI Panels

| Property    | Value                                             |
| ----------- | ------------------------------------------------- |
| **Severity**  | MEDIUM                                            |
| **Files**     | `DrawerPanelController`, `DrawerContentView`        |
| **Rule**      | "Unit (60%): Pure functions, Utils"               |

**Mitigation:**
Add unit tests for:
- `DrawerPanelController` state transitions (show/hide/toggle)
- Panel positioning logic

**Effort Estimate:** 3 hours

---

### TEST-003: IconCapturerTests Mocks Internal Logic

| Property    | Value                                       |
| ----------- | ------------------------------------------- |
| **Severity**  | MEDIUM                                      |
| **File**      | `DrawerTests/Core/Engines/IconCapturerTests.swift` |
| **Rule**      | "Do NOT mock internal Service/Repo logic"  |

**Issue:**
`MockIconCapturer` mocks the internal engine state instead of the system boundary (`ScreenCaptureKit`).

**Mitigation:**
Create protocol-based abstraction for `SCStream` and `SCShareableContent` to mock at the correct boundary.

**Effort Estimate:** 3 hours

---

### TEST-004: Missing Edge Case Tests

| Property    | Value                          |
| ----------- | ------------------------------ |
| **Severity**  | LOW                            |
| **File**      | `DrawerTests/Core/Managers/MenuBarManagerTests.swift` |
| **Rule**      | Testing pyramid coverage       |

**Missing Scenarios:**
- Multiple display configuration changes
- Menu bar crash/restart recovery
- Rapid toggle cycling

**Effort Estimate:** 2 hours

---

### TEST-005: @Observable Migration Test Updates

| Property    | Value                                        |
| ----------- | -------------------------------------------- |
| **Severity**  | MEDIUM                                       |
| **Issue**     | When DEP-003 is resolved, tests need updates |

**Mitigation:**
After `@Observable` migration, update all tests that rely on `ObservableObject` patterns:
- Update `@ObservedObject` usage in test views
- Verify `@Published` replacement works correctly
- Update mock implementations

**Effort Estimate:** 2 hours (dependent on DEP-003)

---

## 8. Logging / Documentation

> **Rule Reference:** `rules/logging.md`, `rules/documentation.md`

### LOG-001: print() Statement in Production Code

| Property    | Value                               |
| ----------- | ----------------------------------- |
| **Severity**  | LOW                                 |
| **File**      | `UI/Panels/DrawerContentView.swift:343` |
| **Rule**      | "print() is FORBIDDEN"              |

**Current Code:**
```swift
print("Tapped item \(item.index)")
```

**Mitigation:**
```swift
Self.logger.debug("Tapped item \(item.index)")
```

**Effort Estimate:** 5 minutes

---

### DOC-001: Stale Comment (Phase 1/Phase 2)

| Property    | Value                                  |
| ----------- | -------------------------------------- |
| **Severity**  | LOW                                    |
| **File**      | `Core/Managers/PermissionManager.swift:77-78` |
| **Rule**      | "NO stale comments"                    |

**Current:**
```swift
/// - Note: Phase 1 only checks status; Phase 2 will require these permissions...
```

**Issue:** Phase 2 features are already implemented.

**Mitigation:**
Update to reflect current state or remove.

**Effort Estimate:** 10 minutes

---

### DOC-002: "What not Why" Comments (9 instances)

| Property    | Value                                             |
| ----------- | ------------------------------------------------- |
| **Severity**  | LOW                                               |
| **Files**     | `Core/Managers/MenuBarManager.swift:303, 307`       |
|             | `Core/Engines/IconRepositioner.swift:236, 254, 265, 270, 273, 277, 282` |
| **Rule**      | "Comment the Intent, not the Syntax"              |

**Examples:**
```swift
// Log positions       // ❌ Describes what
// Calculate points    // ❌ Describes what
```

**Mitigation:**
Either remove trivial comments or expand to explain "why".

**Effort Estimate:** 30 minutes

---

### DOC-003: Missing API Documentation (8 methods)

| Property    | Value                                                           |
| ----------- | --------------------------------------------------------------- |
| **Severity**  | LOW                                                             |
| **Files**     | `Core/Engines/IconCapturer.swift:111, 184, 434`                   |
|             | `Core/Managers/PermissionManager.swift:150, 156, 163, 214`        |
| **Rule**      | "API Documentation required"                                    |

**Missing Docs For:**
- `IconCapturer.captureHiddenIcons()`
- `IconCapturer.captureMenuBarRegion()`
- `IconCapturer.clearLastCapture()`
- `PermissionManager.refreshAllStatuses()`
- `PermissionManager.refreshAccessibilityStatus()`
- `PermissionManager.refreshScreenRecordingStatus()`
- `PermissionManager.request(_:)`

**Mitigation:**
Add `///` documentation blocks to these public API methods.

**Effort Estimate:** 2 hours

---

## 9. Remediation Priority Matrix

### Phase 1: Critical (Immediate - This Week)

| ID       | Issue                                 | Files   | Effort   |
| -------- | ------------------------------------- | ------- | -------- |
| BUG-001  | Drawer not aligned to separator       | 2       | 2 hours  |
| CONC-003 | Missing Task.isCancelled in IconCapturer | 1       | 15 min   |
| CONC-004 | Missing Task.isCancelled in IconRepositioner | 1       | 15 min   |
| CONC-001 | DispatchQueue.main.asyncAfter           | 1       | 30 min   |
| A11Y-001 | onTapGesture without Button           | 1       | 1 hour   |
| SEC-003  | IUOs in MenuBarManager                | 1       | 1 hour   |
| **TOTAL**  |                                       |         | **5 hrs**  |

### Phase 2: High Priority (This Sprint)

| ID       | Issue                           | Files   | Effort   |
| -------- | ------------------------------- | ------- | -------- |
| DEP-001  | Replace foregroundColor()       | 2       | 30 min   |
| DEP-002  | Replace cornerRadius()          | 1       | 10 min   |
| DEP-004  | Replace hardcoded fonts         | 5       | 3 hours  |
| SEC-001  | Force unwrap CGEventField       | 1       | 15 min   |
| SEC-002  | Force unwrap URL                | 1       | 10 min   |
| TEST-001 | Create DrawerUITests target     | New     | 4 hours  |
| DOC-003  | Add API documentation           | 2       | 2 hours  |
| **TOTAL**  |                                 |         | **10 hrs** |

### Phase 3: Medium Priority (Next Sprint)

| ID       | Issue                               | Files   | Effort   |
| -------- | ----------------------------------- | ------- | -------- |
| DEP-003  | Migrate to @Observable              | 13      | 8 hours  |
| ARCH-001 | Extract multiple types per file     | 8       | 6 hours  |
| ARCH-002 | Move logic from Views to ViewModels | 1       | 4 hours  |
| CONC-002 | Wrap NSAnimationContext in async    | 2       | 1 hour   |
| TEST-002 | Add UI Panel tests                  | 2       | 3 hours  |
| TEST-003 | Fix IconCapturer mock boundaries    | 1       | 3 hours  |
| TEST-005 | Update tests after @Observable      | Multiple | 2 hours  |
| **TOTAL**  |                                     |         | **27 hrs** |

### Phase 4: Low Priority (Backlog)

| ID       | Issue                           | Files   | Effort   |
| -------- | ------------------------------- | ------- | -------- |
| LOG-001  | Remove print() statement        | 1       | 5 min    |
| DOC-001  | Update stale Phase 1/2 comment  | 1       | 10 min   |
| DOC-002  | Clean up "what" comments        | 2       | 30 min   |
| DEP-005  | Evaluate GeometryReader         | 1       | 1 hour   |
| TEST-004 | Add edge case tests             | 1       | 2 hours  |
| **TOTAL**  |                                 |         | **4 hrs**  |

---

## Appendix: Rule Files Referenced

| Rule File                    | Categories Covered                    |
| ---------------------------- | ------------------------------------- |
| `rules/rules_swift.md`         | DEP-001 to DEP-005, SEC-001 to SEC-003, A11Y-001 |
| `rules/rules_swift_concurrency.md` | CONC-001 to CONC-004                    |
| `rules/architecture.md`        | ARCH-001, ARCH-002                    |
| `rules/testing.md`             | TEST-001 to TEST-005                  |
| `rules/logging.md`             | LOG-001                               |
| `rules/documentation.md`       | DOC-001 to DOC-003                    |
| `rules/security.md`            | SEC-001 to SEC-003                    |

---

## Next Steps

1. **Immediate:** Address Phase 1 critical issues (BUG-001, CONC-003/004, A11Y-001)
2. **Create Spec:** DEP-003 (@Observable migration) requires a dedicated specification document
3. **Sprint Planning:** Add Phase 2 items to current sprint backlog
4. **Tracking:** Create individual tickets/issues for each item as needed

---

*Report generated by OpenCode comprehensive code review.*
