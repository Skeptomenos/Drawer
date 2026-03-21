# Review: GlobalEventMonitor.swift

**File**: `Drawer/Utilities/GlobalEventMonitor.swift`  
**Reviewer**: Ralphus  
**Date**: 2026-01-17  
**Result**: PASSED (0 critical, 0 high, 0 medium, 0 low, 2 info)

---

## Summary

The `GlobalEventMonitor` and `LocalEventMonitor` classes provide a clean wrapper around macOS event monitoring APIs (`NSEvent.addGlobalMonitorForEvents` and `NSEvent.addLocalMonitorForEvents`). The implementation follows proper memory management patterns with defensive guards and automatic cleanup in `deinit`.

---

## [INFO] Silent Failure on Permission Denied

> `start()` does not report when monitor creation fails due to missing Accessibility permission.

**File**: `Drawer/Utilities/GlobalEventMonitor.swift:26-29`  
**Category**: Correctness  
**Severity**: Info  

### Description

When Accessibility permission is not granted, `NSEvent.addGlobalMonitorForEvents` returns `nil`. The current implementation silently stores `nil` in `monitor`, and `isRunning` correctly returns `false`. However, there is no mechanism to distinguish between "not started" and "failed to start due to permissions".

This is acceptable for the current use case since:
1. Permission is checked at app startup via `PermissionManager`
2. `HoverManager.startMonitoring()` is only called after permissions are granted
3. Callers can check `isRunning` after `start()` if needed

### Current Code

```swift
func start() {
    guard monitor == nil else { return }
    monitor = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: handler)
}
```

### No Action Required

The current design is appropriate for a low-level utility class. Permission gating is correctly handled at a higher level.

---

## [INFO] LocalEventMonitor Unused in Production

> `LocalEventMonitor` class is defined but not used in production code.

**File**: `Drawer/Utilities/GlobalEventMonitor.swift:43-73`  
**Category**: Maintainability  
**Severity**: Info  

### Description

The `LocalEventMonitor` class is defined alongside `GlobalEventMonitor` for symmetry and potential future use. Currently it is only used in tests as a utility. The class follows identical patterns and is correctly implemented.

### No Action Required

Co-location with `GlobalEventMonitor` is reasonable. The class may be needed for future features (e.g., capturing events within the app's windows). No dead code removal needed.

---

## Checklist Results

### Security (P0)
- [x] Permission requirements documented (Accessibility permission for global monitors)
- [x] No sensitive event types monitored (no keyboard events)
- [x] No logging of event data
- [x] Handlers use `[weak self]` in callers (verified in HoverManager)

### Correctness (P1)
- [x] `start()` guards against duplicate monitors
- [x] `stop()` safely handles nil monitor reference
- [x] `deinit` ensures cleanup on deallocation
- [x] Edge cases handled (double start, stop when not running)

### Performance (P2)
- [x] Event listeners properly cleaned up
- [x] No memory leaks (deinit calls stop)
- [x] No unbounded data structures

### Maintainability (P3)
- [x] Follows project conventions (final class, MIT header)
- [x] Single responsibility pattern
- [x] Clean, readable code with no dead code

### Testing (P4)
- [x] Test suite covers all public API methods
- [x] Edge cases tested (GEM-004, GEM-005, GEM-006)
- [x] Tests are deterministic and readable

---

## Verification

1. Review test suite: `DrawerTests/Utilities/GlobalEventMonitorTests.swift` (7 tests)
2. Verify HoverManager cleanup: `stopMonitoring()` at line 105-124 and `deinit` at line 55-64
3. Run tests: `xcodebuild test -scheme Drawer -only-testing:DrawerTests/GlobalEventMonitorTests`
