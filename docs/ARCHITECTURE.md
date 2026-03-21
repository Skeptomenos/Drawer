# Drawer Architecture

This document explains how Drawer works under the hood. Understanding these concepts is essential for contributing to the codebase.

## Overview

Drawer is a macOS menu bar utility that hides icons into a secondary, collapsible panel. It achieves this through a clever technique called the **"10k Pixel Hack"** combined with **ScreenCaptureKit** for icon visualization.

```
┌─────────────────────────────────────────────────────────────────────────┐
│ Menu Bar                                                                │
│  [App Icons] ● < [System Icons]                                         │
│              ↑ ↑                                                        │
│              │ └── Toggle Button (collapse/expand)                      │
│              └──── Separator (expands to 10,000px when collapsed)       │
└─────────────────────────────────────────────────────────────────────────┘
```

## Core Components

### 1. MenuBarManager (The Heart)

**File**: `Drawer/Core/Managers/MenuBarManager.swift`

The MenuBarManager implements the **"10k Pixel Hack"** - the core technique that makes icon hiding possible.

#### How the 10k Pixel Hack Works

macOS menu bar items are `NSStatusItem` objects. Each has a `length` property that determines its width. The hack exploits this:

1. **Separator Item**: An invisible `NSStatusItem` positioned between "hidden" and "visible" icons
2. **Collapsed State**: Separator length = **10,000 pixels**, pushing hidden icons off-screen (beyond the left edge)
3. **Expanded State**: Separator length = **20 pixels**, allowing all icons to be visible

```swift
private let separatorExpandedLength: CGFloat = 20
private let separatorCollapsedLength: CGFloat = 10000

func collapse() {
    separatorItem.length = separatorCollapsedLength  // 10,000px - icons pushed off-screen
    toggleItem.button?.image = expandImage           // Show ">" to indicate expandable
    isCollapsed = true
}

func expand() {
    separatorItem.length = separatorExpandedLength   // 20px - icons visible
    toggleItem.button?.image = collapseImage         // Show "<" to indicate collapsible
    isCollapsed = false
}
```

#### RTL Language Support

The manager detects the system's layout direction and adjusts:
- Toggle icon direction (`chevron.left` vs `chevron.right`)
- Position validation logic

#### Key Properties

| Property | Type | Description |
|----------|------|-------------|
| `isCollapsed` | `Bool` | Current collapse state |
| `isToggling` | `Bool` | Debounce flag to prevent rapid toggles |
| `toggleItem` | `NSStatusItem` | The clickable `<`/`>` button |
| `separatorItem` | `NSStatusItem` | The expandable separator (the "hack") |

---

### 2. IconCapturer (Screen Capture Engine)

**File**: `Drawer/Core/Engines/IconCapturer.swift`

When the Drawer panel needs to display hidden icons, IconCapturer uses **ScreenCaptureKit** to capture them.

#### Capture Flow

```
1. Expand menu bar (make icons visible)
2. Wait for render (50ms)
3. Capture using window-based detection OR ScreenCaptureKit
4. Slice into individual icons
5. Collapse menu bar
6. Return captured icons
```

#### Two Capture Strategies

**Primary: Window-Based Capture**
- Uses `MenuBarItem.getMenuBarItemsForDisplay()` to enumerate menu bar windows
- Captures each window individually via `ScreenCapture.captureMenuBarItems()`
- More accurate icon boundaries

**Fallback: ScreenCaptureKit Region Capture**
- Captures the entire menu bar region
- Slices into icons using fixed-width estimation (22px per icon)
- Used when window enumeration fails

#### Key Types

```swift
struct CapturedIcon {
    let id: UUID
    let image: CGImage
    let originalFrame: CGRect      // Position in menu bar
    let itemInfo: MenuBarItemInfo? // Window metadata
}

struct MenuBarCaptureResult {
    let fullImage: CGImage
    let icons: [CapturedIcon]
    let capturedRegion: CGRect
    let menuBarItems: [MenuBarItem]
}
```

---

### 3. DrawerPanelController (UI Presentation)

**File**: `Drawer/UI/Panels/DrawerPanelController.swift`

Manages the floating panel that displays captured icons.

#### Panel Characteristics

- **Type**: `NSPanel` (floating, non-activating)
- **Level**: Above menu bar
- **Material**: `NSVisualEffectView` with `.hudWindow` material
- **Behavior**: Click-through to underlying windows

#### Animation System

```swift
// Show: Slide down + fade in
startFrame.origin.y += 12  // Start above
panel.alphaValue = 0
// Animate to final position with spring timing

// Hide: Slide up + fade out
endFrame.origin.y += 6
panel.alphaValue = 0
```

#### Styling (DrawerDesign)

| Constant | Value | Purpose |
|----------|-------|---------|
| `cornerRadius` | 11pt | Rounded corners |
| `shadowRadius` | 12pt | Drop shadow |
| `rimLightOpacity` | 0.175 | Top highlight |
| `drawerHeight` | 34pt | Panel height |

---

### 4. HoverManager (Mouse Tracking)

**File**: `Drawer/Core/Managers/HoverManager.swift`

Enables "show on hover" functionality by monitoring global mouse events.

#### Trigger Zones

```
┌─────────────────────────────────────────────────────────────────────────┐
│ TRIGGER ZONE (menu bar height)                                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│                        ┌─────────────────┐                              │
│                        │  DRAWER PANEL   │ ← Safe zone (10px padding)   │
│                        └─────────────────┘                              │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

#### Debouncing

| Action | Delay | Purpose |
|--------|-------|---------|
| Show | 150ms | Prevent accidental triggers |
| Hide | 300ms | Allow cursor to move between zones |

#### Callbacks

```swift
var onShouldShowDrawer: (() -> Void)?
var onShouldHideDrawer: (() -> Void)?
```

---

### 5. EventSimulator (Click Forwarding)

**File**: `Drawer/Utilities/EventSimulator.swift`

Forwards clicks from Drawer panel icons to the actual menu bar items.

#### Click Simulation Sequence

```
1. Move cursor to target position
2. Wait 10ms
3. Post mouseDown event
4. Wait 50ms
5. Post mouseUp event
```

#### Permission Requirement

Uses `CGEvent` posting, which requires **Accessibility** permission:

```swift
var hasAccessibilityPermission: Bool {
    AXIsProcessTrusted()
}
```

---

### 6. PermissionManager

**File**: `Drawer/Core/Managers/PermissionManager.swift`

Handles macOS TCC (Transparency, Consent, and Control) permissions.

#### Required Permissions

| Permission | Purpose | Check Method |
|------------|---------|--------------|
| Screen Recording | Capture menu bar icons | `CGPreflightScreenCaptureAccess()` |
| Accessibility | Simulate clicks | `AXIsProcessTrusted()` |

---

## Data Flow

### Collapse/Expand Flow

```
User clicks toggle
        │
        ▼
MenuBarManager.toggle()
        │
        ├─── isCollapsed? ───┐
        │                    │
        ▼                    ▼
    expand()             collapse()
        │                    │
        ▼                    ▼
separator.length = 20   separator.length = 10000
        │                    │
        ▼                    ▼
Icons slide in          Icons pushed off-screen
```

### Show Drawer Flow

```
HoverManager detects mouse in trigger zone
        │
        ▼
onShouldShowDrawer callback
        │
        ▼
IconCapturer.captureHiddenIcons()
        │
        ├─── Expand menu bar
        ├─── Capture icons
        └─── Collapse menu bar
        │
        ▼
DrawerPanelController.show(content: icons)
        │
        ▼
Panel animates in with captured icons
```

### Click-Through Flow

```
User clicks icon in Drawer panel
        │
        ▼
Get original icon position from CapturedIcon.originalFrame
        │
        ▼
EventSimulator.simulateClick(at: originalPosition)
        │
        ▼
CGEvent posted to menu bar
        │
        ▼
Original app receives click
```

---

## Key Design Decisions

### Why 10,000 Pixels?

The value must be large enough to push all possible icons off-screen. With 4K+ displays and potential for many menu bar items, 10,000px provides ample margin.

### Why ScreenCaptureKit?

- **Modern API**: Replaces deprecated `CGWindowListCreateImage`
- **Performance**: Hardware-accelerated capture
- **Privacy**: Respects system permissions

### Why NSPanel?

- **Non-activating**: Doesn't steal focus from current app
- **Floating**: Stays above other windows
- **Click-through**: Can forward events to underlying windows

### Why Combine?

- **Reactive state**: `@Published` properties for UI binding
- **Debouncing**: Built-in operators for timing control
- **Memory safety**: Automatic subscription management

---

## File Structure

```
Drawer/
├── App/
│   ├── DrawerApp.swift          # @main entry point
│   ├── AppDelegate.swift        # NSApplicationDelegate
│   └── AppState.swift           # Global state coordinator
├── Core/
│   ├── Managers/
│   │   ├── MenuBarManager.swift     # 10k pixel hack
│   │   ├── DrawerManager.swift      # Drawer lifecycle
│   │   ├── PermissionManager.swift  # TCC permissions
│   │   ├── SettingsManager.swift    # User preferences
│   │   ├── HoverManager.swift       # Mouse tracking
│   │   └── LaunchAtLoginManager.swift
│   └── Engines/
│       └── IconCapturer.swift       # ScreenCaptureKit
├── UI/
│   ├── Panels/
│   │   ├── DrawerPanel.swift            # NSPanel subclass
│   │   ├── DrawerPanelController.swift  # Panel management
│   │   └── DrawerContentView.swift      # Icon rendering
│   ├── Settings/                    # Preferences views
│   ├── Onboarding/                  # First-run experience
│   └── Components/                  # Reusable UI elements
├── Models/
│   ├── DrawerItem.swift             # Drawer item model
│   ├── MenuBarItem.swift            # Menu bar window info
│   └── MenuBarMetrics.swift         # Sizing constants
├── Utilities/
│   ├── EventSimulator.swift         # Click forwarding
│   ├── GlobalEventMonitor.swift     # Mouse event monitoring
│   ├── ScreenCapture.swift          # Capture helpers
│   └── Notification+Extensions.swift # Custom notifications
└── Bridging/
    └── PrivateAPIs.swift            # Private API declarations
```

---

## Testing Considerations

### Unit Testable Components

- `SettingsManager` - Pure state management
- `MenuBarManager` - State transitions (mock NSStatusItem)
- `HoverManager` - Zone detection logic

### Integration Testing

- Permission flows require manual testing
- Screen capture requires actual display
- Click simulation requires Accessibility permission

### Manual Verification Checklist

1. Toggle expands/collapses correctly
2. Icons respond to Cmd+Drag repositioning
3. Hover triggers drawer appearance
4. Click-through works for all icon types
5. RTL layout works correctly
6. Multi-display scenarios work

---

## Performance Notes

### Memory

- Captured icons are `CGImage` objects - dispose when drawer hides
- Combine subscriptions stored in `Set<AnyCancellable>` - cleared on deinit

### CPU

- Global mouse monitoring runs continuously when hover enabled
- Debouncing prevents excessive event processing

### GPU

- `NSVisualEffectView` uses GPU compositing
- ScreenCaptureKit uses hardware acceleration

---

## Security Considerations

### Permissions

- Never bypass TCC programmatically
- Always use `PermissionManager` for permission flows
- Handle permission denial gracefully

### Event Simulation

- Only simulate clicks at valid screen coordinates
- Validate target positions before posting events
- Log all simulated events for debugging

---

## References

- [NSStatusItem Documentation](https://developer.apple.com/documentation/appkit/nsstatusitem)
- [ScreenCaptureKit Documentation](https://developer.apple.com/documentation/screencapturekit)
- [CGEvent Documentation](https://developer.apple.com/documentation/coregraphics/cgevent)
- [NSPanel Documentation](https://developer.apple.com/documentation/appkit/nspanel)
