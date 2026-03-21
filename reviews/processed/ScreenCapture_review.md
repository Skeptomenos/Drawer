# ScreenCapture.swift Review

**File**: `Drawer/Utilities/ScreenCapture.swift`  
**Reviewer**: Ralphus  
**Date**: 2026-01-17  
**Result**: PASSED (0 critical, 0 high, 2 low, 2 info)

---

## Summary

ScreenCapture.swift provides utilities for capturing screen content, specifically menu bar items. It wraps the deprecated `CGWindowListCreateImage` API and includes permission checking logic. The code is well-structured with proper memory management and caching.

**Key Observations**:
- Appropriately marked deprecated CGWindowListCreateImage usage
- Permission caching improves performance
- Proper pointer memory management with `defer`
- Silent failure mode (returns nil/empty) - acceptable for utility code

---

## [LOW] No Dedicated Unit Tests

> Test coverage for ScreenCapture utilities is indirect

**File**: `Drawer/Utilities/ScreenCapture.swift`  
**Category**: Testing  
**Severity**: Low  

### Description

ScreenCapture.swift has no dedicated test file. While its functionality is exercised through IconCapturer tests, direct unit tests would improve confidence in:
- Permission check logic (the menu bar item title check)
- Cache invalidation behavior
- Edge cases in `captureMenuBarItems`

### Suggested Action

Create `DrawerTests/Utilities/ScreenCaptureTests.swift` covering:
1. `checkPermissions()` behavior with mock menu bar items
2. `cachedCheckPermissions()` caching and invalidation
3. `captureWindows` empty array handling

### Verification

Run: `xcodebuild test -scheme Drawer -destination 'platform=macOS' -only-testing:DrawerTests/Utilities/ScreenCaptureTests`

---

## [LOW] Strict Width Validation May Reject Valid Captures

> Floating-point comparison may cause false rejections

**File**: `Drawer/Utilities/ScreenCapture.swift:110-111`  
**Category**: Correctness  
**Severity**: Low  

### Description

The exact equality check between `CGFloat(compositeImage.width)` and `expectedWidth` may fail due to floating-point precision issues on some display configurations.

### Current Code

```swift
let expectedWidth = unionFrame.width * backingScaleFactor
guard CGFloat(compositeImage.width) == expectedWidth else {
    return [:]
}
```

### Suggested Fix

Consider using a small tolerance or integer comparison:

```swift
let expectedWidth = Int(unionFrame.width * backingScaleFactor)
guard compositeImage.width == expectedWidth else {
    return [:]
}
```

### Verification

Test on various display configurations (Retina, scaled, external monitors).

---

## [INFO] Silent Failure Pattern

> Utility returns nil/empty on errors without logging

**File**: `Drawer/Utilities/ScreenCapture.swift:53-72, 100-107`  
**Category**: Maintainability  
**Severity**: Info  

### Description

Both `captureWindows` and `captureMenuBarItems` return nil/empty results on failure without logging. While acceptable for utility code (callers handle failures), debug logging could help troubleshoot capture issues.

### Observation

The code correctly handles failure scenarios:
- Empty windowIDs returns nil (line 54)
- Failed CFArrayCreate returns nil (line 63-65)
- Empty window list returns empty dict (line 100)
- Failed composite capture returns empty dict (line 102-107)

Consider adding os.log debug statements for easier troubleshooting if capture issues occur in production.

---

## [INFO] Permission Check Does Not Block Capture

> Permission helpers exist but are not enforced

**File**: `Drawer/Utilities/ScreenCapture.swift:19-46`  
**Category**: Security  
**Severity**: Info  

### Description

The file provides `checkPermissions()`, `cachedCheckPermissions()`, and `requestPermissions()` utilities, but `captureWindows` and `captureMenuBarItems` do not enforce permission checks. This is the expected pattern - callers (IconCapturer) are responsible for gating - but it's worth noting.

### Observation

This follows the separation of concerns principle. IconCapturer and other callers check permissions before invoking ScreenCapture utilities. The pattern is consistent with PermissionManager which was reviewed previously.

No action required - documenting for completeness.

---

## Checklist Results

### Security (P0)
- [x] No injection vulnerabilities
- [x] No hardcoded secrets
- [x] Sensitive data (screen content) handled appropriately
- [x] Permission utilities provided (enforcement is caller responsibility)

### Correctness (P1)
- [x] Logic is correct for permission detection
- [x] Edge cases handled (empty arrays, nil frames)
- [x] Memory properly managed (defer deallocate)
- [x] Types used correctly

### Performance (P2)
- [x] Permission result cached with invalidation
- [x] Loops bounded by window count
- [x] No memory leaks (pointer deallocated)

### Maintainability (P3)
- [x] Clear function names and structure
- [x] Deprecation annotation on legacy API
- [x] Follows project conventions
- [x] No dead code

### Testing (P4)
- [ ] No dedicated unit tests (covered indirectly via IconCapturer)

---

## Final Verdict

**PASSED** - No blocking issues. The code is well-written with proper memory management and appropriate use of deprecated APIs (marked accordingly). Low-priority items are suggestions for improvement, not blockers.
