# ISSUE-001 Postmortem: Missing Menu Bar Icons

**Date**: January 2026  
**Severity**: Critical (app unusable)  
**Status**: Resolved

## Summary

After completing onboarding, Drawer's menu bar icons (toggle `<`/`>` and separator `●`) were not visible, making the app completely unusable.

## Root Cause

**Race condition in SwiftUI singleton initialization.**

The `AppState.shared` singleton was accessed during SwiftUI struct property initialization, which occurs *before* `NSApplication` is fully initialized:

```swift
// DrawerApp.swift - PROBLEMATIC CODE
@main
struct DrawerApp: App {
    @ObservedObject private var appState = AppState.shared  // ← TOO EARLY
    ...
}
```

This caused `NSStatusBar.system.statusItem(withLength:)` to return items with `nil` buttons, and the `if let button = ...` guards silently skipped configuration.

## What Went Wrong

1. **Initialization timing**: SwiftUI struct properties initialize before the app run loop is established
2. **Silent failures**: `if let` guards didn't log when buttons were nil
3. **No retry mechanism**: Single initialization attempt with no recovery
4. **Cached state**: macOS caches NSStatusItem state via `autosaveName`, persisting broken state across launches

## The Fix

### 1. Lazy Initialization (DrawerApp.swift)

```swift
// BEFORE (broken)
@ObservedObject private var appState = AppState.shared

// AFTER (fixed)
var body: some Scene {
    Settings {
        SettingsView()
            .environmentObject(AppState.shared)  // Lazy access in body
    }
}
```

### 2. Defensive Retry Logic (MenuBarManager.swift)

Added retry mechanism with explicit failure handling:

```swift
private let maxRetryAttempts = 3
private let retryDelayNanoseconds: UInt64 = 200_000_000  // 200ms

private func setupUI(attempt: Int) {
    guard let toggleButton = toggleItem.button else {
        handleSetupFailure(component: "toggleItem.button", attempt: attempt)
        return
    }
    // ... setup code ...
}

private func handleSetupFailure(component: String, attempt: Int) {
    if attempt < maxRetryAttempts {
        logger.warning("\(component) is nil on attempt \(attempt). Retrying...")
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: retryDelayNanoseconds)
            self.setupUI(attempt: attempt + 1)
        }
    } else {
        logger.error("CRITICAL: \(component) is nil after \(maxRetryAttempts) attempts")
        NotificationCenter.default.post(name: .menuBarSetupFailed, object: nil)
    }
}
```

### 3. Visibility Verification

Added post-setup verification:

```swift
private func verifyVisibility() {
    let toggleVisible = toggleItem.button?.window?.frame.width ?? 0 > 0
    let separatorVisible = separatorItem.button?.window?.frame.width ?? 0 > 0
    
    if toggleVisible && separatorVisible {
        logger.info("Menu bar icons verified visible")
    } else {
        logger.warning("Visibility check failed")
    }
}
```

### 4. Cache Busting

Incremented autosave names to clear cached broken state:

```swift
// Changed from _v2 to _v3
separatorItem.autosaveName = "drawer_separator_v3"
toggleItem.autosaveName = "drawer_toggle_v3"
```

### 5. Explicit Title Clearing

Removed fallback titles that were being cached:

```swift
separatorButton.title = ""  // Clear any cached title
toggleButton.title = ""
```

## Secondary Fix: Preferences Not Opening

The SwiftUI `Settings` scene wasn't responding to `NSApp.sendAction(Selector(("showSettingsWindow:")))`. 

**Fix**: Created explicit settings window in AppDelegate:

```swift
func openSettings() {
    if let window = settingsWindow {
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        return
    }
    
    let settingsView = SettingsView().environmentObject(AppState.shared)
    let window = NSWindow(...)
    window.title = "Drawer Settings"
    // ... window setup ...
    self.settingsWindow = window
    NSApp.activate(ignoringOtherApps: true)
}
```

## Files Changed

| File | Change |
|------|--------|
| `DrawerApp.swift` | Removed eager `@ObservedObject` initialization |
| `MenuBarManager.swift` | Added retry logic, verification, explicit title clearing |
| `AppDelegate.swift` | Added `openSettings()` method and static `shared` reference |
| `Notification+Extensions.swift` | New file with `.menuBarSetupFailed` notification |
| `AppState.swift` | Added observer for setup failure notification |
| `project.pbxproj` | Added new file to Xcode project |

## Lessons Learned

1. **Never access singletons in SwiftUI property initializers** - Use lazy access in `body` or `onAppear`
2. **Log failures explicitly** - Silent `if let` guards hide critical issues
3. **Add retry mechanisms for system resources** - Menu bar, status items, etc. may not be ready immediately
4. **Verify after setup** - Don't assume success; check actual state
5. **Cache busting** - macOS caches NSStatusItem state; increment autosave names when fixing issues
6. **SwiftUI Settings scene is unreliable** - Use explicit NSWindow for guaranteed behavior

## Verification Checklist

- [x] Fresh launch: icons appear immediately
- [x] App restart: icons persist in correct positions
- [x] No `|` or `D` text visible (cache cleared)
- [x] Preferences menu item opens settings window
- [x] Toggle expands/collapses hidden section
- [x] Console shows "setup complete" log

## Prevention

For future NSStatusItem work:

1. Always initialize after `applicationDidFinishLaunching`
2. Always verify `.button` is non-nil before configuration
3. Always add retry logic for transient failures
4. Always log initialization state for debugging
5. Always test on fresh user account (no cached state)
