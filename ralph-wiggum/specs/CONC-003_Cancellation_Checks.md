# Spec: CONC-003 & CONC-004 - Cooperative Cancellation in Loops

## Context
Long-running asynchronous work or polling loops must support cooperative cancellation to prevent resource waste and potential crashes after a task's context has been invalidated.

## Problem
Two core engines contain `while` loops that perform work inside `async` methods without checking if the task has been cancelled.

**Location 1 (CONC-003):** `Drawer/Core/Engines/IconCapturer.swift` (Line 402)
```swift
while currentX + iconWidthPixels <= imageWidth {
    // Slicing loop logic
}
```

**Location 2 (CONC-004):** `Drawer/Core/Engines/IconRepositioner.swift` (Line 479)
```swift
while ContinuousClock.now < deadline {
    // Polling loop logic
}
```

## Mitigation Plan
1. **Add Cancellation Checks:** At the start of each loop iteration, check `Task.isCancelled`.
2. **Break/Throw:** Exit the loop or throw a `CancellationError` if the task is cancelled.
3. **Clean Up:** Ensure any temporary resources (like image contexts or event suppressions) are properly cleaned up if the loop exits early.

## How to Test
1. **Unit Tests:** Review existing `IconCapturerTests` and `IconRepositionerTests`. 
2. **Cancellation Test:** Write a new unit test that starts a capture/reposition operation and cancels it immediately. 
3. **Verification:** Ensure the method returns quickly and does not continue processing.

## References
- `rules/rules_swift_concurrency.md` - Mandatory standard for concurrency.
- `Drawer/Core/Engines/IconCapturer.swift`
- `Drawer/Core/Engines/IconRepositioner.swift`
