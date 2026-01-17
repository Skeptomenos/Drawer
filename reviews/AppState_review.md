# AppState.swift Review

**File**: `Drawer/App/AppState.swift`  
**Reviewed**: 2026-01-17  
**Reviewer**: Ralphus  
**Result**: PASSED (0 critical, 0 high, 0 medium, 1 low, 2 info)

---

## Summary

`AppState` is the central state coordinator for the Drawer application. It manages the lifecycle and state synchronization between all major managers (MenuBarManager, DrawerManager, PermissionManager, HoverManager, etc.). The implementation is well-structured with proper permission gating, error handling, and Combine subscription management. One minor issue was found related to NotificationCenter observer cleanup.

---

## [LOW] NotificationCenter Observer Not Removed in deinit

> NotificationCenter observer is added but may not be properly removed when AppState is deallocated.

**File**: `Drawer/App/AppState.swift:79-87`  
**Category**: Performance  
**Severity**: Low  

### Description

The `setupMenuBarFailureObserver()` method adds a NotificationCenter observer using `addObserver(forName:object:queue:)` with a closure, but this observer is not stored or removed in `deinit`. While in practice this is mitigated because:
1. AppState is a singleton (`static let shared`) and will never be deallocated during normal app execution
2. The closure uses `[weak self]` to avoid retain cycles

However, for code correctness and to follow best practices (especially if the singleton pattern is ever changed), the observer should be tracked and removed.

### Current Code

```swift
private func setupMenuBarFailureObserver() {
    NotificationCenter.default.addObserver(
        forName: .menuBarSetupFailed,
        object: nil,
        queue: .main
    ) { [weak self] _ in
        self?.logger.error("Menu bar setup failed after all retry attempts")
    }
}

deinit {
    cancellables.removeAll()
}
```

### Suggested Fix

```swift
private var menuBarFailureObserver: NSObjectProtocol?

private func setupMenuBarFailureObserver() {
    menuBarFailureObserver = NotificationCenter.default.addObserver(
        forName: .menuBarSetupFailed,
        object: nil,
        queue: .main
    ) { [weak self] _ in
        self?.logger.error("Menu bar setup failed after all retry attempts")
    }
}

deinit {
    if let observer = menuBarFailureObserver {
        NotificationCenter.default.removeObserver(observer)
    }
    cancellables.removeAll()
}
```

### Verification

1. Run tests: `xcodebuild test -scheme Drawer -only-testing:DrawerTests/AppStateTests`
2. Verify no memory leaks with Instruments

---

## [INFO] Excellent State Coordination Pattern

> AppState follows excellent patterns for coordinating application state.

**File**: `Drawer/App/AppState.swift`  
**Category**: Maintainability  
**Severity**: Info  

### Description

Positive observations:

1. **Dependency Injection**: The init method accepts all major dependencies with default values, making the class testable while convenient for production use:
   ```swift
   init(
       settings: SettingsManager = .shared,
       permissions: PermissionManager = .shared,
       // ...
   )
   ```

2. **Safe Combine Bindings**: Uses `assign(to: &$property)` pattern which avoids retain cycles (as documented in the code comment).

3. **Proper Permission Gating**: Both `captureAndShowDrawer()` and `performClickThrough()` verify permissions before proceeding:
   ```swift
   guard permissions.hasScreenRecording else { ... }
   guard permissions.hasAccessibility else { ... }
   ```

4. **Comprehensive Error Handling**: The `captureAndShowDrawer()` method properly catches errors, logs them, updates state, and still presents UI (with error state) to the user.

5. **Good Use of @MainActor**: The entire class is properly annotated for main thread safety.

6. **Clean Separation of Overlay Mode**: The toggle logic cleanly routes to either overlay mode or traditional expand mode based on settings:
   ```swift
   if settings.overlayModeEnabled {
       Task { await overlayModeManager.toggleOverlay() }
   } else {
       menuBarManager.toggle()
   }
   ```

No action required.

---

## [INFO] Comprehensive Test Coverage

> AppState has good test coverage for its public API.

**File**: `DrawerTests/App/AppStateTests.swift`  
**Category**: Testing  
**Severity**: Info  

### Description

The test file includes 11 test cases covering:

- Initial state verification (APP-001, APP-002, APP-003)
- Toggle behavior (APP-004, APP-005, APP-006)
- State update propagation (APP-007)
- Onboarding completion (APP-008, APP-009)
- Permission bindings (APP-010)
- Hover bindings configuration (APP-011)

The tests use proper async/await patterns and XCTestExpectation for asynchronous assertions.

No action required.

---

## Review Checklist

### Security (P0)
- [x] Input validation: N/A - State coordinator
- [x] No injection vulnerabilities: N/A
- [x] Auth/authz checks: Proper TCC permission gating before sensitive operations
- [x] No hardcoded secrets
- [x] Sensitive data properly handled: Debug logs only show counts, not content

### Correctness (P1)
- [x] Logic matches intended behavior
- [x] Edge cases handled (permission denied, capture failure)
- [x] Error handling present (try/catch with proper error surfacing)
- [x] No obvious bugs or typos
- [x] Types used correctly (@Published, @MainActor)

### Performance (P2)
- [x] No N+1 queries or unbounded loops
- [x] Appropriate data structures
- [~] Minor: NotificationCenter observer not removed in deinit - LOW severity
- [x] Combine subscriptions properly managed in cancellables set

### Maintainability (P3)
- [x] Code is readable and well-documented (MARK sections, inline comments)
- [x] Functions are focused (single responsibility)
- [x] No dead code
- [x] Consistent with project conventions

### Test Coverage (P4)
- [x] Tests exist (11 test cases)
- [x] Happy path and error cases covered
- [x] Tests are meaningful
