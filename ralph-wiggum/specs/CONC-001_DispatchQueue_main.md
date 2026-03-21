# Spec: CONC-001 - Modernize Debounce Logic

## Context
The project is migrating to modern Swift Concurrency (Swift 6). Legacy patterns like `DispatchQueue.main.asyncAfter` are forbidden in new code and must be refactored to use `Task` and `Task.sleep`.

## Problem
In `MenuBarManager.swift`, a debounce timer for menu bar updates is implemented using `DispatchQueue.main`.

**Location:** `Drawer/Core/Managers/MenuBarManager.swift` (Line 473)
```swift
DispatchQueue.main.asyncAfter(deadline: .now() + debounceDelay) { [weak self] in
    self?.reconcileMenuBar()
}
```

## Mitigation Plan
1. **Replace with Task:** Use an unstructured `Task` to wait for the debounce duration.
2. **Use MainActor:** Ensure the task body runs on the `@MainActor` (the class is already marked as such).
3. **Cancel Previous:** Ensure any existing pending update is cancelled if a new one is triggered (standard debounce behavior).
4. **Use ContinuousClock:** Prefer `Task.sleep(for: .seconds(debounceDelay))` which is more readable and accurate in modern Swift.

## How to Test
1. Run the app.
2. Rapidly ⌘+drag icons in the menu bar to trigger multiple updates.
3. **Verification:** Ensure the app does not crash and the menu bar state remains consistent.
4. Check the logs (`DrawerManager` and `MenuBarManager`) to see that updates are correctly debounced and eventually processed.

## References
- `rules/rules_swift_concurrency.md` - Mandatory standard for concurrency.
- `Drawer/Core/Managers/MenuBarManager.swift` - Target file.
