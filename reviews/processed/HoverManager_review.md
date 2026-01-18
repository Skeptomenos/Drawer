# Code Review: HoverManager.swift

**File**: `Drawer/Core/Managers/HoverManager.swift`  
**Reviewer**: Ralphus  
**Date**: 2026-01-17  
**Result**: PASSED (0 critical, 0 high, 1 low, 2 info)

---

## Summary

HoverManager is responsible for mouse tracking, gesture detection, and event listener management for the Drawer's hover-to-show/hide functionality. The implementation is well-structured, follows project conventions, and properly handles cleanup of event monitors and timers.

**Key Responsibilities Reviewed**:
- Global event monitoring (mouse moved, scroll, click)
- Menu bar trigger zone detection
- Drawer area hit testing with 10px tolerance
- Scroll gesture threshold detection with natural scrolling support
- Click-outside-to-dismiss behavior
- App deactivation (focus-loss) detection

---

## Findings

### [LOW] Unused `cancellables` Property

> Combine subscription storage declared but never used

**File**: `Drawer/Core/Managers/HoverManager.swift:30`  
**Category**: Maintainability  
**Severity**: Low  

#### Description

The `cancellables` property is declared for Combine subscription storage but is never used anywhere in the class. This creates dead code that may confuse future maintainers or suggest incomplete implementation.

#### Current Code

```swift
private var cancellables = Set<AnyCancellable>()
```

#### Suggested Fix

Remove the unused property:

```swift
// Remove line 30 entirely if no Combine subscriptions are planned
// OR use it if Combine integration is planned:
// settingsManager.$showOnHover.sink { ... }.store(in: &cancellables)
```

#### Verification

1. Search for `cancellables` usage - should find no store(in:) calls
2. Remove the property
3. Build and verify no compiler errors

---

### [INFO] Task Creation for High-Frequency Events

> Each mouse move/scroll event creates a new Task

**File**: `Drawer/Core/Managers/HoverManager.swift:69-86`  
**Category**: Performance  
**Severity**: Info  

#### Description

The event handlers create a new `Task { @MainActor }` for every mouse move, scroll, and click event. For high-frequency events like `mouseMoved`, this creates many short-lived tasks. This is architecturally correct for thread safety but could be optimized if performance profiling shows issues.

#### Current Code

```swift
mouseMonitor = GlobalEventMonitor(mask: .mouseMoved) { [weak self] event in
    Task { @MainActor in
        self?.handleMouseMoved(event)
    }
}
```

#### Analysis

This pattern is acceptable because:
1. Swift Tasks are lightweight
2. The MainActor ensures thread safety for UI state
3. The handlers are simple and fast-executing

No change required unless performance profiling indicates an issue.

---

### [INFO] Test Coverage Limitation for Event Simulation

> Unit tests cannot simulate NSEvent objects for full gesture testing

**File**: `DrawerTests/Core/Managers/HoverManagerTests.swift`  
**Category**: Testing  
**Severity**: Info  

#### Description

The test suite (27 tests) comprehensively covers the testable portions of HoverManager, including:
- Initial state verification
- Start/stop monitoring lifecycle
- Frame update and geometry detection
- Settings integration

However, direct testing of scroll/click event handling requires NSEvent simulation which is not possible without private APIs. This is a platform limitation, not a code defect.

#### Mitigation

The tests properly verify:
1. Geometry detection (`isInMenuBarTriggerZone`, `isInDrawerArea`)
2. Settings integration (settings flags are checked)
3. Callback wiring (callbacks are assignable)

Manual testing documented in verification steps covers the event-driven behavior.

---

## Checklist Summary

| Category | Status | Notes |
|----------|--------|-------|
| Security | PASS | No user input, no injection vectors |
| Correctness | PASS | Logic correct, edge cases handled |
| Performance | PASS | Appropriate optimizations, no leaks |
| Maintainability | PASS | 1 low finding (unused property) |
| Testing | PASS | 27 tests, good coverage |

---

## Verdict

**PASSED** - No critical or high severity findings. The code is well-structured, follows project conventions, and properly manages event listeners and resources. The one low-severity finding (unused property) is minor and does not impact functionality.
