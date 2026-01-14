# Drawer Implementation Plan

> **Generated**: 2026-01-14 (Updated)  
> **Objective**: Transform Hidden Bar (legacy AppKit/MVC) into Drawer (modern SwiftUI/MVVM) with enhanced Bartender-like functionality.
>
> **Target**: macOS 14.0+ | Swift 5.9+ | SwiftUI-first architecture

---

## Current State Summary

### Legacy Codebase (Hidden Bar)
- **Architecture**: 100% AppKit, MVC pattern, Storyboard-based UI
- **Entry Point**: `hidden/AppDelegate.swift` with `@NSApplicationMain`
- **Core Logic**: `hidden/Features/StatusBar/StatusBarController.swift` - implements the "10k pixel hack"
- **Settings**: `hidden/Common/Preferences.swift` enum wrapping UserDefaults
- **Launch at Login**: `LauncherApplication/` helper app using deprecated `SMLoginItemSetEnabled`
- **Hotkeys**: Uses `HotKey` SPM package (v0.1.3)
- **Deployment**: Currently targets macOS 10.12-10.14
- **Files**: 22 Swift files in `hidden/`, 2 in `LauncherApplication/`

### Known Technical Debt
1. **TODO**: `hidden/Views/HyperlinkTextField.swift:25` - hover click fix needed
2. Hardcoded "Hidden Bar" branding in LauncherApplication
3. Deprecated `SMLoginItemSetEnabled` API (use `SMAppService` instead)
4. Legacy macOS 10.12 compatibility code throughout

### Visual Design Requirements (from reference images)
- **Drawer**: Pill-shaped, high corner radius (10-12pt), HUD material, 0.5pt rim light, floating shadow (15-20pt blur, 30-40% opacity)
- **Settings**: Sidebar + detail layout, platter-based grouping, SF Symbols, system accent colors

---

## Overview

This plan breaks the migration into **atomic, testable tasks** (~30 min each). Tasks are grouped by phase and ordered by dependency. Each task produces a working, verifiable increment.

### Dependency Graph (Critical Path)

```
Phase 1 (Foundation)
├── 1.1 Project Setup ──────────────────┐
│                                        ├── 1.2 MenuBarManager
├── 1.3 SettingsManager ────────────────┤
│                                        ├── 1.4 Launch at Login
└── 1.5 PermissionManager ──────────────┘

Phase 2 (Drawer Engine) - Requires Phase 1 complete
├── 2.1 DrawerPanel ────────────────────┐
│                                        ├── 2.3 DrawerItem Model
├── 2.2 IconCapturer ───────────────────┤
│                                        ├── 2.4 Click-Through
└── 2.5 EventMonitor ───────────────────┘

Phase 3 (Polish) - Requires Phase 2 complete
├── 3.1 Visual Materials
├── 3.2 Animations
├── 3.3 Settings UI
├── 3.4 Onboarding
└── 3.5 Final Polish
```

---

## Phase 1: Foundation & Refactor

**Goal**: Establish SwiftUI architecture with working hide/show functionality (no Drawer UI yet).

**Estimated Total**: 4-6 hours

---

### Task 1.1: Project Structure & SwiftUI App Lifecycle ✅

| Attribute | Value |
|-----------|-------|
| **Priority** | P0 - BLOCKER |
| **Risk** | LOW |
| **Complexity** | Short (1-2h) |
| **Dependencies** | None |
| **Blocks** | All subsequent tasks |

**Description**:
Create the new folder structure and SwiftUI App entry point. This task establishes the foundation but does NOT delete legacy code yet (parallel development).

**Steps**:
1. Create folder structure:
   ```
   Drawer/
   ├── App/
   │   └── DrawerApp.swift
   ├── Core/
   │   ├── Managers/
   │   └── Engines/
   ├── UI/
   │   ├── Components/
   │   ├── Panels/
   │   └── Settings/
   ├── Models/
   └── Utilities/
   ```
2. Create `DrawerApp.swift` with `@main` and `App` protocol
3. Add `@NSApplicationDelegateAdaptor` for AppKit bridging (needed for NSStatusItem)
4. Create minimal `AppState.swift` (ObservableObject) as central state container
5. Configure `Info.plist`: Set `LSUIElement = YES` (menu bar app, no dock icon)
6. Update deployment target to macOS 14.0

**Acceptance Criteria**:
- [x] App compiles with new SwiftUI lifecycle
- [x] App runs as menu bar app (no dock icon)
- [x] Folder structure matches spec
- [x] Legacy code remains functional (not deleted)

**Verification**:
```bash
xcodebuild -scheme Drawer -configuration Debug build
# Run app, verify no dock icon appears
```

---

### Task 1.2: Port StatusBarController → MenuBarManager ✅

| Attribute | Value |
|-----------|-------|
| **Priority** | P0 - BLOCKER |
| **Risk** | MEDIUM |
| **Complexity** | Medium (2-3h) |
| **Dependencies** | Task 1.1 |
| **Blocks** | Tasks 2.1-2.5 |

**Description**:
Extract the "10k pixel hack" from `StatusBarController.swift` into a clean, observable `MenuBarManager`. This is the **heart of the app** - handle with care.

**Key Logic to Port** (from StatusBarController.swift):
- `btnExpandCollapse` → Toggle button (visible)
- `btnSeparate` → Separator (the "barrier")
- `btnHiddenCollapseLength = 10000` → The hiding mechanism
- `isBtnSeparateValidPosition` → RTL language support
- `autosaveName` → Position persistence

**Steps**:
1. Create `Core/Managers/MenuBarManager.swift`
2. Implement as `ObservableObject` with `@Published` state:
   ```swift
   @Published var isCollapsed: Bool = true
   @Published var isToggling: Bool = false // Debounce protection
   ```
3. Create NSStatusItems:
   - `toggleItem`: Variable length, click handler
   - `separatorItem`: Length toggles between 20 and 10000
4. Implement `toggle()` with debounce (0.3s, matching original)
5. Handle RTL languages (check `NSApplication.shared.userInterfaceLayoutDirection`)
6. Set `autosaveName` for position persistence
7. Wire to `DrawerApp` via `@StateObject`

**Acceptance Criteria**:
- [x] Menu bar shows toggle icon
- [x] Clicking toggle expands/collapses separator
- [x] Icons to the left of separator hide when collapsed
- [x] Position persists across app restarts
- [x] RTL languages work correctly
- [x] Rapid clicks don't cause issues (debounce works)

**Verification**:
1. Build and run app
2. Arrange 3+ third-party icons to left of separator (Cmd+drag)
3. Click toggle → icons should disappear
4. Click again → icons reappear
5. Quit and relaunch → positions preserved

**Test Cases**:
```swift
func testToggleChangesState() {
    let manager = MenuBarManager()
    XCTAssertTrue(manager.isCollapsed)
    manager.toggle()
    XCTAssertFalse(manager.isCollapsed)
}

func testDebouncePreventRapidToggle() {
    let manager = MenuBarManager()
    manager.toggle()
    manager.toggle() // Should be ignored
    XCTAssertFalse(manager.isCollapsed) // Still expanded from first toggle
}
```

---

### Task 1.3: Migrate Preferences → SettingsManager ✅

| Attribute | Value |
|-----------|-------|
| **Priority** | P1 |
| **Risk** | LOW |
| **Complexity** | Short (1h) |
| **Dependencies** | Task 1.1 |
| **Blocks** | Task 1.4, Task 3.3 |

**Description**:
Replace the legacy `Preferences.swift` enum with a modern `SettingsManager` using `@AppStorage` and Combine.

**Settings to Migrate**:
| Legacy Key | New Property | Type | Default |
|------------|--------------|------|---------|
| `isAutoHide` | `autoCollapseEnabled` | Bool | true |
| `numberOfSecondForAutoHide` | `autoCollapseDelay` | Double | 10.0 |
| `isAutoStart` | `launchAtLogin` | Bool | false |
| `areSeparatorsHidden` | `hideSeparators` | Bool | false |
| `alwaysHiddenSectionEnabled` | `alwaysHiddenEnabled` | Bool | false |
| `globalKey` | `globalHotkey` | KeyCombo? | nil |

**Steps**:
1. Create `Core/Managers/SettingsManager.swift`
2. Implement as `ObservableObject` with `@AppStorage` properties
3. Add `registerDefaults()` method for first-launch values
4. Create `Combine` publishers for settings that trigger actions
5. Integrate with `MenuBarManager` for auto-collapse timer

**Acceptance Criteria**:
- [x] All settings persist across launches
- [x] Auto-collapse timer triggers after configured delay
- [x] Settings changes immediately affect app behavior
- [x] No migration needed from old keys (fresh start acceptable)

**Test Cases**:
```swift
func testAutoCollapseDelayPersists() {
    let settings = SettingsManager()
    settings.autoCollapseDelay = 5.0
    // Simulate app restart
    let settings2 = SettingsManager()
    XCTAssertEqual(settings2.autoCollapseDelay, 5.0)
}
```

---

### Task 1.4: Launch at Login (SMAppService) ✅

| Attribute | Value |
|-----------|-------|
| **Priority** | P1 |
| **Risk** | LOW |
| **Complexity** | Quick (<1h) |
| **Dependencies** | Task 1.3 |
| **Blocks** | None |

**Description**:
Replace deprecated `SMLoginItemSetEnabled` with modern `SMAppService` (macOS 13+).

**Steps**:
1. Create `Core/Managers/LaunchAtLoginManager.swift`
2. Use `SMAppService.mainApp` for registration
3. Handle errors gracefully (user may deny)
4. Remove `LauncherApplication` target entirely (no longer needed)
5. Update `SettingsManager.launchAtLogin` to use this manager

**Code Pattern**:
```swift
import ServiceManagement

final class LaunchAtLoginManager {
    static let shared = LaunchAtLoginManager()
    
    var isEnabled: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Launch at login error: \(error)")
            }
        }
    }
}
```

**Acceptance Criteria**:
- [x] Toggle adds/removes app from System Settings → Login Items
- [x] No helper app required
- [x] Errors don't crash app

**Verification**:
1. Enable "Launch at Login" in app
2. Open System Settings → General → Login Items
3. Verify "Drawer" appears in list
4. Disable in app, verify removed from list

---

### Task 1.5: PermissionManager (Accessibility + Screen Recording) ✅

| Attribute | Value |
|-----------|-------|
| **Priority** | P1 |
| **Risk** | MEDIUM |
| **Complexity** | Short (1-2h) |
| **Dependencies** | Task 1.1 |
| **Blocks** | Task 2.2, Task 2.4 |

**Description**:
Create a centralized permission manager for TCC (Transparency, Consent, and Control) permissions. Phase 1 only checks status; Phase 2 will require these permissions.

**Permissions Needed**:
| Permission | API | Required For |
|------------|-----|--------------|
| Accessibility | `AXIsProcessTrusted()` | CGEvent simulation (Phase 2) |
| Screen Recording | `CGPreflightScreenCaptureAccess()` | ScreenCaptureKit (Phase 2) |

**Steps**:
1. Create `Core/Managers/PermissionManager.swift`
2. Implement permission checking:
   ```swift
   var hasAccessibility: Bool { AXIsProcessTrusted() }
   var hasScreenRecording: Bool { CGPreflightScreenCaptureAccess() }
   ```
3. Implement permission requesting:
   ```swift
   func requestAccessibility() {
       let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true]
       AXIsProcessTrustedWithOptions(options as CFDictionary)
   }
   
   func requestScreenRecording() {
       CGRequestScreenCaptureAccess()
   }
   ```
4. Create simple `PermissionStatusView.swift` (SwiftUI) showing current status
5. Add to app as debug/onboarding view

**Acceptance Criteria**:
- [x] App correctly reports Accessibility permission status
- [x] App correctly reports Screen Recording permission status
- [x] Requesting permission opens System Settings
- [x] Status updates after user grants permission

**Verification**:
1. Run app without permissions → shows "Not Granted"
2. Click "Request" → System Settings opens
3. Grant permission → status updates to "Granted"

---

### Task 1.6: Delete Legacy Code & Cleanup ✅

| Attribute | Value |
|-----------|-------|
| **Priority** | P2 |
| **Risk** | LOW |
| **Complexity** | Quick (<1h) |
| **Dependencies** | Tasks 1.1-1.5 complete and verified |
| **Blocks** | None |

**Description**:
Remove legacy AppKit code once SwiftUI foundation is stable.

**Files to Delete**:
- `hidden/AppDelegate.swift` (replaced by DrawerApp)
- `hidden/Base.lproj/Main.storyboard`
- `hidden/Features/Preferences/PreferencesWindowController.swift`
- `hidden/Features/Preferences/PreferencesViewController.swift`
- `hidden/Features/About/AboutViewController.swift`
- `hidden/Common/Preferences.swift` (replaced by SettingsManager)
- `LauncherApplication/` (entire target)

**Files to Keep & Refactor**:
- `hidden/EventMonitor.swift` → Move to `Utilities/`
- `hidden/Common/Assets.swift` → Move to `Utilities/`
- `hidden/Extensions/*` → Move to `Utilities/Extensions/`

**Acceptance Criteria**:
- [x] No storyboard files remain (removed from build)
- [x] No legacy AppDelegate (DrawerApp.swift is entry point)
- [x] App still compiles and runs (BUILD SUCCEEDED)
- [x] All functionality from Tasks 1.1-1.5 still works

**Completed Actions**:
- Renamed Xcode target from "Hidden Bar" to "Drawer"
- Renamed scheme from "Hidden Bar.xcscheme" to "Drawer.xcscheme"
- Removed Main.storyboard from Resources build phase
- Removed LauncherApplication.app from Copy Files build phase
- Updated bundle identifier to `com.drawer.app`
- Updated product name to "Drawer"
- Updated version to 1.0 (build 1)
- Updated copyright to "Drawer"

---

## Phase 2: The Drawer Engine

**Goal**: Implement the floating Drawer panel with captured icon images and click-through interaction.

**Estimated Total**: 8-12 hours

**Prerequisites**: Phase 1 complete and stable

---

### Task 2.1: DrawerPanel (NSPanel Window) ✅

| Attribute | Value |
|-----------|-------|
| **Priority** | P0 - BLOCKER |
| **Risk** | MEDIUM |
| **Complexity** | Medium (2-3h) |
| **Dependencies** | Phase 1 complete |
| **Blocks** | Tasks 2.3, 2.4, 2.5 |

**Description**:
Create the floating NSPanel that hosts the Drawer UI. This must be non-activating (doesn't steal focus) and positioned precisely below the menu bar.

**Panel Configuration**:
```swift
class DrawerPanel: NSPanel {
    init() {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        self.level = .statusBar
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
    }
}
```

**Steps**:
1. Create `UI/Panels/DrawerPanel.swift` (NSPanel subclass)
2. Configure window flags for floating, non-activating behavior
3. Implement `position(relativeTo screen: NSScreen)` for menu bar alignment
4. Create `DrawerPanelController.swift` to manage show/hide
5. Create placeholder `DrawerContentView.swift` (SwiftUI)
6. Host SwiftUI view in panel via `NSHostingView`
7. Wire to `MenuBarManager.toggle()` for testing

**Acceptance Criteria**:
- [x] Panel appears below menu bar when triggered
- [x] Panel doesn't steal focus from other apps
- [x] Panel appears on all Spaces
- [x] Panel has no title bar or window chrome
- [x] Panel has shadow

**Completed Implementation**:
- `Drawer/UI/Panels/DrawerPanel.swift`: NSPanel subclass with `.borderless`, `.nonactivatingPanel`, `.fullSizeContentView` style masks
- `Drawer/UI/Panels/DrawerPanelController.swift`: Manages panel lifecycle, hosts SwiftUI via NSHostingView
- `Drawer/UI/Panels/DrawerContentView.swift`: Placeholder SwiftUI view with mock icons
- `Drawer/App/AppState.swift`: Updated with `drawerController` and drawer toggle methods
- `Drawer/Core/Managers/MenuBarManager.swift`: Added "Show Drawer" context menu item with callback

**Verification**:
1. Right-click separator → "Show Drawer" menu item
2. Click "Show Drawer" → panel appears below menu bar
3. Panel uses HUD material background with rounded corners

---

### Task 2.2: IconCapturer (ScreenCaptureKit) ✅

| Attribute | Value |
|-----------|-------|
| **Priority** | P0 - BLOCKER |
| **Risk** | HIGH ⚠️ |
| **Complexity** | Large (3-4h) |
| **Dependencies** | Task 1.5 (PermissionManager), Task 2.1 |
| **Blocks** | Task 2.3 |

**Description**:
Capture the visual state of hidden menu bar icons using ScreenCaptureKit. This is the most technically challenging task.

**⚠️ Risk Factors**:
- Requires Screen Recording permission
- Menu bar window identification is fragile
- Timing-sensitive (must capture after render)
- May need fallback to CGWindowListCreateImage

**Capture Strategy**:
1. Temporarily expand menu bar (separator = 20)
2. Wait for render (1-2 frames, ~33ms)
3. Capture menu bar region via SCScreenshotManager
4. Collapse menu bar (separator = 10000)
5. Slice image into individual icons

**Steps**:
1. Create `Core/Engines/IconCapturer.swift`
2. Implement `SCShareableContent` query to find menu bar
3. Implement capture sequence with proper timing
4. Add image slicing logic (standard icon width = 22pt, spacing = 4pt)
5. Return `[CapturedIcon]` with image + position data
6. Add fallback to `CGWindowListCreateImage` if SCK fails

**Code Pattern**:
```swift
func captureHiddenIcons() async throws -> [CapturedIcon] {
    // 1. Expand menu bar
    await menuBarManager.expand()
    
    // 2. Wait for render
    try await Task.sleep(nanoseconds: 33_000_000) // ~1 frame
    
    // 3. Capture
    let content = try await SCShareableContent.current
    guard let menuBarWindow = content.windows.first(where: { 
        $0.owningApplication?.bundleIdentifier == "com.apple.systemuiserver" 
    }) else { throw CaptureError.menuBarNotFound }
    
    let image = try await SCScreenshotManager.captureImage(
        contentFilter: SCContentFilter(desktopIndependentWindow: menuBarWindow),
        configuration: SCStreamConfiguration()
    )
    
    // 4. Collapse
    await menuBarManager.collapse()
    
    // 5. Slice and return
    return sliceIcons(from: image)
}
```

**Acceptance Criteria**:
- [x] Captures menu bar image when triggered
- [x] Slices into individual icon images
- [x] Works with Screen Recording permission granted
- [x] Graceful error when permission denied
- [x] Capture is fast enough to not be noticeable (<100ms)

**Verification**:
1. Grant Screen Recording permission
2. Trigger capture
3. Verify captured image shows hidden icons
4. Verify individual icons are correctly sliced

**Test Cases**:
```swift
func testCaptureRequiresPermission() async {
    // Mock permission denied
    let capturer = IconCapturer(permissionManager: mockDenied)
    do {
        _ = try await capturer.captureHiddenIcons()
        XCTFail("Should throw")
    } catch {
        XCTAssertEqual(error as? CaptureError, .permissionDenied)
    }
}
```

---

### Task 2.3: DrawerItem Model & Rendering ✅

| Attribute | Value |
|-----------|-------|
| **Priority** | P1 |
| **Risk** | LOW |
| **Complexity** | Short (1-2h) |
| **Dependencies** | Task 2.1, Task 2.2 |
| **Blocks** | Task 2.4 |

**Description**:
Define the data model for drawer items and render them in the DrawerContentView.

**Steps**:
1. Create `Models/DrawerItem.swift`:
   ```swift
   struct DrawerItem: Identifiable {
       let id: UUID
       let image: CGImage
       let originalFrame: CGRect // Position in real menu bar
       let capturedAt: Date
   }
   ```
2. Create `Core/Managers/DrawerManager.swift` (ObservableObject)
3. Implement `@Published var items: [DrawerItem]`
4. Update `DrawerContentView.swift` to render items in HStack
5. Style to match reference image (specs/reference_images/icon-drawer.jpg)

**Visual Requirements** (from reference):
- Pill-shaped container
- High corner radius (10-12pt)
- HUD material background
- 0.5pt rim light (white @ 20% opacity)
- Consistent icon spacing (4pt)

**Acceptance Criteria**:
- [x] DrawerItem model captures all needed data
- [x] DrawerContentView renders items horizontally
- [x] Styling matches reference image
- [x] Empty state handled gracefully

**Completed Implementation**:
- `Drawer/Models/DrawerItem.swift`: Model struct wrapping CapturedIcon with id, image, originalFrame, capturedAt, index
- `Drawer/Core/Managers/DrawerManager.swift`: ObservableObject managing drawer state with items, isVisible, isLoading, lastError
- `Drawer/UI/Panels/DrawerContentView.swift`: Complete rewrite with DrawerDesign constants (10pt icon spacing, 16pt horizontal padding, 7pt vertical padding, 11pt corner radius)
- `Drawer/UI/Panels/DrawerPanelController.swift`: Added DrawerContainerView with rim light (1pt white @ 17.5% opacity gradient) and shadow (12pt radius, 3pt Y offset)
- `Drawer/App/AppState.swift`: Integrated DrawerManager with capture flow

---

### Task 2.4: Click-Through Interaction (CGEvent) ✅

| Attribute | Value |
|-----------|-------|
| **Priority** | P0 - BLOCKER |
| **Risk** | HIGH ⚠️ |
| **Complexity** | Medium (2-3h) |
| **Dependencies** | Task 1.5 (Accessibility), Task 2.3 |
| **Blocks** | None |

**Description**:
Make drawer icons interactive by simulating clicks on the real menu bar items.

**⚠️ Risk Factors**:
- Requires Accessibility permission
- CGEvent posting can be blocked by security software
- Coordinate mapping must be precise
- May interfere with other accessibility tools

**Interaction Flow**:
1. User clicks icon in Drawer
2. Hide Drawer immediately
3. Expand real menu bar
4. Calculate real icon position
5. Move mouse cursor to position
6. Post CGEvent mouseDown + mouseUp
7. (Optional) Restore state after menu closes

**Completed Implementation**:
- `Drawer/Utilities/EventSimulator.swift`: CGEvent-based mouse simulation with permission checks
- `Drawer/App/AppState.swift`: Updated `handleItemTap()` and `performClickThrough()` methods
- Flow: Hide drawer → Wait 50ms → Expand menu bar → Wait 100ms → Simulate click at original icon position

**Acceptance Criteria**:
- [x] Clicking drawer icon opens real app's menu
- [x] Works with Accessibility permission granted
- [x] Graceful error when permission denied
- [x] Click position is accurate (within 2pt)

**Verification**:
1. Hide some icons (e.g., Dropbox, 1Password)
2. Open Drawer
3. Click on Dropbox icon in Drawer
4. Verify Dropbox menu opens

---

### Task 2.5: Hover & Auto-Show (EventMonitor) ✅

| Attribute | Value |
|-----------|-------|
| **Priority** | P2 |
| **Risk** | LOW |
| **Complexity** | Short (1-2h) |
| **Dependencies** | Task 2.1 |
| **Blocks** | None |

**Description**:
Show the Drawer when mouse enters the menu bar area (optional feature).

**Steps**:
1. Refactor `EventMonitor.swift` → `Utilities/GlobalEventMonitor.swift`
2. Create `Core/Managers/HoverManager.swift`
3. Track mouse position via global event monitor
4. Define trigger zone (top 24pt of screen = menu bar height)
5. Implement debounce to prevent flicker
6. Add setting to enable/disable hover trigger
7. Implement auto-hide when mouse leaves Drawer area

**Acceptance Criteria**:
- [x] Moving mouse to top of screen shows Drawer (when enabled)
- [x] Moving mouse away hides Drawer
- [x] No flicker on rapid mouse movement (150ms show debounce, 300ms hide debounce)
- [x] Feature can be disabled in settings (`showOnHover` in SettingsManager)

**Completed Implementation**:
- `Drawer/Utilities/GlobalEventMonitor.swift`: Refactored from legacy EventMonitor with both global and local monitor classes
- `Drawer/Core/Managers/HoverManager.swift`: ObservableObject managing mouse tracking with:
  - Trigger zone detection (top 24pt of screen)
  - Show debounce (150ms) and hide debounce (300ms) to prevent flicker
  - Auto-hide when mouse leaves drawer area (with 10pt padding)
  - Callbacks for show/hide events
- `Drawer/App/AppState.swift`: Integrated HoverManager with settings binding
- `Drawer/Core/Managers/SettingsManager.swift`: Added `showOnHoverSubject` publisher

---

## Phase 3: UI/UX Polish

**Goal**: Transform functional prototype into beautiful, release-ready product.

**Estimated Total**: 6-8 hours

**Prerequisites**: Phase 2 complete and stable

---

### Task 3.1: Visual Materials (NSVisualEffectView) ✅

| Attribute | Value |
|-----------|-------|
| **Priority** | P1 |
| **Risk** | LOW |
| **Complexity** | Short (1-2h) |
| **Dependencies** | Task 2.1 |
| **Blocks** | None |

**Description**:
Apply native macOS materials to the Drawer for a polished look.

**Steps**:
1. Create `UI/Components/VisualEffectView.swift` (NSViewRepresentable)
2. Configure material: `.menu` or `.hudWindow`
3. Wrap DrawerContentView in VisualEffectView
4. Add 0.5pt inner border (white @ 20% opacity)
5. Add shadow (radius: 8, opacity: 0.3)
6. Ensure rounded corners at bottom (10-12pt radius)

**Visual Reference**: Check `specs/reference_images/icon-drawer.jpg`

**Acceptance Criteria**:
- [x] Drawer has frosted glass appearance
- [x] Background content bleeds through elegantly
- [x] Works in both Light and Dark mode
- [x] Matches native macOS menu styling

**Completed Implementation**:
- `Drawer/UI/Panels/DrawerPanelController.swift`: Contains `DrawerBackgroundView` (NSViewRepresentable) with:
  - `NSVisualEffectView` using `.hudWindow` material
  - `.blendingMode = .behindWindow` for proper transparency
  - `.state = .active` for consistent vibrancy
  - Corner radius applied via layer
- `DrawerContainerView`: Applies rim light (1pt gradient stroke @ 17.5% opacity) and shadow (12pt radius, 3pt Y offset, 30% opacity)
- Design constants in `DrawerDesign` enum for consistency

---

### Task 3.2: Animations ✅

| Attribute | Value |
|-----------|-------|
| **Priority** | P1 |
| **Risk** | LOW |
| **Complexity** | Short (1h) |
| **Dependencies** | Task 3.1 |
| **Blocks** | None |

**Description**:
Add smooth, spring-based animations for Drawer show/hide.

**Steps**:
1. Implement slide-down animation for show:
   ```swift
   .transition(.move(edge: .top).combined(with: .opacity))
   .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isVisible)
   ```
2. Implement fade-out for hide
3. Ensure no flicker during capture sequence
4. Add subtle scale animation on icon hover

**Acceptance Criteria**:
- [x] Drawer slides in smoothly from top
- [x] Drawer fades out when hiding
- [x] No visual glitches during capture
- [x] Animations feel "tactile" (spring physics)

**Completed Implementation**:
- `Drawer/UI/Panels/DrawerPanelController.swift`: Added `DrawerAnimation` constants and animation methods:
  - `animateShow()`: Slide-down (12pt) + fade-in with custom spring-like bezier timing (0.25s)
  - `animateHide()`: Fade-out + slight upward movement with ease-in timing (0.15s)
  - Animation guard (`isAnimating`) prevents overlapping animations
- `Drawer/UI/Panels/DrawerContentView.swift`: Icon hover animation with `.spring(response: 0.2, dampingFraction: 0.6)` and 1.1x scale effect
- Capture sequence shows drawer only after content is ready (no loading flicker)

---

### Task 3.3: Settings UI (SwiftUI) ✅

| Attribute | Value |
|-----------|-------|
| **Priority** | P1 |
| **Risk** | LOW |
| **Complexity** | Medium (2-3h) |
| **Dependencies** | Task 1.3 |
| **Blocks** | None |

**Description**:
Create a comprehensive Settings window using SwiftUI.

**Visual Reference**: Check `specs/reference_images/settings-layout.jpg`

**Tabs**:
1. **General**
   - Launch at Login toggle
   - Auto-collapse toggle + delay slider
   - Show on Hover toggle
   - Global hotkey recorder

2. **Appearance**
   - Drawer position (below menu bar / replace menu bar)
   - Icon spacing slider
   - Show separator icons toggle

3. **About**
   - App icon + version
   - Credits / acknowledgments
   - Links (GitHub, support)

**Steps**:
1. Create `UI/Settings/SettingsView.swift` with TabView
2. Create `UI/Settings/GeneralSettingsView.swift`
3. Create `UI/Settings/AppearanceSettingsView.swift`
4. Create `UI/Settings/AboutView.swift`
5. Use `Settings` scene (macOS 13+) for native integration
6. Style with platter-based grouping (Form + Section)

**Acceptance Criteria**:
- [x] Settings window opens from menu bar context menu
- [x] All settings persist and take effect immediately
- [x] UI matches macOS native settings style
- [x] Keyboard shortcut (⌘,) opens settings

**Implementation Notes** (2026-01-14):
- Created `UI/Settings/SettingsView.swift` with TabView (General, Appearance, About)
- Created `UI/Settings/GeneralSettingsView.swift` with Launch at Login, Auto-collapse, Show on Hover, Global Hotkey
- Created `UI/Settings/AppearanceSettingsView.swift` with Hide separators, Always-hidden section, Full menu bar width
- Created `UI/Settings/AboutView.swift` with app icon, version, credits, GitHub link
- Uses SwiftUI `Settings` scene for native ⌘, integration
- All settings bound to `SettingsManager.shared` for immediate persistence

---

### Task 3.4: Onboarding & Icon Arrangement

| Attribute | Value |
|-----------|-------|
| **Priority** | P2 |
| **Risk** | LOW |
| **Complexity** | Short (1-2h) |
| **Dependencies** | Task 1.5 |
| **Blocks** | None |

**Description**:
Create first-launch onboarding explaining how to use the app.

**Onboarding Steps**:
1. Welcome screen with app overview
2. Permission request (Accessibility + Screen Recording)
3. Tutorial: "Hold ⌘ and drag icons to arrange"
4. Completion with "Get Started" button

**Steps**:
1. Create `UI/Onboarding/OnboardingView.swift`
2. Create step views with illustrations
3. Integrate with PermissionManager for permission flow
4. Store `hasCompletedOnboarding` in SettingsManager
5. Show on first launch only

**Acceptance Criteria**:
- [ ] Onboarding shows on first launch
- [ ] Permissions are requested with clear explanation
- [ ] User understands ⌘+drag arrangement
- [ ] Onboarding can be skipped

---

### Task 3.5: Final Polish & Release Prep

| Attribute | Value |
|-----------|-------|
| **Priority** | P2 |
| **Risk** | LOW |
| **Complexity** | Medium (2-3h) |
| **Dependencies** | All previous tasks |
| **Blocks** | None |

**Description**:
Final polish for release readiness.

**Steps**:
1. Design and add AppIcon (1024x1024 + all sizes)
2. Update app name: "Hidden Bar" → "Drawer"
3. Update bundle identifier
4. Remove all debug logging
5. Verify Dark Mode / Light Mode in all views
6. Test on multiple screen sizes
7. Enable Hardened Runtime
8. Configure code signing for notarization
9. Create DMG for distribution

**Acceptance Criteria**:
- [ ] Professional app icon
- [ ] No debug output in console
- [ ] Works in Light and Dark mode
- [ ] Passes notarization
- [ ] Clean DMG installer

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| ScreenCaptureKit fails to find menu bar | Medium | High | Fallback to CGWindowListCreateImage |
| CGEvent blocked by security software | Low | High | Document in FAQ, provide manual workaround |
| Menu bar icon positions change between capture and click | Medium | Medium | Recapture on each Drawer open |
| Performance issues with frequent captures | Low | Medium | Cache captures, only refresh on change |
| RTL language layout issues | Low | Low | Test with Arabic/Hebrew, use existing RTL logic |

---

## Testing Strategy

### Unit Tests (Required)
- `MenuBarManagerTests.swift` - Toggle logic, debounce, state
- `SettingsManagerTests.swift` - Persistence, defaults
- `PermissionManagerTests.swift` - Status checking (mock TCC)
- `DrawerItemTests.swift` - Model validation

### Integration Tests (Recommended)
- Full toggle cycle (expand → capture → display → click → collapse)
- Settings changes reflect in behavior
- Permission flow (denied → granted → functional)

### Manual Verification Checklist
- [ ] Fresh install experience
- [ ] Upgrade from Hidden Bar (if supporting migration)
- [ ] Multiple monitors
- [ ] Spaces / Mission Control
- [ ] Full Screen apps
- [ ] Menu bar with many icons (20+)
- [ ] Menu bar with few icons (3-5)
- [ ] Light Mode
- [ ] Dark Mode
- [ ] RTL language (Arabic)

---

## Appendix: File Mapping (Legacy → New)

| Legacy File | New Location | Notes |
|-------------|--------------|-------|
| `AppDelegate.swift` | `App/DrawerApp.swift` | Complete rewrite |
| `StatusBarController.swift` | `Core/Managers/MenuBarManager.swift` | Port logic only |
| `Preferences.swift` | `Core/Managers/SettingsManager.swift` | Use @AppStorage |
| `EventMonitor.swift` | `Utilities/GlobalEventMonitor.swift` | Minor refactor |
| `Util.swift` | Split into specific utilities | Delete after migration |
| `PreferencesViewController.swift` | `UI/Settings/SettingsView.swift` | SwiftUI rewrite |
| `AboutViewController.swift` | `UI/Settings/AboutView.swift` | SwiftUI rewrite |
| `LauncherApplication/*` | DELETE | Use SMAppService |
| `Main.storyboard` | DELETE | No storyboards |

---

## Appendix: Source Files Inventory

### Legacy Files (hidden/)
| File | Purpose | Action |
|------|---------|--------|
| `AppDelegate.swift` | App entry, hotkey setup | REPLACE with DrawerApp.swift |
| `EventMonitor.swift` | Global mouse event tracking | REFACTOR to Utilities/ |
| `Common/Util.swift` | Auto-start, window helpers | SPLIT into specific utilities |
| `Common/Preferences.swift` | UserDefaults wrapper | REPLACE with SettingsManager |
| `Common/Assets.swift` | Image assets | KEEP, move to Utilities/ |
| `Common/Constant.swift` | App constants, bundle IDs | UPDATE bundle IDs |
| `Extensions/*.swift` | Various extensions | KEEP, move to Utilities/Extensions/ |
| `Models/SelectedSecond.swift` | Auto-hide delay options | REPLACE with enum in SettingsManager |
| `Models/GlobalKeybindingPreferences.swift` | Hotkey data model | KEEP, move to Models/ |
| `Features/StatusBar/StatusBarController.swift` | Core 10k pixel hack | PORT to MenuBarManager |
| `Features/Preferences/*.swift` | Settings UI (AppKit) | REPLACE with SwiftUI |
| `Features/About/AboutViewController.swift` | About screen (AppKit) | REPLACE with SwiftUI |
| `Views/*.swift` | Custom AppKit views | DELETE (not needed) |

### LauncherApplication Files
| File | Purpose | Action |
|------|---------|--------|
| `AppDelegate.swift` | Launch main app at login | DELETE (use SMAppService) |
| `ViewController.swift` | Unused boilerplate | DELETE |
| `Info.plist` | Helper app config | DELETE |
| Entire target | Login item helper | REMOVE from project |

---

## Appendix: Key Code Patterns to Preserve

### The "10k Pixel Hack" (from StatusBarController.swift)
```swift
// The core hiding mechanism - DO NOT CHANGE THIS LOGIC
private let btnHiddenCollapseLength: CGFloat = 10000

private func collapseMenuBar() {
    btnSeparate.length = self.btnHiddenCollapseLength  // Hide icons
}

private func expandMenubar() {
    btnSeparate.length = btnHiddenLength  // Show icons (20pt)
}
```

### RTL Language Support (from StatusBarController.swift)
```swift
// Must preserve for Arabic, Hebrew, etc.
private var isBtnSeparateValidPosition: Bool {
    if Constant.isUsingLTRLanguage {
        return btnExpandCollapseX >= btnSeparateX
    } else {
        return btnExpandCollapseX <= btnSeparateX
    }
}
```

### Position Persistence
```swift
// Preserves icon positions across restarts
btnExpandCollapse.autosaveName = "hiddenbar_expandcollapse"
btnSeparate.autosaveName = "hiddenbar_separate"
```

### Debounce Protection
```swift
// Prevents rapid click issues
private var isToggle = false

func expandCollapseIfNeeded() {
    if isToggle { return }
    isToggle = true
    // ... toggle logic ...
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        self.isToggle = false
    }
}
```
