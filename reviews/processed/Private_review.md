# Code Review: Private.swift

**File**: `Drawer/Bridging/Shims/Private.swift`  
**Reviewer**: Ralphus  
**Date**: 2026-01-17  
**Review Type**: Codebase Review

## Summary

| Category | Status | Findings |
|----------|--------|----------|
| Security | PASS | 0 issues |
| Correctness | PASS | 0 issues |
| Performance | PASS | 0 issues |
| Maintainability | PASS | 0 issues |
| Testing | INFO | 1 info |
| App Store Compliance | INFO | 1 info |

**Overall**: PASSED (0 critical, 0 high, 0 medium, 1 low, 1 info)

---

## File Overview

This file contains private CGS (CoreGraphics Server) API declarations using Swift's `@_silgen_name` attribute. These undocumented Apple APIs provide accurate window frame information for menu bar items, which is essential for the app's core functionality.

**Dependencies**:
- CoreGraphics (Apple framework)

**Used by**:
- `Bridging.swift` - Swift-friendly wrappers for these private APIs
- Indirectly by `WindowInfo.swift` and `ScreenCapture.swift`

**Attribution**: Based on [Ice](https://github.com/jordanbaird/Ice) implementation.

---

## Detailed Review

### Security (P0) - PASS

**Input Validation**
- [x] N/A - These are C function declarations, no inputs to validate at this level

**Injection Prevention**
- [x] No dynamic string construction
- [x] Fixed C function signatures

**Authentication & Authorization**
- [x] N/A - Low-level window APIs, system handles access control

**Secrets & Sensitive Data**
- [x] No hardcoded secrets
- [x] No sensitive data logging
- [x] Window enumeration only returns IDs and frames, not content

**Notes**: The APIs enumerate windows across all processes, which is the intended design for menu bar management. This capability is gated by macOS system permissions and is the same approach used by established apps like Bartender and Ice.

---

### Correctness (P1) - PASS

**Type Declarations**
- [x] `CGSConnectionID = UInt32` - Correct per private API
- [x] `CGSSpaceID = UInt64` - Correct per private API
- [x] `CGSError` struct with `RawRepresentable` - Proper error handling pattern

**Function Signatures**
All 9 `@_silgen_name` declarations verified against known private API signatures:

| Function | Status |
|----------|--------|
| `CGSMainConnectionID()` | Correct |
| `CGSGetWindowCount()` | Correct |
| `CGSGetWindowList()` | Correct |
| `CGSGetOnScreenWindowCount()` | Correct |
| `CGSGetOnScreenWindowList()` | Correct |
| `CGSGetProcessMenuBarWindowList()` | Correct |
| `CGSGetScreenRectForWindow()` | Correct |
| `CGSGetActiveSpace()` | Correct |
| `CGSCopySpacesForWindows()` | Correct |

**Constants**
- [x] `kCGSAllSpacesMask: Int32 = 0x7` - Correct
- [x] `kCGSCurrentSpaceMask: Int32 = 0x5` - Correct
- [x] `kCGStatusWindowLevel: Int = 25` - Correct

---

### Performance (P2) - PASS

- [x] Pure C function declarations - no performance concerns
- [x] Memory management handled correctly in `Bridging.swift` wrapper

---

### Maintainability (P3) - PASS

**Code Organization**
- [x] Well-organized with MARK comments separating sections
- [x] Clear file header with purpose and attribution
- [x] Consistent naming following Apple's private API conventions

**Documentation**
- [x] Header explains purpose and source attribution
- [x] Each section has MARK comments for navigation

**Code Cleanliness**
- [x] No dead code
- [x] No commented-out code
- [x] All declarations are used via Bridging.swift

---

### Testing (P4) - INFO

**Current State**:
- No dedicated unit tests for Private.swift or Bridging.swift
- WindowInfoTests indirectly validates `kCGStatusWindowLevel` constant

**Recommendation**:
While testing private APIs directly is challenging (they require real system state), the error handling paths in `Bridging.swift` could benefit from unit tests using mocking strategies.

---

## [INFO] App Store Distribution Risk

> Private API usage will require non-App Store distribution

**File**: `Drawer/Bridging/Shims/Private.swift:17-113`  
**Category**: App Store Compliance  
**Severity**: Info

### Description

The file uses `@_silgen_name` to declare 9 private CGS (CoreGraphics Server) APIs. Apple's Mac App Store review process typically rejects apps that use private APIs because:

1. Private APIs are undocumented and subject to change without notice
2. Apple cannot guarantee stability or security of private API usage
3. Private APIs may access system resources in unsanctioned ways

### Private APIs Used

```swift
@_silgen_name("CGSMainConnectionID")
@_silgen_name("CGSGetWindowCount")
@_silgen_name("CGSGetWindowList")
@_silgen_name("CGSGetOnScreenWindowCount")
@_silgen_name("CGSGetOnScreenWindowList")
@_silgen_name("CGSGetProcessMenuBarWindowList")
@_silgen_name("CGSGetScreenRectForWindow")
@_silgen_name("CGSGetActiveSpace")
@_silgen_name("CGSCopySpacesForWindows")
```

### Context

These APIs are necessary for the app's core functionality:
- Getting accurate window frames for menu bar items
- Enumerating menu bar windows across all processes
- Managing multi-space/display scenarios

This is the same approach used by:
- [Ice](https://github.com/jordanbaird/Ice) (MIT License)
- [Bartender](https://www.macbartender.com/) (Commercial)
- [Hidden Bar](https://github.com/dwarvesf/hidden) (MIT License)

### Recommendation

**No code change required.** This is a known architectural decision documented in the project. Distribution options:

1. **Direct distribution** - DMG/pkg downloads from website
2. **Homebrew** - `brew install --cask drawer`
3. **Developer ID signing** - Notarization for Gatekeeper approval
4. **TestFlight** - For beta distribution

### Verification

Documented in:
- `REVIEW_PLAN.md` - "Uses undocumented CGS APIs (App Store risk)"
- `docs/ARCHITECTURE_COMPARISON.md` - "via Private APIs like CGSGetWindowList"

---

## [LOW] Missing Bridging Layer Tests

> The Bridging wrapper lacks dedicated unit tests

**File**: `Drawer/Bridging/Bridging.swift` (related)  
**Category**: Testing  
**Severity**: Low

### Description

While testing the private APIs themselves is impractical (they require real system state), the wrapper functions in `Bridging.swift` have error handling paths that could be unit tested.

### Current Code

```swift
// Bridging.swift:25-33
static func getWindowCount() -> Int {
    var count: Int32 = 0
    let result = CGSGetWindowCount(CGSMainConnectionID(), 0, &count)
    guard result == .success else {
        logger.error("CGSGetWindowCount failed: \(result.logString)")
        return 0  // Graceful fallback - could be tested
    }
    return Int(count)
}
```

### Suggested Approach

Create a protocol-based abstraction that allows mocking for testing:

```swift
// BridgingProtocol.swift
protocol WindowBridging {
    func getWindowCount() -> Int
    func getWindowList(option: Bridging.WindowListOption) -> [CGWindowID]
    func getWindowFrame(for windowID: CGWindowID) -> CGRect?
}

// In tests, create MockBridging that returns controlled values
final class MockBridging: WindowBridging {
    var windowCountToReturn: Int = 0
    func getWindowCount() -> Int { windowCountToReturn }
    // ...
}
```

### Verification

1. Add `DrawerTests/Bridging/BridgingTests.swift`
2. Test error handling returns (empty arrays, nil, 0)
3. Test option flag combinations in `getWindowList`

---

## Verification Checklist

- [x] No security vulnerabilities identified
- [x] Type declarations match private API requirements
- [x] Function signatures verified against Ice implementation
- [x] Constants correct per established implementations
- [x] Code follows project conventions (AGENTS.md)
- [x] App Store limitation documented as known constraint
- [x] Error handling present in wrapper layer (Bridging.swift)

---

## Verdict

**PASSED** - No critical or high severity findings. The private API usage is a deliberate architectural choice that is well-documented and follows established patterns from other menu bar utilities. The info-level findings are acknowledged constraints rather than issues to fix.
