# IconCapturer.swift Code Review

**File**: `Drawer/Core/Engines/IconCapturer.swift`  
**Reviewer**: Ralphus  
**Date**: 2026-01-17  
**Result**: PASSED (0 critical, 0 high, 2 low, 1 info)

---

## Summary

IconCapturer is a well-structured ScreenCaptureKit-based component that captures menu bar icons for display in the Drawer panel. The implementation properly gates all capture operations behind TCC permission checks, uses dependency injection for testability, and includes appropriate fallback mechanisms.

**Verdict**: No blocking issues. Ready for production use.

---

## Findings

### [LOW] Off-by-One in Icon Slicing Limit

> The 50-icon limit breaks after the 51st icon, not at 50

**File**: `Drawer/Core/Engines/IconCapturer.swift:418`  
**Category**: Correctness  
**Severity**: Low  

#### Description

The icon slicing limit uses `if icons.count > 50` which allows 51 icons before breaking. The test at `IconCapturerTests.swift:261-264` acknowledges this but it's inconsistent with the logged "Hit icon limit (50)".

#### Current Code

```swift
if icons.count > 50 {
    logger.warning("Hit icon limit (50), stopping slice")
    break
}
```

#### Suggested Fix

```swift
if icons.count >= 50 {
    logger.warning("Hit icon limit (50), stopping slice")
    break
}
```

#### Verification

1. Update test ICN-007 to expect exactly 50 icons
2. Verify legacy fallback still works correctly

---

### [LOW] Public Constants Could Be Private

> Instance-level constants should be encapsulated

**File**: `Drawer/Core/Engines/IconCapturer.swift:381-382`  
**Category**: Maintainability  
**Severity**: Low  

#### Description

`standardIconWidth` and `iconSpacing` are declared as public `let` properties but are only meaningful for internal icon slicing logic.

#### Current Code

```swift
let standardIconWidth: CGFloat = 22
let iconSpacing: CGFloat = 4
```

#### Suggested Fix

```swift
private let standardIconWidth: CGFloat = 22
private let iconSpacing: CGFloat = 4
```

Or extract to a private enum:

```swift
private enum SlicingConstants {
    static let standardIconWidth: CGFloat = 22
    static let iconSpacing: CGFloat = 4
}
```

#### Verification

1. Verify `sliceIconsUsingFixedWidth` tests still pass (they don't depend on these constants directly)
2. Run full test suite

---

### [INFO] Missing Test Coverage for determineSectionType

> Section type detection logic has no unit tests

**File**: `Drawer/Core/Engines/IconCapturer.swift:442-460`  
**Category**: Testing  
**Severity**: Info  

#### Description

The `determineSectionType(for:hiddenSeparatorX:alwaysHiddenSeparatorX:)` method contains branching logic for assigning icons to `.alwaysHidden`, `.hidden`, or `.visible` sections. This logic is not covered by unit tests.

#### Suggested Fix

Add tests for:
- Icon left of alwaysHiddenSeparatorX returns `.alwaysHidden`
- Icon left of hiddenSeparatorX (no alwaysHidden) returns `.hidden`
- Icon right of hiddenSeparatorX returns `.visible`
- Edge case: icon exactly at separator boundary

```swift
func testDetermineSectionType_AlwaysHidden() {
    let capturer = IconCapturer()
    let frame = CGRect(x: 100, y: 0, width: 22, height: 24)
    let type = capturer.determineSectionType(
        for: frame, 
        hiddenSeparatorX: 300, 
        alwaysHiddenSeparatorX: 200
    )
    XCTAssertEqual(type, .alwaysHidden)
}
```

#### Verification

1. Add unit tests for all branches
2. Run test suite

---

## Review Checklist Results

### Security (P0) - PASSED
- [x] Screen Recording permission checked before capture (line 124)
- [x] Secondary permission check in `captureMenuBarRegion` (line 181)
- [x] No hardcoded secrets
- [x] Debug logging only in DEBUG builds
- [x] Captured images stored in memory only, not persisted

### Correctness (P1) - PASSED
- [x] Proper defer pattern for state cleanup (line 120)
- [x] Menu bar state restoration on error (line 165)
- [x] Fallback to legacy capture when window-based fails (line 215)
- [x] Concurrent capture prevention (line 112)
- [x] Well-defined error types with LocalizedError

### Performance (P2) - PASSED
- [x] Bounded loops with explicit limits
- [x] O(n) complexity where n = menu bar items
- [x] Efficient batch capture via ScreenCapture.captureMenuBarItems
- [x] No memory leaks (CGImage is value-typed/refcounted)

### Maintainability (P3) - PASSED
- [x] Follows AGENTS.md conventions
- [x] Proper MARK comments
- [x] @MainActor for thread safety
- [x] Dependency injection for testability
- [x] No dead code or commented blocks

### Testing (P4) - PASSED
- [x] 11 unit tests covering core functionality
- [x] MockPermissionManager for DI testing
- [x] Initial state, error paths, and edge cases covered
- [x] Some gaps for platform-dependent code (acceptable)

---

## References

- [ScreenCaptureKit Documentation](https://developer.apple.com/documentation/screencapturekit)
- AGENTS.md: Core Engines marked as HIGH risk
- Related files: `ScreenCapture.swift`, `PermissionManager.swift`
