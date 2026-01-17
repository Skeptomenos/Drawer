# Spec: Phase 4B - Overlay Mode Integration

**Phase:** 4B
**Priority:** Low (P3 - Future)
**Estimated Time:** 35-45 minutes
**Dependencies:** Phase 4A (Overlay Infrastructure)
**Parent Doc:** `docs/IMPLEMENTATION_PLAN_ARCHITECTURE_IMPROVEMENTS.md`

---

## Objective

Integrate the Overlay Panel infrastructure with the app's toggle flow, IconCapturer, and EventSimulator to provide a complete "Overlay Mode" experience as an alternative to the traditional expand mode.

---

## Background

### Phase 4A Created
- `OverlayPanel` - NSPanel at menu bar level
- `OverlayPanelController` - Panel lifecycle
- `OverlayContentView` - Horizontal icon strip
- `overlayModeEnabled` setting

### This Phase Adds
- `OverlayModeManager` - Orchestrates the full flow
- Modified toggle behavior when overlay mode is enabled
- Capture-while-collapsed logic for IconCapturer
- Settings UI for overlay mode
- Auto-hide behavior for overlay panel

---

## User Experience

### Traditional Mode (Expand)
```
1. User clicks toggle
2. Separator shrinks to 20px
3. Hidden icons slide into view in menu bar
4. User clicks icon directly in menu bar
5. Auto-collapse timer starts
```

### Overlay Mode (New)
```
1. User clicks toggle
2. Separator stays at 10k (icons remain hidden)
3. Capture hidden icon windows
4. Overlay panel appears at menu bar level
5. User clicks icon in overlay
6. EventSimulator sends click to hidden icon
7. Overlay dismisses
```

---

## Implementation

### File 1: `Drawer/Core/Managers/OverlayModeManager.swift`

```swift
//
//  OverlayModeManager.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import Combine
import os.log

/// Manages the Overlay Mode flow - capturing hidden icons and displaying them
/// in a floating panel at menu bar level without expanding the menu bar.
@MainActor
final class OverlayModeManager: ObservableObject {
    
    // MARK: - Published State
    
    @Published private(set) var isOverlayVisible: Bool = false
    @Published private(set) var isCapturing: Bool = false
    @Published private(set) var capturedItems: [DrawerItem] = []
    
    // MARK: - Dependencies
    
    private let settings: SettingsManager
    private let iconCapturer: IconCapturer
    private let eventSimulator: EventSimulator
    private let overlayController: OverlayPanelController
    private let menuBarManager: MenuBarManager
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.drawer", category: "OverlayModeManager")
    private var cancellables = Set<AnyCancellable>()
    private var autoHideTask: Task<Void, Never>?
    
    // MARK: - Configuration
    
    private let autoHideDelay: TimeInterval = 5.0
    
    // MARK: - Initialization
    
    init(
        settings: SettingsManager,
        iconCapturer: IconCapturer,
        eventSimulator: EventSimulator,
        menuBarManager: MenuBarManager,
        overlayController: OverlayPanelController = OverlayPanelController()
    ) {
        self.settings = settings
        self.iconCapturer = iconCapturer
        self.eventSimulator = eventSimulator
        self.menuBarManager = menuBarManager
        self.overlayController = overlayController
        
        setupBindings()
    }
    
    private func setupBindings() {
        overlayController.$isVisible
            .assign(to: &$isOverlayVisible)
    }
    
    // MARK: - Public API
    
    /// Whether overlay mode is currently enabled in settings
    var isOverlayModeEnabled: Bool {
        settings.overlayModeEnabled
    }
    
    /// Toggles the overlay panel visibility
    func toggleOverlay() async {
        if isOverlayVisible {
            hideOverlay()
        } else {
            await showOverlay()
        }
    }
    
    /// Shows the overlay panel with captured hidden icons
    func showOverlay() async {
        guard !isCapturing else { return }
        
        isCapturing = true
        logger.debug("Starting overlay capture...")
        
        do {
            // Capture icons while menu bar is collapsed
            let result = try await captureHiddenIconsForOverlay()
            
            let items = result.icons.enumerated().map { index, icon in
                DrawerItem(
                    id: icon.id,
                    image: icon.image,
                    originalFrame: icon.originalFrame,
                    capturedAt: icon.capturedAt,
                    index: index,
                    sectionType: .hidden
                )
            }
            
            capturedItems = items
            isCapturing = false
            
            guard !items.isEmpty else {
                logger.debug("No hidden icons to display")
                return
            }
            
            // Calculate position (right edge of separator)
            let xPosition = calculateOverlayPosition()
            
            overlayController.show(
                items: items,
                alignedTo: xPosition,
                onItemTap: { [weak self] item in
                    Task {
                        await self?.handleOverlayItemTap(item)
                    }
                }
            )
            
            startAutoHideTimer()
            logger.debug("Overlay shown with \(items.count) icons")
            
        } catch {
            isCapturing = false
            logger.error("Overlay capture failed: \(error.localizedDescription)")
        }
    }
    
    /// Hides the overlay panel
    func hideOverlay() {
        cancelAutoHideTimer()
        overlayController.hide()
        logger.debug("Overlay hidden")
    }
    
    // MARK: - Private Methods
    
    /// Captures hidden icons without expanding the menu bar
    private func captureHiddenIconsForOverlay() async throws -> MenuBarCaptureResult {
        // The key difference from normal capture:
        // We DON'T expand the menu bar first
        // Icons are captured in their "hidden" position (pushed off-screen)
        
        // Temporarily expand just long enough to capture
        let wasCollapsed = menuBarManager.isCollapsed
        
        if wasCollapsed {
            menuBarManager.expand()
            // Brief delay for icons to settle
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        
        let result = try await iconCapturer.captureHiddenIcons(menuBarManager: menuBarManager)
        
        // Immediately collapse back
        if wasCollapsed {
            menuBarManager.collapse()
        }
        
        return result
    }
    
    /// Calculates X position for overlay panel
    private func calculateOverlayPosition() -> CGFloat {
        // Position at the separator's right edge
        if let separatorWindow = menuBarManager.separatorControlItem.button?.window {
            return separatorWindow.frame.maxX + 4
        }
        
        // Fallback: center of main screen
        return (NSScreen.main?.frame.width ?? 1000) / 2 - 100
    }
    
    /// Handles tap on an icon in the overlay
    private func handleOverlayItemTap(_ item: DrawerItem) async {
        logger.info("Overlay item tapped at index \(item.index)")
        
        // Hide overlay first
        hideOverlay()
        
        // Brief delay
        try? await Task.sleep(nanoseconds: 50_000_000)
        
        // Expand menu bar to reveal the real icon
        menuBarManager.expand()
        
        // Wait for icons to settle
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Simulate click on the real icon
        do {
            try await eventSimulator.simulateClick(at: item.clickTarget)
            logger.info("Click-through completed")
        } catch {
            logger.error("Click-through failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Auto-Hide Timer
    
    private func startAutoHideTimer() {
        cancelAutoHideTimer()
        
        autoHideTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(self?.autoHideDelay ?? 5.0))
            guard !Task.isCancelled else { return }
            await self?.hideOverlay()
        }
    }
    
    private func cancelAutoHideTimer() {
        autoHideTask?.cancel()
        autoHideTask = nil
    }
    
    // MARK: - Cleanup
    
    deinit {
        autoHideTask?.cancel()
        cancellables.removeAll()
    }
}
```

### File 2: Modify AppState for Overlay Mode

**File:** `Drawer/App/AppState.swift`

Add overlay mode support:

```swift
// Add property
let overlayModeManager: OverlayModeManager

// In init(), after creating other managers:
self.overlayModeManager = OverlayModeManager(
    settings: settings,
    iconCapturer: iconCapturer,
    eventSimulator: eventSimulator,
    menuBarManager: menuBarManager
)

// Modify toggleMenuBar() to check overlay mode:
func toggleMenuBar() {
    if settings.overlayModeEnabled {
        Task {
            await overlayModeManager.toggleOverlay()
        }
    } else {
        menuBarManager.toggle()
    }
}
```

### File 3: Add Settings UI

**File:** `Drawer/UI/Settings/GeneralSettingsView.swift`

Add overlay mode toggle:

```swift
Section("Display Mode") {
    Picker("When clicking toggle:", selection: $settings.overlayModeEnabled) {
        Text("Expand menu bar").tag(false)
        Text("Show overlay panel").tag(true)
    }
    .pickerStyle(.radioGroup)
    
    if settings.overlayModeEnabled {
        Text("Hidden icons will appear in a floating panel instead of expanding the menu bar. This works better on MacBooks with a notch.")
            .font(.caption)
            .foregroundColor(.secondary)
    }
}
```

### File 4: Modify MenuBarManager Toggle Action

**File:** `Drawer/Core/Managers/MenuBarManager.swift`

The toggle button should notify AppState, not toggle directly:

```swift
// Add callback for external toggle handling
var onTogglePressed: (() -> Void)?

@objc private func toggleButtonPressed(_ sender: NSStatusBarButton) {
    logger.debug("Toggle Button Pressed")
    guard let event = NSApp.currentEvent else { return }
    
    let isOptionKeyPressed = event.modifierFlags.contains(.option)
    
    if event.type == .leftMouseUp && !isOptionKeyPressed {
        // Delegate to AppState which decides expand vs overlay
        onTogglePressed?()
    }
}
```

Then in `AppState.init()`:

```swift
menuBarManager.onTogglePressed = { [weak self] in
    self?.toggleMenuBar()
}
```

---

## Acceptance Criteria

- [ ] `OverlayModeManager` created and functional
- [ ] Toggle respects `overlayModeEnabled` setting
- [ ] Overlay captures icons without visible expand/collapse
- [ ] Overlay panel appears at menu bar level
- [ ] Click-through works from overlay to real icons
- [ ] Auto-hide timer dismisses overlay after delay
- [ ] Settings UI allows switching between modes
- [ ] Build succeeds with no warnings
- [ ] Works on notched MacBooks

---

## Testing

### Manual Verification Steps

1. Build and run app
2. Open Preferences → General
3. Select "Show overlay panel" mode
4. Click toggle in menu bar
5. Verify overlay appears (not menu bar expand)
6. Verify icons are displayed horizontally
7. Click an icon in overlay
8. Verify:
   - Overlay dismisses
   - Menu bar briefly expands
   - Click is sent to real icon
   - Menu bar collapses
9. Wait 5 seconds with overlay open
10. Verify auto-hide triggers
11. Switch back to "Expand menu bar" mode
12. Verify traditional behavior works

### Notch Testing

1. Test on MacBook with notch
2. Crowd menu bar with many icons
3. Verify overlay mode works regardless of notch
4. Verify icons don't get stuck behind notch

### Edge Cases

- Rapid toggle clicks
- Overlay visible when screen changes
- Multiple displays
- Click-through while icon has open menu

---

## Flow Diagram

```
User clicks toggle
        │
        ▼
┌───────────────────┐
│ overlayModeEnabled?│
└───────┬───────────┘
        │
   ┌────┴────┐
   │         │
  Yes       No
   │         │
   ▼         ▼
┌──────┐  ┌───────────┐
│Overlay│  │Traditional│
│ Flow │  │   Flow    │
└──┬───┘  └─────┬─────┘
   │            │
   ▼            ▼
Capture      Expand
 icons      separator
   │            │
   ▼            │
 Show           │
overlay         │
   │            │
   ▼            ▼
User          User
clicks        clicks
icon          icon
   │          directly
   ▼            │
Hide            │
overlay         │
   │            │
   ▼            ▼
Expand      Auto-collapse
briefly      timer
   │            │
   ▼            ▼
Click        Done
through
   │
   ▼
Collapse
   │
   ▼
 Done
```

---

## Files Changed

| File | Action |
|------|--------|
| `Drawer/Core/Managers/OverlayModeManager.swift` | Create |
| `Drawer/App/AppState.swift` | Add overlay manager, modify toggle |
| `Drawer/Core/Managers/MenuBarManager.swift` | Add toggle callback |
| `Drawer/UI/Settings/GeneralSettingsView.swift` | Add display mode picker |

---

## Future Enhancements

After Phase 4B is complete, consider:

1. **Real-time capture**: Update overlay icons in real-time as apps update their status items
2. **Hover to show**: Show overlay on hover instead of click
3. **Persist overlay**: Keep overlay open until explicitly dismissed
4. **Custom overlay position**: Let users position the overlay panel
5. **Icon reordering**: Allow drag-and-drop in overlay to reorder icons
