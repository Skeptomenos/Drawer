# Code Review: Bridging.swift

**File**: `Drawer/Bridging/Bridging.swift`  
**Reviewer**: Ralphus  
**Date**: 2026-01-17  
**Result**: PASSED (0 critical, 0 high, 1 medium, 1 low, 2 info)

---

## Summary

This file provides Swift wrappers around private CGS (CoreGraphics Server) APIs for window enumeration, frame retrieval, and space detection. The implementation is clean, follows established patterns from the Ice project, and has proper error handling.

---

## [MEDIUM] TOCTOU Race Condition in Window List Allocation

> Window count and list retrieval have a potential race condition

**File**: `Drawer/Bridging/Bridging.swift:74-95`  
**Category**: Correctness  
**Severity**: Medium  

### Description

The `getAllWindowList()`, `getOnScreenWindowList()`, and `getMenuBarWindowList()` functions first call a count function, then allocate a buffer based on that count, then fill the buffer. If windows are created between the count and list calls, the CGS API could potentially write beyond the buffer.

However, the actual CGS APIs appear to respect the `maxCount` parameter and return `actualCount` which is used for slicing, mitigating buffer overflow. The risk is that newly created windows may be missed.

### Current Code

```swift
private static func getAllWindowList() -> [CGWindowID] {
    let count = getWindowCount()
    guard count > 0 else { return [] }

    var list = [CGWindowID](repeating: 0, count: count)
    var actualCount: Int32 = 0

    let result = CGSGetWindowList(
        CGSMainConnectionID(),
        0,
        Int32(count),
        &list,
        &actualCount
    )
    // ...
    return Array(list[..<Int(actualCount)])
}
```

### Suggested Fix

Consider adding a buffer margin or retry logic for critical use cases:

```swift
private static func getAllWindowList() -> [CGWindowID] {
    let count = getWindowCount()
    guard count > 0 else { return [] }

    // Add buffer margin to handle windows created between count and list calls
    let bufferSize = count + 10
    var list = [CGWindowID](repeating: 0, count: bufferSize)
    var actualCount: Int32 = 0

    let result = CGSGetWindowList(
        CGSMainConnectionID(),
        0,
        Int32(bufferSize),
        &list,
        &actualCount
    )
    // ...
    return Array(list[..<Int(actualCount)])
}
```

### Verification

1. Current behavior is safe due to `actualCount` slicing
2. This is a minor edge case for menu bar utilities
3. Ice uses the same pattern without issues

---

## [LOW] Unsafe Bit Cast in Space Enumeration

> `unsafeBitCast` used for CFArray value extraction

**File**: `Drawer/Bridging/Bridging.swift:191`  
**Category**: Correctness  
**Severity**: Low  

### Description

The `getSpacesForWindow` function uses `unsafeBitCast` to convert CFArray values to `CGSSpaceID`. While this matches Ice's implementation, it relies on undocumented ABI behavior.

### Current Code

```swift
for i in 0..<count {
    if let spaceNumber = CFArrayGetValueAtIndex(spacesArray, i) {
        let space = unsafeBitCast(spaceNumber, to: CGSSpaceID.self)
        spaces.append(space)
    }
}
```

### Suggested Fix

This is acceptable given the private API context. Document the assumption:

```swift
for i in 0..<count {
    if let spaceNumber = CFArrayGetValueAtIndex(spacesArray, i) {
        // Space IDs are stored as raw pointer values in the CFArray
        // This matches Ice's implementation pattern
        let space = unsafeBitCast(spaceNumber, to: CGSSpaceID.self)
        spaces.append(space)
    }
}
```

### Verification

1. Ice project uses identical pattern
2. Works correctly on macOS 14.0+
3. Private API usage is documented in AGENTS.md

---

## [INFO] Stub Function: isSpaceFullscreen

> Fullscreen detection not implemented

**File**: `Drawer/Bridging/Bridging.swift:201-205`  
**Category**: Maintainability  
**Severity**: Info  

### Description

The `isSpaceFullscreen` function is a stub that always returns `false`. This is documented in the code comment but could be tracked for future implementation.

### Current Code

```swift
static func isSpaceFullscreen(_ spaceID: CGSSpaceID) -> Bool {
    // Fullscreen spaces have specific characteristics
    // For now, return false - can be enhanced later
    return false
}
```

### Verification

1. Function is not currently used in critical paths
2. Can be implemented when fullscreen handling is needed
3. Consider removing if unused to avoid dead code

---

## [INFO] No Unit Tests for Bridging

> Private API wrappers lack unit test coverage

**File**: `Drawer/Bridging/Bridging.swift`  
**Category**: Testing  
**Severity**: Info  

### Description

The `Bridging` enum has no dedicated unit tests. This is understandable since CGS APIs require actual system context and are difficult to mock. However, integration tests or manual verification should be documented.

### Suggested Fix

Add a test file with basic smoke tests that verify the APIs don't crash:

```swift
// DrawerTests/Bridging/BridgingTests.swift
import XCTest
@testable import Drawer

final class BridgingTests: XCTestCase {
    func testGetWindowCountDoesNotCrash() {
        // Just verify it returns a non-negative number
        let count = Bridging.getWindowCount()
        XCTAssertGreaterThanOrEqual(count, 0)
    }
    
    func testGetWindowListDoesNotCrash() {
        // Verify it returns an array (may be empty)
        let list = Bridging.getWindowList()
        XCTAssertNotNil(list)
    }
    
    func testActiveSpaceIDDoesNotCrash() {
        // Verify it returns a valid space ID
        let spaceID = Bridging.activeSpaceID
        XCTAssertGreaterThan(spaceID, 0)
    }
}
```

### Verification

1. Tests would validate API compatibility across macOS versions
2. Helps catch regressions if CGS behavior changes

---

## Security Checklist

| Check | Status | Notes |
|-------|--------|-------|
| Input validation | N/A | No external input |
| Injection prevention | N/A | No SQL/XSS/command surface |
| Auth/authorization | N/A | System APIs handle access |
| No hardcoded secrets | Pass | No secrets present |
| Sensitive data handling | Pass | Only window metadata accessed |
| Permission gating | Pass | CGS APIs self-gate based on process permissions |

---

## Correctness Checklist

| Check | Status | Notes |
|-------|--------|-------|
| Logic correctness | Pass | Follows Ice's proven patterns |
| Edge cases | Pass | Empty arrays handled, errors logged |
| Error handling | Pass | All CGS calls check result codes |
| Types used correctly | Pass | Proper use of CGS types |
| Nullability | Pass | guard/optional handling throughout |

---

## Approval

**Verdict**: PASSED

No critical or high severity findings. The code is well-structured, follows established patterns from the Ice project, and has appropriate error handling. The medium severity TOCTOU issue is mitigated by the actual slicing behavior and is acceptable for this use case.
