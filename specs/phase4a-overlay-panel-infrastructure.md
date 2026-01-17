# Spec: Phase 4A - Overlay Panel Infrastructure

**Phase:** 4A
**Priority:** Low (P3 - Future)
**Estimated Time:** 30-40 minutes
**Dependencies:** Phase 2B (Section Architecture), Phase 3 (Always Hidden)
**Parent Doc:** `docs/IMPLEMENTATION_PLAN_ARCHITECTURE_IMPROVEMENTS.md`

---

## Objective

Create the infrastructure for "Overlay Mode" - an alternative display mode where hidden icons are rendered in a floating NSPanel at menu bar level, rather than being shown in the native menu bar. This solves the MacBook Notch problem definitively.

---

## Background

### The Notch Problem
The 10k pixel hack pushes icons off-screen to the left. On notched MacBooks:
- Icons can get stuck behind the notch
- Space is limited on the right side
- The hack is unreliable in crowded menu bars

### The Overlay Solution
Instead of expanding the menu bar:
1. Keep the separator at 10k (icons stay hidden)
2. Capture hidden icon windows via CGWindowList
3. Render them in a floating panel at the menu bar level
4. Forward clicks to the real (hidden) icons

### Existing Infrastructure
Drawer already has:
- `DrawerPanel` - Floating NSPanel
- `DrawerPanelController` - Panel lifecycle management
- `IconCapturer` - CGWindowList window capture
- `EventSimulator` - Click event simulation

This spec extends these to support menu-bar-level overlay rendering.

---

## Architecture

### New Components

```
OverlayMode/
├── OverlayPanel.swift         - NSPanel styled like menu bar
├── OverlayPanelController.swift - Show/hide/position logic
├── OverlayContentView.swift    - SwiftUI view for icons
└── OverlayModeManager.swift    - Coordinates capture + display
```

### Component Responsibilities

| Component | Responsibility |
|-----------|----------------|
| `OverlayPanel` | NSPanel configured to appear at menu bar level |
| `OverlayPanelController` | Positioning, animations, show/hide |
| `OverlayContentView` | Horizontal icon strip with click handling |
| `OverlayModeManager` | Coordinates IconCapturer + Panel + EventSimulator |

---

## Implementation

### File 1: `Drawer/UI/Overlay/OverlayPanel.swift`

```swift
//
//  OverlayPanel.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit

/// A floating panel that renders at menu bar level to display hidden icons.
/// Styled to match the system menu bar appearance.
final class OverlayPanel: NSPanel {
    
    // MARK: - Initialization
    
    init() {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: true
        )
        
        configure()
    }
    
    private func configure() {
        // Panel behavior
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        
        // Don't steal focus
        hidesOnDeactivate = false
        isMovable = false
        isMovableByWindowBackground = false
        
        // Appearance
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        standardWindowButton(.closeButton)?.isHidden = true
        standardWindowButton(.miniaturizeButton)?.isHidden = true
        standardWindowButton(.zoomButton)?.isHidden = true
    }
    
    // MARK: - Overrides
    
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
    
    // MARK: - Positioning
    
    /// Positions the panel at menu bar level, aligned to the right of the separator.
    /// - Parameters:
    ///   - xPosition: X position to align left edge (typically separator's right edge)
    ///   - screen: Screen to display on
    func positionAtMenuBar(alignedTo xPosition: CGFloat, on screen: NSScreen) {
        let menuBarHeight = NSStatusBar.system.thickness
        let panelHeight = menuBarHeight
        let panelWidth = frame.width
        
        // Position just below the menu bar
        let yPosition = screen.frame.maxY - menuBarHeight - panelHeight - 2
        
        let origin = NSPoint(x: xPosition, y: yPosition)
        setFrameOrigin(origin)
    }
}
```

### File 2: `Drawer/UI/Overlay/OverlayContentView.swift`

```swift
//
//  OverlayContentView.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import SwiftUI

/// Horizontal strip of hidden icons, styled like the menu bar.
struct OverlayContentView: View {
    let items: [DrawerItem]
    let onItemTap: ((DrawerItem) -> Void)?
    
    @State private var hoveredItemId: UUID?
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                OverlayIconView(
                    item: item,
                    isHovered: hoveredItemId == item.id,
                    onTap: { onItemTap?(item) }
                )
                .onHover { isHovered in
                    hoveredItemId = isHovered ? item.id : nil
                }
            }
        }
        .padding(.horizontal, 4)
        .frame(height: NSStatusBar.system.thickness)
        .background(OverlayBackground())
    }
}

/// Individual icon in the overlay
struct OverlayIconView: View {
    let item: DrawerItem
    let isHovered: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Image(decorative: item.image, scale: NSScreen.main?.backingScaleFactor ?? 2.0)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 18, height: 18)
        }
        .buttonStyle(OverlayIconButtonStyle(isHovered: isHovered))
        .frame(width: 24, height: 22)
    }
}

/// Button style matching menu bar icon appearance
struct OverlayIconButtonStyle: ButtonStyle {
    let isHovered: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(backgroundColor(configuration: configuration))
            )
    }
    
    private func backgroundColor(configuration: Configuration) -> Color {
        if configuration.isPressed {
            return Color.primary.opacity(0.15)
        } else if isHovered {
            return Color.primary.opacity(0.08)
        }
        return .clear
    }
}

/// Menu bar style background
struct OverlayBackground: View {
    var body: some View {
        VisualEffectView(material: .menu, blendingMode: .behindWindow)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
```

### File 3: `Drawer/UI/Overlay/OverlayPanelController.swift`

```swift
//
//  OverlayPanelController.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import Combine
import SwiftUI
import os.log

/// Manages the overlay panel lifecycle and positioning.
@MainActor
final class OverlayPanelController: ObservableObject {
    
    // MARK: - Published State
    
    @Published private(set) var isVisible: Bool = false
    
    // MARK: - Properties
    
    private var panel: OverlayPanel?
    private var hostingView: NSHostingView<AnyView>?
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.drawer", category: "OverlayPanelController")
    
    // MARK: - Configuration
    
    private let itemWidth: CGFloat = 24
    private let horizontalPadding: CGFloat = 8
    
    // MARK: - Show/Hide
    
    /// Shows the overlay panel with the given items
    /// - Parameters:
    ///   - items: The icons to display
    ///   - xPosition: X position to align the panel
    ///   - screen: Screen to display on (defaults to main)
    ///   - onItemTap: Callback when an icon is tapped
    func show(
        items: [DrawerItem],
        alignedTo xPosition: CGFloat,
        on screen: NSScreen? = nil,
        onItemTap: @escaping (DrawerItem) -> Void
    ) {
        let targetScreen = screen ?? NSScreen.main ?? NSScreen.screens.first!
        
        // Create panel if needed
        if panel == nil {
            panel = OverlayPanel()
        }
        
        guard let panel = panel else { return }
        
        // Calculate size based on items
        let width = CGFloat(items.count) * itemWidth + horizontalPadding
        let height = NSStatusBar.system.thickness
        
        panel.setContentSize(NSSize(width: width, height: height))
        
        // Create content view
        let contentView = OverlayContentView(items: items, onItemTap: onItemTap)
        
        if hostingView == nil {
            hostingView = NSHostingView(rootView: AnyView(contentView))
            panel.contentView = hostingView
        } else {
            hostingView?.rootView = AnyView(contentView)
        }
        
        // Position and show
        panel.positionAtMenuBar(alignedTo: xPosition, on: targetScreen)
        
        panel.alphaValue = 0
        panel.orderFrontRegardless()
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            panel.animator().alphaValue = 1
        }
        
        isVisible = true
        logger.debug("Overlay shown with \(items.count) items at x=\(xPosition)")
    }
    
    /// Hides the overlay panel
    func hide() {
        guard let panel = panel, isVisible else { return }
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.1
            panel.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            panel.orderOut(nil)
            self?.isVisible = false
            self?.logger.debug("Overlay hidden")
        })
    }
    
    /// Toggles overlay visibility
    func toggle(
        items: [DrawerItem],
        alignedTo xPosition: CGFloat,
        on screen: NSScreen? = nil,
        onItemTap: @escaping (DrawerItem) -> Void
    ) {
        if isVisible {
            hide()
        } else {
            show(items: items, alignedTo: xPosition, on: screen, onItemTap: onItemTap)
        }
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        panel?.close()
        panel = nil
        hostingView = nil
        isVisible = false
    }
    
    deinit {
        panel?.close()
    }
}
```

### File 4: Add Setting to SettingsManager

**File:** `Drawer/Core/Managers/SettingsManager.swift`

```swift
// Add to existing settings
@AppStorage("overlayModeEnabled") var overlayModeEnabled: Bool = false {
    didSet {
        overlayModeEnabledSubject.send(overlayModeEnabled)
    }
}

let overlayModeEnabledSubject = PassthroughSubject<Bool, Never>()
```

---

## Directory Structure

After implementation:
```
Drawer/UI/
├── Panels/
│   ├── DrawerPanel.swift           (existing)
│   ├── DrawerPanelController.swift (existing)
│   └── DrawerContentView.swift     (existing)
└── Overlay/
    ├── OverlayPanel.swift          (NEW)
    ├── OverlayPanelController.swift (NEW)
    └── OverlayContentView.swift    (NEW)
```

---

## Acceptance Criteria

- [ ] `OverlayPanel` created with menu-bar-level positioning
- [ ] `OverlayContentView` renders icons horizontally
- [ ] `OverlayPanelController` manages panel lifecycle
- [ ] Panel appears at menu bar Y-coordinate
- [ ] Panel styled with NSVisualEffectView
- [ ] Hover states work on icons
- [ ] `overlayModeEnabled` setting added
- [ ] All files compile without errors
- [ ] Panel doesn't steal focus

---

## Testing

### Manual Verification Steps

1. Build and run
2. Instantiate `OverlayPanelController` in debug mode
3. Call `show(items:alignedTo:onItemTap:)` with test items
4. Verify panel appears at menu bar level
5. Verify icons are horizontally arranged
6. Hover over icons → verify highlight
7. Click icon → verify callback fires
8. Call `hide()` → verify smooth fade out

### Integration Test (Phase 4B)

Full integration with `MenuBarManager` and `IconCapturer` is covered in Phase 4B.

---

## Notes

- This phase creates the infrastructure only
- Phase 4B integrates it with the toggle flow
- The overlay doesn't replace the Drawer panel - it's an alternative mode
- Users choose between "Expand Mode" (traditional) and "Overlay Mode" in settings

---

## Files Created

| File | Purpose |
|------|---------|
| `Drawer/UI/Overlay/OverlayPanel.swift` | Menu-bar-level NSPanel |
| `Drawer/UI/Overlay/OverlayContentView.swift` | Icon strip UI |
| `Drawer/UI/Overlay/OverlayPanelController.swift` | Panel management |
| `Drawer/Core/Managers/SettingsManager.swift` | Add setting (modify) |
