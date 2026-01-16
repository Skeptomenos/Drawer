# Drawer Code Review Report

**Date**: January 15, 2026  
**Reviewer**: Automated Code Analysis  
**Project**: Drawer (macOS Menu Bar Utility)  
**Scope**: Full codebase review of `/Drawer` and `/hidden` directories

---

## Executive Summary

This report documents issues found during a comprehensive code review of the Drawer project, a macOS menu bar utility forked from Hidden Bar. The codebase contains a mix of new SwiftUI-based code (`Drawer/`) and legacy AppKit code (`hidden/`).

**Overall Assessment**: Moderate code quality with several critical issues requiring immediate attention.

| Severity | Count | Status |
|----------|-------|--------|
| Critical | 5 | Requires immediate fix |
| High | 5 | Should fix before release |
| Medium | 5 | Should fix in next sprint |
| Low | 4 | Fix when convenient |

---

## Critical Issues

### CRIT-001: Duplicate AppState Instances

**Location**: `Drawer/App/DrawerApp.swift:13` + `Drawer/App/AppState.swift:30`

**Description**:  
The application creates two separate `AppState` instances, causing state desynchronization.

```swift
// DrawerApp.swift - Creates NEW instance
@StateObject private var appState = AppState()

// AppState.swift - Singleton exists
static let shared = AppState()

// AppDelegate.swift - Uses singleton
_ = AppState.shared
```

**Impact**: 
- State changes in one instance don't reflect in the other
- Menu bar toggle state may not sync with Settings UI
- Unpredictable behavior across the application

**Mitigation**:
```swift
// DrawerApp.swift - Use the singleton instead
@StateObject private var appState = AppState.shared
```

**Effort**: Low (5 minutes)

---

### CRIT-002: Debug Timer Running in Production

**Location**: `Drawer/Core/Managers/MenuBarManager.swift:85-101`

**Description**:  
A debug timer prints status information every 5 seconds indefinitely.

```swift
debugTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
    print("--- STATUS ITEM DEBUG ---")
    print("Toggle: Frame=\(toggleBtn.window?.frame ?? .zero)...")
    // ... more prints
}
```

**Impact**:
- Console spam in production
- Wasted CPU cycles
- Timer never invalidated (no `deinit`)

**Mitigation**:
```swift
#if DEBUG
debugTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
    // debug code
}
#endif
```

Or remove entirely and add `deinit`:
```swift
deinit {
    debugTimer?.invalidate()
    autoCollapseTask?.cancel()
}
```

**Effort**: Low (10 minutes)

---

### CRIT-003: Missing deinit in Critical Managers

**Locations**:
- `Drawer/Core/Managers/MenuBarManager.swift`
- `Drawer/Core/Managers/HoverManager.swift`
- `Drawer/Core/Managers/DrawerManager.swift`
- `Drawer/App/AppState.swift`

**Description**:  
Managers with timers, tasks, or Combine subscriptions lack `deinit` methods to clean up resources.

| Manager | Resources Not Cleaned |
|---------|----------------------|
| MenuBarManager | `debugTimer`, `autoCollapseTask`, `cancellables` |
| HoverManager | `showDebounceTimer`, `hideDebounceTimer`, `mouseMonitor` |
| DrawerManager | `cancellables` |
| AppState | `cancellables` |

**Impact**:
- Memory leaks
- Zombie timers/tasks
- Potential crashes on edge cases

**Mitigation**:
```swift
// MenuBarManager.swift
deinit {
    debugTimer?.invalidate()
    autoCollapseTask?.cancel()
    cancellables.removeAll()
}

// HoverManager.swift
deinit {
    stopMonitoring()  // Already cleans up timers and monitor
}
```

**Effort**: Low (15 minutes)

---

### CRIT-004: Force Unwrap in Legacy Code

**Location**: `hidden/EventMonitor.swift:30-31`

**Description**:  
Unsafe force unwrap with potential race condition.

```swift
public func stop() {
    if monitor != nil {
        NSEvent.removeMonitor(monitor!)  // Force unwrap after nil check
        monitor = nil
    }
}
```

**Impact**:
- Potential crash if `monitor` becomes nil between check and unwrap
- Code smell indicating poor Swift practices

**Mitigation**:
```swift
public func stop() {
    if let monitor = monitor {
        NSEvent.removeMonitor(monitor)
        self.monitor = nil
    }
}
```

**Note**: The new `GlobalEventMonitor.swift` already implements this correctly.

**Effort**: Low (5 minutes)

---

### CRIT-005: Storyboards Present (Violates Architecture Guidelines)

**Locations**:
- `hidden/Base.lproj/Main.storyboard`
- `LauncherApplication/Base.lproj/Main.storyboard`

**Description**:  
Per `AGENTS.md`: "NO Storyboards: All UI must be code-based (SwiftUI)."

The legacy `hidden/` folder contains storyboards with `@IBOutlet` connections used by:
- `AboutViewController.swift`
- `PreferencesViewController.swift`
- `PreferencesWindowController.swift`

**Impact**:
- Inconsistent architecture
- Harder to maintain
- Violates project guidelines

**Mitigation**:
1. Short-term: Document that `hidden/` is legacy code pending removal
2. Long-term: Complete migration to SwiftUI (already in progress with `Drawer/UI/`)
3. Remove `hidden/` folder once migration is complete

**Effort**: High (requires full UI migration)

---

## High Severity Issues

### HIGH-001: Main Actor Isolation Violations

**Location**: `Drawer/Core/Managers/MenuBarManager.swift:86-100`

**Description**:  
Timer callback accesses `@MainActor`-isolated properties from non-main-actor context.

```swift
@MainActor
final class MenuBarManager: ObservableObject {
    private let toggleItem: NSStatusItem  // MainActor-isolated
    
    init() {
        debugTimer = Timer.scheduledTimer(...) { [weak self] _ in
            // ⚠️ Accessing MainActor property from Sendable closure
            print("Toggle: Frame=\(self.toggleItem.button?.window?.frame)")
        }
    }
}
```

**Compiler Warning**:
```
Main actor-isolated property 'toggleItem' can not be referenced from a Sendable closure
```

**Impact**:
- Undefined behavior
- Potential data races
- Future Swift versions may make this a hard error

**Mitigation**:
```swift
debugTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
    Task { @MainActor in
        guard let self = self else { return }
        // Now safe to access MainActor properties
        print("Toggle: Frame=\(self.toggleItem.button?.window?.frame ?? .zero)")
    }
}
```

**Effort**: Low (10 minutes)

---

### HIGH-002: Singleton Overuse Creates Testing Difficulties

**Affected Classes**:
| Singleton | Location |
|-----------|----------|
| `AppState.shared` | `AppState.swift:30` |
| `SettingsManager.shared` | `SettingsManager.swift:20` |
| `PermissionManager.shared` | `PermissionManager.swift:73` |
| `DrawerManager.shared` | `DrawerManager.swift:26` |
| `IconCapturer.shared` | `IconCapturer.swift:94` |
| `EventSimulator.shared` | `EventSimulator.swift:56` |
| `HoverManager.shared` | `HoverManager.swift:14` |
| `LaunchAtLoginManager.shared` | `LaunchAtLoginManager.swift:22` |

**Description**:  
Excessive singleton usage makes unit testing difficult and creates hidden dependencies.

**Impact**:
- Cannot inject mocks for testing
- Hidden coupling between components
- Inconsistent patterns (`AppState` accepts DI but also has `.shared`)

**Mitigation**:
1. Use protocol-based dependency injection
2. Pass dependencies through initializers (already partially done in `AppState`)
3. Reserve singletons for truly global state only

```swift
// Example: Protocol-based approach
protocol PermissionChecking {
    var hasAccessibility: Bool { get }
    var hasScreenRecording: Bool { get }
}

final class IconCapturer {
    private let permissionChecker: PermissionChecking
    
    init(permissionChecker: PermissionChecking = PermissionManager.shared) {
        self.permissionChecker = permissionChecker
    }
}
```

**Effort**: Medium (requires architectural refactoring)

---

### HIGH-003: Click Target Coordinate System Mismatch

**Location**: `Drawer/Models/DrawerItem.swift:85-87`

**Description**:  
Click target uses `originalFrame` coordinates without proper conversion.

```swift
var clickTarget: CGPoint {
    CGPoint(x: originalCenterX, y: originalCenterY)
}
```

**Problem**:
- `originalFrame` is captured in screen coordinates (bottom-left origin)
- `CGEvent` uses display coordinates (top-left origin)
- `EventSimulator.convertToScreenCoordinates()` exists but isn't used in click flow

**Impact**:
- Clicks may land at wrong Y position
- Click-through feature may not work correctly

**Mitigation**:
```swift
// DrawerItem.swift
var clickTarget: CGPoint {
    guard let screen = NSScreen.main else {
        return CGPoint(x: originalCenterX, y: originalCenterY)
    }
    // Convert from screen coordinates to CGEvent coordinates
    let convertedY = screen.frame.height - originalCenterY
    return CGPoint(x: originalCenterX, y: convertedY)
}
```

**Effort**: Low (15 minutes) but requires testing

---

### HIGH-004: Permission Polling Never Stops

**Location**: `Drawer/Core/Managers/PermissionManager.swift:233-245`

**Description**:  
Polling task runs every 2 seconds forever since singleton never deinits.

```swift
private func setupPolling() {
    pollingTask = Task { [weak self] in
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(2))
            self?.refreshAllStatuses()
        }
    }
}

deinit {
    pollingTask?.cancel()  // Never called - singleton!
}
```

**Impact**:
- Unnecessary CPU usage
- Battery drain on laptops
- 43,200 permission checks per day

**Mitigation**:
```swift
// Option 1: Stop polling when permissions are granted
private func setupPolling() {
    pollingTask = Task { [weak self] in
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(2))
            guard let self = self else { break }
            self.refreshAllStatuses()
            
            // Stop polling once all permissions granted
            if self.hasAllPermissions {
                break
            }
        }
    }
}

// Option 2: Use NotificationCenter for app activation instead
func startPollingOnAppActivation() {
    NotificationCenter.default.addObserver(
        forName: NSApplication.didBecomeActiveNotification,
        object: nil,
        queue: .main
    ) { [weak self] _ in
        self?.refreshAllStatuses()
    }
}
```

**Effort**: Low (20 minutes)

---

### HIGH-005: Combine Subscription Without Weak Self

**Location**: `Drawer/App/AppState.swift:57-58`

**Description**:  
Direct property assignment in Combine pipeline.

```swift
menuBarManager.$isCollapsed
    .assign(to: &$isCollapsed)
```

**Analysis**:  
This specific pattern is actually **safe** because `assign(to:)` with `&$` uses an inout parameter that doesn't create a retain cycle. However, the codebase mixes patterns inconsistently:

```swift
// Pattern 1: assign(to:) - safe
drawerController.$isVisible.assign(to: &$isDrawerVisible)

// Pattern 2: sink with [weak self] - safe
drawerManager.$isVisible.sink { [weak self] visible in ... }

// Pattern 3: sink without [weak self] - UNSAFE (not found, but could be added)
```

**Impact**:
- Code review confusion
- Risk of future developers adding unsafe patterns

**Mitigation**:
Add documentation comment explaining the pattern:
```swift
// Using assign(to:) with &$ is safe - no retain cycle created
// See: https://developer.apple.com/documentation/combine/publisher/assign(to:)
menuBarManager.$isCollapsed
    .assign(to: &$isCollapsed)
```

**Effort**: Low (5 minutes)

---

## Medium Severity Issues

### MED-001: Poor Error UX in Drawer

**Location**: `Drawer/App/AppState.swift:195-206`

**Description**:  
On capture failure, drawer shows empty with no error indication.

```swift
} catch {
    drawerManager.setError(error)
    // Still shows empty drawer!
    let contentView = DrawerContentView(items: [], isLoading: false)
    drawerController.show(content: contentView)
}
```

**Mitigation**:
Add error state to `DrawerContentView`:
```swift
struct DrawerContentView: View {
    let items: [DrawerItem]
    let isLoading: Bool
    let error: Error?  // Add this
    
    var body: some View {
        if let error = error {
            errorView(error)
        } else if isLoading {
            loadingView
        } else {
            // ...
        }
    }
}
```

**Effort**: Medium (30 minutes)

---

### MED-002: Hardcoded Menu Bar Height

**Locations**:
| File | Line | Value |
|------|------|-------|
| `IconCapturer.swift` | 119 | `24` |
| `DrawerPanel.swift` | 26 | `24` |
| `HoverManager.swift` | 20 | `24` |
| `EventSimulator.swift` | 167 | `24` |

**Description**:  
Menu bar height is hardcoded to 24pt, but MacBooks with notch have 37pt menu bar.

**Mitigation**:
Create a shared utility:
```swift
enum MenuBarMetrics {
    static var height: CGFloat {
        guard let screen = NSScreen.main else { return 24 }
        return screen.frame.height - screen.visibleFrame.height - screen.visibleFrame.origin.y
    }
}
```

**Effort**: Low (20 minutes)

---

### MED-003: Commented-Out Safety Guards

**Location**: `Drawer/Core/Managers/MenuBarManager.swift:219, 231-233`

**Description**:  
Safety guards are disabled with comments like "Force expand for debugging".

```swift
func expand() {
    // guard isCollapsed else { return } // Force expand for debugging
}

func collapse() {
    // guard isSeparatorValidPosition, !isCollapsed else { return }
}
```

**Impact**:
- Unexpected behavior in edge cases
- Guards exist for a reason

**Mitigation**:
Re-enable guards or remove if truly unnecessary:
```swift
func expand() {
    guard isCollapsed else { return }
    // ...
}
```

**Effort**: Low (10 minutes)

---

### MED-004: TODO Left in Production Code

**Location**: `Drawer/Core/Engines/IconCapturer.swift:371`

```swift
// TODO: Implement smarter edge detection for variable-width icons
```

**Description**:  
Indicates incomplete functionality in icon slicing algorithm.

**Mitigation**:
1. Create GitHub issue to track this work
2. Either implement or document limitation in user-facing docs

**Effort**: Varies (depends on implementation complexity)

---

### MED-005: Excessive Print Statements

**Location**: `Drawer/Core/Managers/MenuBarManager.swift` (10+ occurrences)

**Description**:  
Debug print statements throughout production code.

```swift
print("MenuBarManager: Initialized...")
print("MenuBarManager: toggle() called...")
print("MenuBarManager: Expanding...")
```

**Mitigation**:
Use `os.log` / `Logger` like other managers:
```swift
private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.drawer", category: "MenuBarManager")

// Replace print with:
logger.debug("Initialized")
logger.info("Toggle called")
```

**Effort**: Low (15 minutes)

---

## Low Severity Issues

### LOW-001: Mixed Import Styles

**Location**: `Drawer/Utilities/GlobalEventMonitor.swift`

```swift
import Foundation
import Cocoa  // Cocoa already includes Foundation
```

**Mitigation**: Remove redundant `Foundation` import.

---

### LOW-002: Inconsistent Access Control

**Description**:
- `GlobalEventMonitor` is `public` but only used internally
- `EventSimulator` is `internal` (default)

**Mitigation**: Use consistent access levels (`internal` for app-only code).

---

### LOW-003: Legacy Code Not Cleaned Up

**Location**: `hidden/` folder

**Description**:  
Contains original Hidden Bar code no longer used by new `Drawer/` implementation.

**Mitigation**:
1. Archive to separate branch
2. Remove from main branch
3. Or document as "legacy reference only"

---

### LOW-004: Preview Provider Uses Wrong Data

**Location**: `Drawer/UI/Panels/DrawerContentView.swift:183-184`

```swift
#Preview("With Items") {
    DrawerContentView(items: [])  // Says "With Items" but array is empty
}
```

**Mitigation**: Create mock data for previews or rename preview.

---

## Appendix: Files Reviewed

### New Codebase (`Drawer/`)
- `App/AppDelegate.swift`
- `App/AppState.swift`
- `App/DrawerApp.swift`
- `Core/Engines/IconCapturer.swift`
- `Core/Managers/DrawerManager.swift`
- `Core/Managers/HoverManager.swift`
- `Core/Managers/LaunchAtLoginManager.swift`
- `Core/Managers/MenuBarManager.swift`
- `Core/Managers/PermissionManager.swift`
- `Core/Managers/SettingsManager.swift`
- `Models/DrawerItem.swift`
- `UI/Components/PermissionStatusView.swift`
- `UI/Onboarding/*.swift`
- `UI/Panels/DrawerContentView.swift`
- `UI/Panels/DrawerPanel.swift`
- `UI/Panels/DrawerPanelController.swift`
- `UI/Settings/*.swift`
- `Utilities/EventSimulator.swift`
- `Utilities/GlobalEventMonitor.swift`

### Legacy Codebase (`hidden/`)
- `AppDelegate.swift`
- `EventMonitor.swift`
- `Features/StatusBar/StatusBarController.swift`
- `Features/Preferences/*.swift`
- `Features/About/AboutViewController.swift`

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-15 | Automated Analysis | Initial report |
