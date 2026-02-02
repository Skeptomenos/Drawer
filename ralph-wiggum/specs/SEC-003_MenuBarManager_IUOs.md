# Spec: SEC-003 - Fix Implicitly Unwrapped Optionals

## Context
Project rules strictly forbid force unwraps (`!`) and implicitly unwrapped optionals (IUO) in production code to prevent runtime crashes during initialization or state transitions.

## Problem
`MenuBarManager` uses IUOs for its core section models. These are initialized in a `setup` method rather than `init`, creating a window of vulnerability where they could be accessed before being populated.

**Location:** `Drawer/Core/Managers/MenuBarManager.swift` (Lines 38, 41)
```swift
private(set) var hiddenSection: MenuBarSection!
private(set) var visibleSection: MenuBarSection!
```

## Mitigation Plan
1. **Remove IUOs:** Change the property types to non-optional `MenuBarSection`.
2. **Move Initialization:** Move the creation of these sections into the class `init()`.
3. **Handle Dependencies:** If these sections require other objects (like `SettingsManager`) that aren't available at init time, use a protocol-based injection or lazy initialization with a non-optional getter.
4. **Update Callers:** Verify all references to these sections still compile and don't rely on the implicit unwrapping behavior.

## How to Test
1. **Compilation:** Ensure the project builds without errors.
2. **App Launch:** Launch the app and verify the menu bar items appear correctly immediately.
3. **Unit Tests:** Run `MenuBarManagerTests.swift`. Ensure all tests pass and no "found nil" crashes occur.

## References
- `rules/rules_swift.md` Section 4 - Type Safety.
- `Drawer/Core/Managers/MenuBarManager.swift`
