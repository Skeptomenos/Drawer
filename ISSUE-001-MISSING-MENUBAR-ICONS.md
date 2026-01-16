# ISSUE-001: Menu Bar Toggle/Separator Icons Not Visible

## Problem Statement

After completing the onboarding wizard with all permissions granted (Accessibility + Screen Recording), the Drawer app's menu bar icons (`<` `>` toggle and `|` separator) are not visible in the menu bar.

## Expected Behavior

After onboarding completion:
1. A toggle icon (`<` or `>`) should appear in the menu bar
2. A separator (`|`) should appear to the left of the toggle
3. Users should be able to Cmd+drag menu bar icons to reposition them relative to the separator

## Actual Behavior

- The menu bar shows no Drawer-related icons
- The app appears to be running (onboarding window was displayed)
- All permissions are granted

## Screenshots

- Permissions screen shows both Accessibility and Screen Recording as "Granted" with green checkmarks
- Menu bar screenshot shows no `<`, `>`, or `|` icons

## Technical Context

### Relevant Files to Investigate

1. **`Drawer/Core/Managers/MenuBarManager.swift`**
   - Creates `toggleItem` and `separatorItem` NSStatusItems
   - `setupUI()` configures the button images
   - Check if `NSStatusBar.system.statusItem(withLength:)` is being called
   - Check if buttons are being configured with images

2. **`Drawer/App/AppState.swift`**
   - Initializes `MenuBarManager.shared`
   - Check initialization order and timing

3. **`Drawer/App/AppDelegate.swift`**
   - `applicationDidFinishLaunching` forces `AppState.shared` initialization
   - Verify this is being called

4. **`Drawer/App/DrawerApp.swift`**
   - Main app entry point
   - Check if `@NSApplicationDelegateAdaptor` is properly connected

### Potential Root Causes

1. **Initialization Order**: `MenuBarManager` may not be initialized, or initialized too late
2. **Button Configuration**: `toggleItem.button` or `separatorItem.button` may be nil
3. **Image Assets**: SF Symbols may not be loading correctly
4. **Status Item Length**: Items may have zero length making them invisible
5. **Autosave Name Conflict**: Changed autosave names may cause positioning issues
6. **MainActor Issues**: Initialization may be happening off the main thread

### Debug Steps for Next Session

1. **Add logging to verify initialization**:
   ```swift
   // In MenuBarManager.init()
   logger.debug("MenuBarManager init started")
   logger.debug("Toggle button: \(String(describing: toggleItem.button))")
   logger.debug("Separator button: \(String(describing: separatorItem.button))")
   ```

2. **Check Console.app for Drawer logs**:
   ```bash
   log stream --predicate 'subsystem == "com.drawer.app"' --level debug
   ```

3. **Verify NSStatusItem creation**:
   - Confirm `NSStatusBar.system.statusItem(withLength:)` returns valid items
   - Check if `.button` property is non-nil

4. **Check image assignment**:
   - Verify SF Symbol names are correct (`chevron.left`, `chevron.right`)
   - Check if `button.image` is being set

5. **Test with hardcoded title**:
   ```swift
   toggleItem.button?.title = "TEST"
   ```

### Code Sections to Review

```swift
// MenuBarManager.swift - setupUI()
private func setupUI() {
    // Toggle button setup
    if let button = toggleItem.button {
        button.image = NSImage(systemSymbolName: isCollapsed ? "chevron.right" : "chevron.left", accessibilityDescription: "Toggle Drawer")
        // ...
    }
    
    // Separator setup
    if let button = separatorItem.button {
        button.title = "|"
        // ...
    }
}
```

### Questions to Answer

1. Is `MenuBarManager.init()` being called?
2. Are `toggleItem.button` and `separatorItem.button` non-nil?
3. Are the images/titles being set correctly?
4. Is `setupUI()` being called?
5. Are there any errors in the system log?

## Root Cause Analysis

### Primary Root Cause: Race Condition in Singleton Initialization

The `AppState.shared` singleton is accessed from `DrawerApp.swift` during SwiftUI struct property initialization:

```swift
// DrawerApp.swift:13
@ObservedObject private var appState = AppState.shared
```

**Problem**: SwiftUI struct property initializers execute during struct creation, which happens **before** `NSApplication` is fully initialized. This causes:

1. `NSStatusBar.system.statusItem(withLength:)` returns items with `nil` buttons
2. The `if let button = ...` guards in `setupUI()` silently skip configuration
3. No error is logged - icons simply don't appear

### Initialization Chain (Problematic)

```
DrawerApp struct initialization (SwiftUI)
    │
    ├── @ObservedObject private var appState = AppState.shared
    │   ↑ TRIGGERS SINGLETON CREATION TOO EARLY
    │
    └── AppState.init()
            └── MenuBarManager.init()
                    ├── NSStatusBar.system.statusItem() → button may be nil
                    └── setupUI() → silent failure if button is nil
```

### Secondary Issue: Silent Failures

```swift
// MenuBarManager.swift - setupUI()
if let button = separatorItem.button { ... }  // Silent skip if nil
if let button = toggleItem.button { ... }     // Silent skip if nil
```

No logging occurs when buttons are nil, making debugging difficult.

---

## Recommended Fix: Hybrid Approach

Combines fixing the root cause with defensive retry logic for maximum reliability.

### Change 1: `DrawerApp.swift` - Lazy Access

Remove eager initialization; access `AppState.shared` lazily in the body.

```swift
@main
struct DrawerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // REMOVE: @ObservedObject private var appState = AppState.shared
    
    var body: some Scene {
        Settings {
            SettingsView()
                .environmentObject(AppState.shared)  // Lazy access here
        }
    }
}
```

### Change 2: `MenuBarManager.swift` - Defensive Initialization with Retry

Add retry logic and explicit failure handling.

```swift
// Add at top of class
private let maxRetryAttempts = 3
private let retryDelayNanoseconds: UInt64 = 200_000_000  // 200ms

// Modify init()
init(settings: SettingsManager = .shared) {
    self.settings = settings
    self.toggleItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    self.separatorItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    setupUI(attempt: 1)
    setupSettingsBindings()
    
    logger.debug("Initialized. Toggle: \(String(describing: self.toggleItem.button)), Separator: \(String(describing: self.separatorItem.button))")
}

// Replace setupUI() with:
private func setupUI(attempt: Int = 1) {
    // Verify buttons are available
    guard let toggleButton = toggleItem.button else {
        handleSetupFailure(component: "toggleItem.button", attempt: attempt)
        return
    }
    
    guard let separatorButton = separatorItem.button else {
        handleSetupFailure(component: "separatorItem.button", attempt: attempt)
        return
    }
    
    // Configure separator
    separatorButton.image = separatorImage ?? NSImage(named: NSImage.touchBarHistoryTemplateName)
    separatorButton.imagePosition = .imageOnly
    separatorItem.length = separatorExpandedLength
    separatorItem.menu = createContextMenu()
    separatorItem.autosaveName = "drawer_separator_v2"
    
    // Configure toggle
    toggleButton.image = collapseImage ?? NSImage(named: NSImage.touchBarGoForwardTemplateName)
    toggleButton.target = self
    toggleButton.action = #selector(toggleButtonPressed)
    toggleButton.sendAction(on: [.leftMouseUp, .rightMouseUp])
    toggleButton.imagePosition = .imageOnly
    toggleItem.autosaveName = "drawer_toggle_v2"
    
    logger.info("Menu bar UI setup complete on attempt \(attempt)")
    
    // Verify visibility after a short delay
    Task { @MainActor in
        try? await Task.sleep(nanoseconds: 100_000_000)
        verifyVisibility()
    }
}

private func handleSetupFailure(component: String, attempt: Int) {
    if attempt < maxRetryAttempts {
        logger.warning("\(component) is nil on attempt \(attempt)/\(self.maxRetryAttempts). Retrying...")
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: retryDelayNanoseconds)
            self.setupUI(attempt: attempt + 1)
        }
    } else {
        logger.error("CRITICAL: \(component) is nil after \(self.maxRetryAttempts) attempts. Menu bar icons will not appear.")
        NotificationCenter.default.post(name: .menuBarSetupFailed, object: nil)
    }
}

private func verifyVisibility() {
    let toggleVisible = toggleItem.button?.window?.frame.width ?? 0 > 0
    let separatorVisible = separatorItem.button?.window?.frame.width ?? 0 > 0
    
    if toggleVisible && separatorVisible {
        logger.info("Menu bar icons verified visible")
    } else {
        logger.warning("Menu bar visibility check failed. Toggle: \(toggleVisible), Separator: \(separatorVisible)")
    }
}
```

### Change 3: Add Notification Name Extension

Add to `MenuBarManager.swift` or a separate extensions file:

```swift
extension Notification.Name {
    static let menuBarSetupFailed = Notification.Name("com.drawer.menuBarSetupFailed")
}
```

### Change 4: `AppState.swift` - Handle Setup Failures (Optional)

```swift
// In init(), after existing setup code:
NotificationCenter.default.addObserver(
    forName: .menuBarSetupFailed,
    object: nil,
    queue: .main
) { [weak self] _ in
    self?.logger.error("Menu bar setup failed - user may need to restart app")
}
```

---

## Why This Fix Is Optimal

| Benefit          | How It's Achieved                                              |
| ---------------- | -------------------------------------------------------------- |
| **Fixes root cause** | Lazy initialization prevents race condition                    |
| **Self-healing**     | Retry logic recovers from transient timing issues              |
| **Observable**       | All failures are logged with context                           |
| **Fail-loud**        | After retries exhausted, posts notification for handling       |
| **Extensible**       | Notification pattern allows any component to react to failures |
| **Defensive**        | Guards against future regressions in initialization order      |

---

## Verification Checklist

After implementing the fix:

- [ ] Fresh launch: icons appear immediately
- [ ] App restart: icons persist in correct positions  
- [ ] Console shows "setup complete" log, not error logs
- [ ] Cmd+drag repositions icons correctly
- [ ] Works on fresh macOS user account (no cached autosave)
- [ ] Kill app during launch: icons appear on next launch

---

## Priority

**HIGH** - Core functionality is broken; app is unusable without menu bar presence.

## Labels

`bug`, `menu-bar`, `phase-1`, `blocking`
