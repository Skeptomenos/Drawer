# Code Review: SettingsManager.swift

**File**: `Drawer/Core/Managers/SettingsManager.swift`  
**Reviewer**: Ralphus  
**Date**: 2026-01-17  
**Verdict**: PASSED

## Summary

| Category | Status |
|----------|--------|
| Security | PASSED |
| Correctness | PASSED |
| Performance | PASSED |
| Maintainability | PASSED |
| Testing | PASSED |

**Total Findings**: 0 critical, 0 high, 0 medium, 0 low, 2 info

---

## [INFO] hasCompletedOnboarding Not Reset by resetToDefaults

> The onboarding flag is preserved during settings reset

**File**: `Drawer/Core/Managers/SettingsManager.swift:178-194`  
**Category**: Maintainability  
**Severity**: Info  

### Description

The `resetToDefaults()` method does not reset the `hasCompletedOnboarding` flag. This appears to be intentional behavior - onboarding should only be shown once per install, not after a settings reset.

If a user wants to re-see onboarding, they would need to manually clear the app's preferences or reinstall.

### Current Code

```swift
func resetToDefaults() {
    autoCollapseEnabled = true
    autoCollapseDelay = 10.0
    launchAtLogin = false
    hideSeparators = false
    alwaysHiddenSectionEnabled = false
    useFullStatusBarOnExpand = false
    showOnHover = false
    globalHotkey = nil
    // Gesture triggers
    showOnScrollDown = true
    hideOnScrollUp = true
    hideOnClickOutside = true
    hideOnMouseAway = true
    // Overlay mode
    overlayModeEnabled = false
    // NOTE: hasCompletedOnboarding is NOT reset - intentional
}
```

### Verification

This is informational only. No action required unless requirements change.

---

## [INFO] No Bounds Validation on autoCollapseDelay

> The auto-collapse delay accepts any Double value

**File**: `Drawer/Core/Managers/SettingsManager.swift:30-31`  
**Category**: Correctness  
**Severity**: Info  

### Description

The `autoCollapseDelay` property is stored as a raw `Double` without bounds validation. Theoretically, a negative value or extremely large value could be set. However:

1. The UI layer (slider) constrains the value to sensible bounds
2. The timer logic in DrawerManager handles any positive value
3. Setting this programmatically would require intentional misuse

This is a defense-in-depth consideration, not a bug.

### Current Code

```swift
@AppStorage("autoCollapseDelay") var autoCollapseDelay: Double = 10.0 {
    didSet { autoCollapseDelaySubject.send(autoCollapseDelay) }
}
```

### Suggested Fix (Optional)

If stricter validation is desired:

```swift
@AppStorage("autoCollapseDelay") private var _autoCollapseDelay: Double = 10.0

var autoCollapseDelay: Double {
    get { _autoCollapseDelay }
    set {
        let clamped = max(1.0, min(300.0, newValue)) // 1-300 seconds
        _autoCollapseDelay = clamped
        autoCollapseDelaySubject.send(clamped)
    }
}
```

### Verification

No action required. UI already constrains values.

---

## Checklist Results

### Security (P0) - PASSED
- [x] No hardcoded secrets
- [x] No sensitive data logging
- [x] Settings stored in UserDefaults (standard practice)
- [x] GlobalHotkeyConfig validation occurs at UI capture time

### Correctness (P1) - PASSED
- [x] @AppStorage properly persists settings
- [x] Combine subjects fire on property changes
- [x] globalHotkey encoding/decoding handles failures gracefully
- [x] resetToDefaults restores all user-facing settings

### Performance (P2) - PASSED
- [x] Singleton pattern is appropriate for app-lifetime settings
- [x] PassthroughSubjects are lightweight
- [x] No expensive operations in property observers

### Maintainability (P3) - PASSED
- [x] Clear MARK sections organize code
- [x] Descriptive comments on each setting
- [x] Follows project naming conventions
- [x] Uses @MainActor per AGENTS.md guidelines

### Testing (P4) - PASSED
- [x] SettingsManagerTests.swift has 15 comprehensive tests
- [x] Tests cover default values, reset behavior, Combine publishers
- [x] Tests verify globalHotkey roundtrip encoding/decoding
- [x] Tests properly reset state between runs

---

## Recommendations

1. **Consider adding a "Reset Onboarding" developer option** for testing purposes (could be hidden behind a debug flag).

2. **Document the intentional exclusion of hasCompletedOnboarding** from reset with a code comment.

---

## Notes

This is a well-architected settings manager that follows Swift/SwiftUI best practices:

- Uses `@AppStorage` for automatic persistence
- Uses Combine `PassthroughSubject` for reactive updates
- Singleton pattern is appropriate for app-wide settings
- Clean separation between primitive settings and complex types (GlobalHotkeyConfig)

No changes required.
