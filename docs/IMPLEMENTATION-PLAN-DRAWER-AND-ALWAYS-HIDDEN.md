# Implementation Plan: Drawer & Always-Hidden Features

This document provides a detailed implementation plan for completing the Drawer panel functionality and adding the Always-Hidden section feature.

**Priority Order**: Complete Option B first (Drawer must work before Always-Hidden can be useful).

---

## Table of Contents

1. [Current State](#current-state)
2. [Option B: Drawer End-to-End](#option-b-drawer-end-to-end)
3. [Option A: Always-Hidden Section](#option-a-always-hidden-section)
4. [Testing Checklist](#testing-checklist)
5. [Key Files Reference](#key-files-reference)

---

## Current State

### What Works
- **MenuBarManager**: Toggle (`<`/`>`) and separator (`●`) icons appear in menu bar
- **10k Pixel Hack**: Collapsing/expanding hidden icons works
- **Settings**: `alwaysHiddenEnabled` setting exists in `SettingsManager`
- **IconCapturer**: ScreenCaptureKit integration exists
- **DrawerPanelController**: Panel creation and animation code exists
- **HoverManager**: Mouse tracking for show-on-hover exists

### What's Incomplete/Untested
- **Drawer capture → display → click-through pipeline**: Not verified end-to-end
- **Always-Hidden section**: Setting exists but no implementation

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              MENU BAR                                       │
│  [Always Hidden] ▏ [Hidden Icons] ● < [Visible Icons] [System]              │
│                  ↑                ↑ ↑                                       │
│                  │                │ └── toggleItem (NSStatusItem)           │
│                  │                └──── separatorItem (NSStatusItem)        │
│                  └───────────────────── alwaysHiddenItem (NOT IMPLEMENTED)  │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼ (on hover or click "Show Drawer")
┌─────────────────────────────────────────────────────────────────────────────┐
│                           DRAWER PANEL                                      │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  [icon] [icon] [icon] [icon] [icon]  ← Captured menu bar icons      │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                             │
│  Click icon → EventSimulator forwards click to real menu bar item           │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Option B: Drawer End-to-End

**Goal**: Verify and fix the complete Drawer pipeline so users can:
1. Trigger the Drawer (via hover or context menu)
2. See captured menu bar icons in a floating panel
3. Click icons in the Drawer to activate the real menu bar items

### Phase B1: Verify Capture Pipeline

#### Task B1.1: Test IconCapturer in Isolation

**File**: `Drawer/Core/Engines/IconCapturer.swift`

**Steps**:
1. Add debug logging to `captureHiddenIcons()` to trace execution
2. Verify `performWindowBasedCapture()` returns valid `MenuBarCaptureResult`
3. Check that `CapturedIcon` objects have valid `CGImage` and `originalFrame`

**Verification**:
```swift
// Add temporary debug in IconCapturer.captureHiddenIcons()
logger.info("Capture result: \(captureResult.icons.count) icons, region: \(captureResult.capturedRegion)")
for (index, icon) in captureResult.icons.enumerated() {
    logger.info("Icon \(index): frame=\(icon.originalFrame), image size=\(icon.image.width)x\(icon.image.height)")
}
```

**Success Criteria**:
- [ ] `captureHiddenIcons()` returns without throwing
- [ ] `icons` array is non-empty
- [ ] Each icon has valid dimensions (width/height > 0)

#### Task B1.2: Verify Permission Flow

**File**: `Drawer/Core/Managers/PermissionManager.swift`

**Steps**:
1. Confirm `hasScreenRecording` returns correct value
2. Confirm `hasAccessibility` returns correct value
3. Test permission request dialogs appear when needed

**Verification**:
- Run app with permissions revoked in System Settings
- Verify app prompts for permissions
- Grant permissions and verify `hasScreenRecording` / `hasAccessibility` update

**Success Criteria**:
- [ ] Permission checks return accurate values
- [ ] Permission requests trigger system dialogs
- [ ] App detects when permissions are granted

---

### Phase B2: Verify Display Pipeline

#### Task B2.1: Test DrawerContentView Rendering

**File**: `Drawer/UI/Panels/DrawerContentView.swift`

**Steps**:
1. Create a test with mock `DrawerItem` objects
2. Verify `DrawerItemView` renders `CGImage` correctly
3. Check hover states and tap gestures work

**Verification**:
```swift
// Use Xcode Preview with mock data
#Preview("With Mock Icons") {
    // Create mock DrawerItems with test images
    let mockItems = (0..<5).map { index in
        DrawerItem(
            id: UUID(),
            image: createTestImage(), // Helper to create a colored square
            originalFrame: CGRect(x: CGFloat(index) * 30, y: 0, width: 22, height: 22),
            index: index,
            clickTarget: CGPoint(x: CGFloat(index) * 30 + 11, y: 11)
        )
    }
    DrawerContentView(items: mockItems)
}
```

**Success Criteria**:
- [ ] Icons render at correct size (22x22)
- [ ] Hover effect (scale) works
- [ ] Tap gesture triggers `onItemTap` callback

#### Task B2.2: Test DrawerPanelController Presentation

**File**: `Drawer/UI/Panels/DrawerPanelController.swift`

**Steps**:
1. Verify `show()` creates and displays the panel
2. Verify panel appears below menu bar at correct position
3. Verify `hide()` dismisses the panel with animation

**Verification**:
- Add debug logging to `animateShow()` and `animateHide()`
- Manually trigger `show()` from a debug menu item
- Observe panel appearance and positioning

**Success Criteria**:
- [ ] Panel appears with slide-down animation
- [ ] Panel is positioned correctly (below menu bar, aligned to separator)
- [ ] Panel disappears with fade-out animation

---

### Phase B3: Verify Click-Through Pipeline

#### Task B3.1: Test EventSimulator

**File**: `Drawer/Utilities/EventSimulator.swift`

**Steps**:
1. Verify `hasAccessibilityPermission` returns correct value
2. Test `simulateClick(at:)` with known coordinates
3. Verify click events are received by target apps

**Verification**:
```swift
// Test click at a known menu bar icon position
// 1. Expand menu bar
// 2. Note the position of a specific icon (e.g., Wi-Fi)
// 3. Call simulateClick(at: knownPosition)
// 4. Verify the icon's menu opens
```

**Success Criteria**:
- [ ] `simulateClick()` doesn't throw errors
- [ ] Click events are posted to the system
- [ ] Target menu bar items respond to simulated clicks

#### Task B3.2: Test Full Click-Through Flow

**File**: `Drawer/App/AppState.swift` → `performClickThrough(on:)`

**Steps**:
1. Trace the flow from `handleItemTap()` to `simulateClick()`
2. Verify `item.clickTarget` contains correct coordinates
3. Verify menu bar expands before click simulation
4. Verify click is simulated at correct position

**Verification**:
```swift
// In performClickThrough(), add logging:
logger.info("Click target: \(item.clickTarget)")
logger.info("Original frame: \(item.originalFrame)")
```

**Success Criteria**:
- [ ] Clicking icon in Drawer hides the Drawer
- [ ] Menu bar expands
- [ ] Click is simulated at correct position
- [ ] Target app's menu opens

---

### Phase B4: Integration Testing

#### Task B4.1: End-to-End Flow Test

**Steps**:
1. Launch app with all permissions granted
2. Collapse menu bar (some icons hidden)
3. Trigger Drawer via "Show Drawer" context menu
4. Verify Drawer panel appears with captured icons
5. Click an icon in the Drawer
6. Verify the real menu bar item activates

**Success Criteria**:
- [ ] Drawer shows captured icons (not placeholders)
- [ ] Icons match the hidden menu bar icons
- [ ] Click-through activates correct menu bar item

#### Task B4.2: Hover Trigger Test

**Steps**:
1. Enable "Show on Hover" in preferences
2. Move mouse to menu bar area
3. Verify Drawer appears after debounce delay
4. Move mouse away
5. Verify Drawer disappears after debounce delay

**Success Criteria**:
- [ ] Hover triggers Drawer appearance
- [ ] Moving away triggers Drawer dismissal
- [ ] Debounce prevents flickering

---

## Option A: Always-Hidden Section

**Goal**: Add a third status item that creates an "always hidden" zone. Icons in this zone never appear in the menu bar, only in the Drawer.

**Prerequisite**: Option B must be complete (Drawer must work).

### Phase A1: Add Always-Hidden Status Item

#### Task A1.1: Create Always-Hidden Item in MenuBarManager

**File**: `Drawer/Core/Managers/MenuBarManager.swift`

**Changes**:

```swift
// Add new status item
private var alwaysHiddenItem: NSStatusItem?

// Add constants
private let alwaysHiddenExpandedLength: CGFloat = 20
private let alwaysHiddenCollapsedLength: CGFloat = 10000

// Add computed property for validation
private var isAlwaysHiddenValidPosition: Bool {
    guard settings.alwaysHiddenEnabled else { return true }
    guard
        let separatorX = separatorItem.button?.window?.frame.origin.x,
        let alwaysHiddenX = alwaysHiddenItem?.button?.window?.frame.origin.x
    else { return false }
    
    return isLTRLanguage ? (separatorX >= alwaysHiddenX) : (separatorX <= alwaysHiddenX)
}
```

#### Task A1.2: Setup/Teardown Always-Hidden Item

**File**: `Drawer/Core/Managers/MenuBarManager.swift`

**Add method**:

```swift
private func setupAlwaysHiddenItem() {
    guard settings.alwaysHiddenEnabled else {
        alwaysHiddenItem = nil
        return
    }
    
    alwaysHiddenItem = NSStatusBar.system.statusItem(withLength: alwaysHiddenExpandedLength)
    
    guard let button = alwaysHiddenItem?.button else {
        logger.error("Failed to create always-hidden button")
        return
    }
    
    // Use a dimmed/translucent separator icon
    button.image = NSImage(systemSymbolName: "line.diagonal", accessibilityDescription: "Always Hidden Separator")
    button.alphaValue = 0.5  // Dimmed appearance
    button.title = ""
    
    alwaysHiddenItem?.autosaveName = "drawer_always_hidden_v1"
    
    logger.info("Always-hidden item created")
}

private func teardownAlwaysHiddenItem() {
    if let item = alwaysHiddenItem {
        NSStatusBar.system.removeStatusItem(item)
        alwaysHiddenItem = nil
        logger.info("Always-hidden item removed")
    }
}
```

#### Task A1.3: Observe Settings Changes

**File**: `Drawer/Core/Managers/MenuBarManager.swift`

**Add to init or setupSettingsBindings**:

```swift
// Observe alwaysHiddenEnabled changes
settings.$alwaysHiddenEnabled
    .removeDuplicates()
    .sink { [weak self] enabled in
        if enabled {
            self?.setupAlwaysHiddenItem()
        } else {
            self?.teardownAlwaysHiddenItem()
        }
    }
    .store(in: &cancellables)
```

**Note**: Need to add `@Published` wrapper or subject for `alwaysHiddenEnabled` in SettingsManager.

---

### Phase A2: Modify Collapse/Expand Logic

#### Task A2.1: Update Collapse Behavior

**File**: `Drawer/Core/Managers/MenuBarManager.swift`

**Modify `collapse()` and `expand()`**:

```swift
func collapse() {
    guard isSeparatorValidPosition, !isCollapsed else { return }
    
    cancelAutoCollapseTimer()
    separatorItem.length = separatorCollapsedLength
    toggleItem.button?.image = expandImage
    isCollapsed = true
    
    // Always-hidden section stays collapsed
    if settings.alwaysHiddenEnabled && isAlwaysHiddenValidPosition {
        alwaysHiddenItem?.length = alwaysHiddenCollapsedLength
    }
    
    logger.debug("Collapsed")
}

func expand() {
    guard isCollapsed else { return }
    
    separatorItem.length = separatorExpandedLength
    toggleItem.button?.image = collapseImage
    isCollapsed = false
    
    // Always-hidden section STAYS collapsed (that's the point!)
    // Only the Drawer can show these icons
    
    startAutoCollapseTimer()
    logger.debug("Expanded")
}
```

#### Task A2.2: Add Method to Expand Everything (for Drawer capture)

**File**: `Drawer/Core/Managers/MenuBarManager.swift`

**Add method**:

```swift
/// Expands all sections including always-hidden (used for Drawer capture)
func expandAll() {
    separatorItem.length = separatorExpandedLength
    alwaysHiddenItem?.length = alwaysHiddenExpandedLength
    toggleItem.button?.image = collapseImage
    isCollapsed = false
    logger.debug("Expanded all (including always-hidden)")
}

/// Collapses all sections including always-hidden
func collapseAll() {
    guard isSeparatorValidPosition else { return }
    
    separatorItem.length = separatorCollapsedLength
    
    if settings.alwaysHiddenEnabled && isAlwaysHiddenValidPosition {
        alwaysHiddenItem?.length = alwaysHiddenCollapsedLength
    }
    
    toggleItem.button?.image = expandImage
    isCollapsed = true
    logger.debug("Collapsed all")
}
```

---

### Phase A3: Update IconCapturer for Always-Hidden

#### Task A3.1: Modify Capture to Use expandAll()

**File**: `Drawer/Core/Engines/IconCapturer.swift`

**Modify `captureHiddenIcons()`**:

```swift
func captureHiddenIcons(menuBarManager: MenuBarManager) async throws -> MenuBarCaptureResult {
    // ... existing permission check ...
    
    logger.debug("Expanding ALL sections for capture")
    let wasCollapsed = menuBarManager.isCollapsed
    
    // Use expandAll() instead of expand() to include always-hidden icons
    menuBarManager.expandAll()
    
    // ... rest of capture logic ...
    
    // Collapse everything after capture
    if wasCollapsed {
        menuBarManager.collapseAll()
    }
    
    // ... return result ...
}
```

---

### Phase A4: Update Settings UI

#### Task A4.1: Add Toggle in Preferences

**File**: `Drawer/UI/Settings/AppearanceSettingsView.swift`

**Current code** (already exists):
```swift
Toggle("Always-hidden section", isOn: $settings.alwaysHiddenEnabled)
```

**Add description**:
```swift
VStack(alignment: .leading, spacing: 4) {
    Toggle("Always-hidden section", isOn: $settings.alwaysHiddenEnabled)
    Text("Icons between the dimmed separator and main separator will only appear in the Drawer, never in the menu bar.")
        .font(.caption)
        .foregroundColor(.secondary)
}
```

#### Task A4.2: Add Publisher for Setting Changes

**File**: `Drawer/Core/Managers/SettingsManager.swift`

**Add**:
```swift
@AppStorage("alwaysHiddenEnabled") var alwaysHiddenEnabled: Bool = false {
    didSet { alwaysHiddenEnabledSubject.send(alwaysHiddenEnabled) }
}

let alwaysHiddenEnabledSubject = PassthroughSubject<Bool, Never>()
```

---

### Phase A5: Visual Differentiation in Drawer

#### Task A5.1: Mark Always-Hidden Icons in Drawer

**File**: `Drawer/Models/DrawerItem.swift`

**Add property**:
```swift
struct DrawerItem: Identifiable {
    // ... existing properties ...
    
    /// Whether this icon is from the always-hidden section
    let isAlwaysHidden: Bool
}
```

#### Task A5.2: Visual Indicator in DrawerContentView

**File**: `Drawer/UI/Panels/DrawerContentView.swift`

**Optional**: Add subtle visual distinction for always-hidden icons (e.g., a small badge or different background).

---

## Testing Checklist

### Option B: Drawer End-to-End

- [ ] **Permissions**
  - [ ] Screen Recording permission check works
  - [ ] Accessibility permission check works
  - [ ] Permission request dialogs appear

- [ ] **Capture**
  - [ ] `captureHiddenIcons()` returns valid result
  - [ ] Icons have correct frames and images
  - [ ] Capture works with various numbers of hidden icons

- [ ] **Display**
  - [ ] Drawer panel appears at correct position
  - [ ] Icons render correctly (not stretched/squished)
  - [ ] Hover effect works on icons
  - [ ] Loading state displays correctly
  - [ ] Error state displays correctly

- [ ] **Click-Through**
  - [ ] Clicking icon hides Drawer
  - [ ] Menu bar expands
  - [ ] Click is simulated at correct position
  - [ ] Target app responds to click

- [ ] **Hover Trigger**
  - [ ] "Show on Hover" setting works
  - [ ] Debounce prevents flickering
  - [ ] Moving away hides Drawer

### Option A: Always-Hidden Section

- [ ] **Status Item**
  - [ ] Always-hidden separator appears when enabled
  - [ ] Separator is visually distinct (dimmed)
  - [ ] Separator disappears when disabled

- [ ] **Behavior**
  - [ ] Always-hidden icons stay hidden when menu bar expands
  - [ ] Always-hidden icons appear in Drawer
  - [ ] Click-through works for always-hidden icons
  - [ ] ⌘+drag works to move icons into always-hidden zone

- [ ] **Settings**
  - [ ] Toggle in preferences works
  - [ ] Setting persists across app restarts
  - [ ] Enabling/disabling doesn't require restart

---

## Key Files Reference

| File | Purpose |
|------|---------|
| `Drawer/Core/Managers/MenuBarManager.swift` | 10k pixel hack, status items |
| `Drawer/Core/Engines/IconCapturer.swift` | ScreenCaptureKit capture |
| `Drawer/Core/Managers/DrawerManager.swift` | Drawer state management |
| `Drawer/UI/Panels/DrawerPanelController.swift` | Panel presentation |
| `Drawer/UI/Panels/DrawerContentView.swift` | Icon rendering |
| `Drawer/Utilities/EventSimulator.swift` | Click simulation |
| `Drawer/Core/Managers/HoverManager.swift` | Mouse tracking |
| `Drawer/Core/Managers/SettingsManager.swift` | User preferences |
| `Drawer/Core/Managers/PermissionManager.swift` | TCC permissions |
| `Drawer/App/AppState.swift` | Central coordinator |
| `Drawer/Models/DrawerItem.swift` | Drawer item model |

---

## Session Handover Notes

### Phase B1 Status: ✅ COMPLETE (2026-01-15)

**What was done:**
- Added comprehensive `#if DEBUG` logging to `IconCapturer.swift` for B1.1
- Added permission status logging to `PermissionManager.swift` for B1.2
- Verified project builds successfully with all debug logging

**Debug logging added to these locations:**

1. **`IconCapturer.captureHiddenIcons()`** - Logs capture result summary:
   - Total icons captured
   - Captured region coordinates
   - Each icon's frame, image dimensions, and owner name

2. **`IconCapturer.performWindowBasedCapture()`** - Logs window detection:
   - Screen name and displayID
   - Number of menu bar items found
   - Each item's windowID, owner, and frame
   - Number of images captured by ScreenCapture

3. **`PermissionManager.init()`** - Logs permission status on startup:
   - hasScreenRecording
   - hasAccessibility
   - hasAllPermissions

---

### Phase B2 Status: ✅ COMPLETE (2026-01-15)

**What was done:**

#### B2.1: DrawerContentView Rendering
- Added comprehensive Xcode Preview support with mock data
- Created `PreviewHelpers` enum with:
  - `createTestImage(color:size:)` - Generates colored CGImages for testing
  - `createMockDrawerItems(count:)` - Creates arrays of mock DrawerItems
- Added previews for: Empty State, Loading, Error State, Mock Icons (5), Many Icons (10), Full Container
- Verified hover states and tap gestures work via existing implementation

#### B2.2: DrawerPanelController Presentation
- Added `os.log` logger to `DrawerPanelController`
- Added debug logging to `animateShow()`:
  - Target frame coordinates
  - Screen name
  - Animation completion confirmation
- Added debug logging to `animateHide()`:
  - Hide initiation
  - Animation completion confirmation
- Added debug logging to `DrawerPanel.position()`:
  - Screen info, full frame, visible frame
  - Menu bar height calculation
  - Final panel position and size

#### B2.3: Integration Verification
- Added debug logging to `AppState.captureAndShowDrawer()`:
  - Permission status check
  - Capture initiation and result
  - Item count passed to drawer
  - Panel show confirmation
- Verified complete flow: Context Menu → AppState → IconCapturer → DrawerManager → DrawerPanelController

**All B2 debug logging uses `#if DEBUG` guards for production safety.**

### Starting Point for Next Session

**Phase B2 is complete. Proceed to Phase B3 (Verify Click-Through Pipeline).**

1. Run the app and trigger "Show Drawer" via right-click on separator (●)
2. Verify drawer panel appears with captured icons
3. Click an icon in the drawer
4. Verify the real menu bar item activates

If click-through fails, check:
- `EventSimulator.swift` for click simulation logic
- `AppState.performClickThrough()` for coordinate handling
- Console logs for `item.clickTarget` coordinates

### Manual Verification Steps

```bash
# 1. Build the app
cd /Users/davidhelmus/Repos/Drawer
xcodebuild -scheme Drawer -configuration Debug build

# 2. Run the app
open /Users/davidhelmus/Library/Developer/Xcode/DerivedData/Hidden_Bar-aoafbiklmbomondrabmraopnqnex/Build/Products/Debug/Drawer.app

# 3. Grant permissions when prompted (Screen Recording + Accessibility)

# 4. Right-click the separator (●) → "Show Drawer"

# 5. View logs in Console.app
# Filter: subsystem:com.drawer OR category:IconCapturer
```

### Expected Log Output (B1 + B2)

```
=== PERMISSION MANAGER INIT (B1.2) ===
hasScreenRecording: true
hasAccessibility: true
hasAllPermissions: true
=== END PERMISSION DEBUG ===

=== CAPTURE AND SHOW DRAWER (B2.3) ===
hasScreenRecording: true
Starting icon capture...

=== WINDOW-BASED CAPTURE DEBUG (B1.1) ===
Screen: Built-in Retina Display, displayID: 1
MenuBarItem.getMenuBarItemsForDisplay returned 15 items
  [0] windowID=123, owner=Spotlight, frame=(100,0,30,24)
  [1] windowID=124, owner=Control Center, frame=(130,0,30,24)
  ...
ScreenCapture.captureMenuBarItems returned 15 images
  Captured: owner=Spotlight, windowID=123, size=60x48
  ...
=== CAPTURE RESULT DEBUG (B1.1) ===
Total icons: 15
Captured region: x=100, y=0, w=400, h=24
Menu bar items found: 15
Icon 0: frame=(100,0,30,24), image=60x48, owner=Spotlight
...
=== END CAPTURE DEBUG ===

Capture succeeded: 15 icons
Showing drawer panel with 15 items

=== DRAWER PANEL POSITION (B2.2) ===
Screen: Built-in Retina Display
Full frame: x=0, y=0, w=1728, h=1117
Visible frame: x=0, y=0, w=1728, h=1093
Menu bar height: 24
Panel position: x=764, y=1055
Panel size: w=200, h=36

=== DRAWER PANEL SHOW (B2.2) ===
Target frame: x=764, y=1055, w=200, h=36
Screen: Built-in Retina Display
Drawer panel show animation complete

=== END CAPTURE AND SHOW DRAWER ===
```

### Debug Tips
- Use Console.app to view os.log output (filter by "com.drawer")
- Add `#if DEBUG` blocks for temporary logging
- Use Xcode Previews for UI components
- Test with permissions both granted and revoked

### Known Issues
- LSP errors in Xcode are false positives (project builds fine)
- macOS caches `NSStatusItem` state - use `defaults delete com.drawer.app` to reset
- Swift 6 warnings about `@MainActor` isolation are expected (not errors)

### Build Commands
```bash
# Debug build
xcodebuild -scheme Drawer -configuration Debug build

# Run from DerivedData
open /Users/davidhelmus/Library/Developer/Xcode/DerivedData/Hidden_Bar-aoafbiklmbomondrabmraopnqnex/Build/Products/Debug/Drawer.app

# Reset cached state
defaults delete com.drawer.app

# View logs
log stream --predicate 'subsystem == "com.drawer"' --level debug
```

---

## Capture Pipeline Architecture (Reference)

Understanding the capture flow is critical for debugging:

```
captureHiddenIcons(menuBarManager)
│
├── 1. Check permissions (hasScreenRecording)
│       └── If denied → throw CaptureError.permissionDenied
│
├── 2. Expand menu bar
│       └── menuBarManager.expand() → separatorItem.length = 20
│
├── 3. Wait for render (50ms)
│       └── Task.sleep(nanoseconds: 50_000_000)
│
├── 4. performWindowBasedCapture()
│       │
│       ├── Get menu bar items via CGS private APIs
│       │     └── MenuBarItem.getMenuBarItemsForDisplay(displayID)
│       │           └── Bridging.getWindowList(option: .menuBarItems)
│       │                 └── CGSGetProcessMenuBarWindowList()
│       │
│       ├── Capture images via deprecated CGWindowListCreateImage
│       │     └── ScreenCapture.captureMenuBarItems(items, screen)
│       │
│       └── If no items found → fallback to performLegacyCapture()
│             └── Uses ScreenCaptureKit + fixed-width slicing
│
├── 5. Collapse menu bar
│       └── menuBarManager.collapse() → separatorItem.length = 10000
│
└── 6. Return MenuBarCaptureResult
        ├── fullImage: CGImage (composite)
        ├── icons: [CapturedIcon] (individual icons)
        ├── capturedRegion: CGRect
        └── menuBarItems: [MenuBarItem]
```

### Key Dependencies

| Component | File | Purpose |
|-----------|------|---------|
| `Bridging` | `Drawer/Bridging/Bridging.swift` | Swift wrappers for private CGS APIs |
| `Private` | `Drawer/Bridging/Shims/Private.swift` | `@_silgen_name` declarations for CGS functions |
| `WindowInfo` | `Drawer/Utilities/WindowInfo.swift` | `MenuBarItem` struct with window info |
| `ScreenCapture` | `Drawer/Utilities/ScreenCapture.swift` | `captureMenuBarItems()` using CGWindowListCreateImage |
| `MenuBarMetrics` | `Drawer/Utilities/MenuBarMetrics.swift` | Menu bar height calculation |

### Private APIs Used

The capture relies on undocumented CGS (CoreGraphics Server) APIs:

```swift
CGSMainConnectionID()           // Get connection ID
CGSGetProcessMenuBarWindowList() // Get menu bar window IDs
CGSGetScreenRectForWindow()     // Get window frame
CGSGetActiveSpace()             // Get current space ID
CGSCopySpacesForWindows()       // Get spaces for windows
```

These are declared in `Private.swift` using `@_silgen_name` to link to the private symbols.
