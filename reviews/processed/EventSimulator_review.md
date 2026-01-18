# Review: EventSimulator.swift

**File**: `Drawer/Utilities/EventSimulator.swift`  
**Reviewer**: Ralphus  
**Date**: 2026-01-17  
**Result**: PASSED (0 critical, 0 high, 0 medium, 1 info)

---

## Summary

EventSimulator is a well-implemented utility for CGEvent-based mouse click simulation. The code demonstrates solid security practices with proper permission gating and coordinate validation before any system event injection.

## Checklist Results

### Security (P0) - PASSED

- [x] **Permission gating**: `hasAccessibilityPermission` checked at line 91 before any CGEvent operations
- [x] **Input validation**: Coordinates validated via `isValidScreenPoint()` at line 96
- [x] **No injection risks**: CGEvent API is type-safe, no string interpolation
- [x] **No hardcoded secrets**: Only bundle identifier used for logging
- [x] **Sensitive data**: Logging only contains screen coordinates, no PII

### Correctness (P1) - PASSED

- [x] **Logic sequence**: Move → delay → down → delay → up (lines 101-105) is correct
- [x] **Edge cases**: Invalid coordinates and missing permissions throw specific errors
- [x] **Error handling**: All four error cases (accessibilityNotGranted, eventCreationFailed, eventPostingFailed, invalidCoordinates) have `LocalizedError` conformance
- [x] **Type safety**: `CGPoint`, `CGEvent` used correctly throughout

### Performance (P2) - PASSED

- [x] **Bounded operations**: `isValidScreenPoint` iterates only over `NSScreen.screens` (finite)
- [x] **Appropriate delays**: 10ms move-to-click, 50ms click duration are reasonable
- [x] **Memory management**: Singleton pattern appropriate for stateless utility

### Maintainability (P3) - PASSED

- [x] **Code style**: Follows AGENTS.md conventions (MARK comments, camelCase, header)
- [x] **Single responsibility**: Focused solely on event simulation
- [x] **No dead code**: All methods are utilized
- [x] **Documentation**: Public methods have doc comments

### Testing (P4) - PASSED

- [x] **Test coverage**: 8 test cases in `EventSimulatorTests.swift`
- [x] **Permission scenarios**: Both granted and denied paths tested
- [x] **Coordinate validation**: Inside screen, outside screen, menu bar area all tested
- [x] **Cursor management**: Save/restore position tested

---

## Findings

### [INFO] Multi-Display Coordinate Conversion Assumption

> `convertToScreenCoordinates` assumes main screen origin for Y-axis flip

**File**: `Drawer/Utilities/EventSimulator.swift:192-195`  
**Category**: Maintainability  
**Severity**: Info  

#### Description

The `convertToScreenCoordinates` method uses `NSScreen.main` to flip the Y-coordinate from AppKit's bottom-left origin to CGEvent's top-left origin. On multi-display setups where displays have different heights or non-standard arrangements, this could result in slightly inaccurate coordinates.

However, since `restoreCursorPosition` is the only caller and the saved position comes from `NSEvent.mouseLocation` (which is already in AppKit coordinates relative to main screen), this is internally consistent and unlikely to cause issues in practice.

#### Current Code

```swift
private func convertToScreenCoordinates(_ point: CGPoint) -> CGPoint {
    guard let mainScreen = NSScreen.main else { return point }
    return CGPoint(x: point.x, y: mainScreen.frame.height - point.y)
}
```

#### Recommendation

No code change required. Consider adding a brief comment noting the assumption:

```swift
/// Converts AppKit coordinates (bottom-left origin) to CGEvent coordinates (top-left origin).
/// Note: Uses main screen height for Y-flip; safe for single-screen and typical multi-display setups.
private func convertToScreenCoordinates(_ point: CGPoint) -> CGPoint {
    guard let mainScreen = NSScreen.main else { return point }
    return CGPoint(x: point.x, y: mainScreen.frame.height - point.y)
}
```

---

## Positive Observations

1. **Clean error handling**: The `EventSimulatorError` enum with `LocalizedError` conformance provides clear, actionable error messages.

2. **Proper async/await usage**: Uses modern Swift concurrency with `Task.sleep(nanoseconds:)` for timing.

3. **Defense in depth**: Permission check happens before validation, so unauthorized callers fail fast with a clear reason.

4. **Logging discipline**: Uses `os.log` with appropriate levels (info for operations, debug for low-level events, error for failures).

5. **Testable design**: While a singleton, the permission check is based on `AXIsProcessTrusted()` which allows tests to detect the environment and skip appropriately.

---

## Verdict

**PASSED** - The code is production-ready with no security concerns. The single info-level finding is a documentation enhancement suggestion, not a functional issue.
