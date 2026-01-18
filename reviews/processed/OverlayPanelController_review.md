<!-- Review: OverlayPanelController.swift -->

# Code Review: OverlayPanelController.swift

**File**: `Drawer/UI/Overlay/OverlayPanelController.swift`  
**Reviewer**: Ralphus  
**Date**: 2026-01-18  
**Result**: PASSED (0 critical, 0 high, 1 medium, 0 low, 3 info)

---

## [MEDIUM] Force Unwrap May Crash if No Screens Available

> Force unwrapping `NSScreen.screens.first!` can crash if screen array is empty.

**File**: `Drawer/UI/Overlay/OverlayPanelController.swift:76`  
**Category**: Correctness  
**Severity**: Medium  

### Description

When both `screen` parameter is nil and `NSScreen.main` is nil, the code falls back to `NSScreen.screens.first!`. While extremely rare (would require running headless or during display reconfiguration), this force unwrap could cause a crash.

The sibling `DrawerPanelController` handles this more gracefully with an early return guard.

### Current Code

```swift
let targetScreen = screen ?? NSScreen.main ?? NSScreen.screens.first!
```

### Suggested Fix

```swift
guard let targetScreen = screen ?? NSScreen.main ?? NSScreen.screens.first else {
    logger.warning("No screen available for overlay panel")
    return
}
```

### Verification

1. Code inspection - verify guard-let pattern used
2. Test by simulating `NSScreen.screens` returning empty (unit test with mock)

---

## [INFO] Missing Animation Guard May Cause Visual Glitches

> No guard against concurrent show/hide animations unlike sibling controller.

**File**: `Drawer/UI/Overlay/OverlayPanelController.swift:70-128`  
**Category**: Maintainability  
**Severity**: Info  

### Description

`DrawerPanelController` uses an `isAnimating` flag to prevent overlapping show/hide calls. `OverlayPanelController` lacks this, which could cause animation glitches if `show()` and `hide()` are called in rapid succession.

This is low-risk since the overlay is typically controlled by mouse hover events which are debounced upstream, but adding the guard would provide defense-in-depth.

### Current Code

```swift
func show(...) {
    // No animation guard
    ...
}

func hide() {
    guard let panel = panel, isVisible else { return }
    // No animation guard
    ...
}
```

### Suggested Fix

```swift
private var isAnimating: Bool = false

func show(...) {
    guard !isAnimating else { return }
    isAnimating = true
    ...
    NSAnimationContext.runAnimationGroup { [showDuration] context in
        context.duration = showDuration
        panel.animator().alphaValue = 1
    } completionHandler: { [weak self] in
        self?.isAnimating = false
    }
    ...
}
```

### Verification

1. Rapidly trigger show/hide to verify no visual glitches

---

## [INFO] deinit Not Isolated to MainActor

> Swift 6 may warn about non-isolated deinit accessing MainActor-isolated properties.

**File**: `Drawer/UI/Overlay/OverlayPanelController.swift:159-161`  
**Category**: Correctness  
**Severity**: Info  

### Description

The class is `@MainActor`, but `deinit` is not isolated. Calling `panel?.close()` in deinit may produce warnings in Swift 6 strict concurrency mode. The `cleanup()` method is the intended cleanup path, so this deinit call is a safety net.

### Current Code

```swift
deinit {
    panel?.close()
}
```

### Suggested Fix

The current pattern is acceptable since `panel?.close()` is safe to call and deinit should only occur when object is unreachable. However, for Swift 6 compliance, consider:

```swift
deinit {
    // Panel cleanup handled via cleanup() method
    // Explicit close removed for Swift 6 MainActor isolation compliance
}
```

Or alternatively, dispatch to main:

```swift
deinit {
    let panelToClose = panel
    Task { @MainActor in
        panelToClose?.close()
    }
}
```

### Verification

1. Build with `-strict-concurrency=complete` flag
2. Verify no warnings on deinit

---

## [INFO] Inconsistent Naming: cleanup() vs dispose()

> Method naming differs from sibling DrawerPanelController.

**File**: `Drawer/UI/Overlay/OverlayPanelController.swift:152`  
**Category**: Maintainability  
**Severity**: Info  

### Description

`OverlayPanelController` uses `cleanup()` while `DrawerPanelController` uses `dispose()`. Consistency aids maintainability.

### Verification

Consider standardizing on one naming convention across panel controllers. No immediate action required.

---

## Summary

The `OverlayPanelController` is well-structured and follows good patterns:

- Proper `@MainActor` annotation for thread safety
- Lazy panel creation for resource efficiency
- Correct `[weak self]` usage in animation completion handlers
- Clear documentation and MARK sections
- Appropriate separation of concerns

**Findings:**
- 1 Medium: Force unwrap on screen fallback
- 3 Info: Animation guard, deinit isolation, naming consistency

**Missing Test Coverage**: No unit tests found for `OverlayPanelController`. Consider adding tests for show/hide lifecycle.

**Recommendation**: Address the medium-severity force unwrap issue. Info items are optional improvements.
