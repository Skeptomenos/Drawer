# Spec: Phase 2A - Core Models (ControlItem & ControlItemImage)

**Phase:** 2A
**Priority:** High (P1)
**Estimated Time:** 25-30 minutes
**Dependencies:** Phase 1 (Reactive State Binding)
**Parent Doc:** `docs/IMPLEMENTATION_PLAN_ARCHITECTURE_IMPROVEMENTS.md`

---

## Objective

Create the foundational `ControlItem` and `ControlItemImage` types that encapsulate NSStatusItem management. These models provide reactive state binding and flexible icon rendering, forming the foundation for the Section-based architecture.

---

## Background

Currently, `MenuBarManager` directly manipulates raw `NSStatusItem` objects. This leads to:
- Scattered state management logic
- No encapsulation of length/visibility behavior
- Hardcoded image creation

The new models will:
- Encapsulate `NSStatusItem` with reactive state
- Auto-update length when state changes
- Provide flexible icon rendering (SF Symbols, BezierPath, assets)

---

## Files to Create

### 1. `Drawer/Core/Models/ControlItemState.swift`

### 2. `Drawer/Core/Models/ControlItemImage.swift`

### 3. `Drawer/Core/Models/ControlItem.swift`

---

## Implementation

### File 1: `Drawer/Core/Models/ControlItemState.swift`

```swift
//
//  ControlItemState.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import Foundation

/// Represents the visual state of a control item in the menu bar.
enum ControlItemState: String, CaseIterable {
    /// Item is expanded (separator at small length, icons visible)
    case expanded
    
    /// Item is collapsed (separator at 10k length, icons hidden)
    case collapsed
    
    /// Item is completely hidden from the menu bar
    case hidden
}
```

### File 2: `Drawer/Core/Models/ControlItemImage.swift`

```swift
//
//  ControlItemImage.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit

/// Represents different ways to render a control item's icon.
/// Supports SF Symbols, programmatic drawing, and asset catalog images.
enum ControlItemImage {
    /// An SF Symbol with optional weight configuration
    case sfSymbol(String, weight: NSFont.Weight = .medium)
    
    /// A programmatically drawn icon using NSBezierPath
    case bezierPath(() -> NSBezierPath)
    
    /// An image from the asset catalog
    case asset(String)
    
    /// No image
    case none
    
    // MARK: - Rendering
    
    /// Renders the image at the specified size.
    /// - Parameter size: The desired image size (default: 18x18)
    /// - Returns: An NSImage configured as a template image, or nil
    func render(size: NSSize = NSSize(width: 18, height: 18)) -> NSImage? {
        switch self {
        case .sfSymbol(let name, let weight):
            return renderSFSymbol(name: name, weight: weight)
        case .bezierPath(let pathBuilder):
            return renderBezierPath(pathBuilder(), size: size)
        case .asset(let name):
            return renderAsset(name: name)
        case .none:
            return nil
        }
    }
    
    // MARK: - Private Rendering Methods
    
    private func renderSFSymbol(name: String, weight: NSFont.Weight) -> NSImage? {
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: weight)
        guard let image = NSImage(systemSymbolName: name, accessibilityDescription: name) else {
            return nil
        }
        return image.withSymbolConfiguration(config)
    }
    
    private func renderBezierPath(_ path: NSBezierPath, size: NSSize) -> NSImage {
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.labelColor.setFill()
        path.fill()
        image.unlockFocus()
        image.isTemplate = true
        return image
    }
    
    private func renderAsset(name: String) -> NSImage? {
        guard let image = NSImage(named: name) else {
            return nil
        }
        image.isTemplate = true
        return image
    }
}

// MARK: - Common Images

extension ControlItemImage {
    /// Chevron pointing left (for LTR expand action)
    static let chevronLeft = ControlItemImage.sfSymbol("chevron.left")
    
    /// Chevron pointing right (for LTR collapse action)
    static let chevronRight = ControlItemImage.sfSymbol("chevron.right")
    
    /// Small circle used for separator
    static let separatorDot = ControlItemImage.sfSymbol("circle.fill", weight: .regular)
}
```

### File 3: `Drawer/Core/Models/ControlItem.swift`

```swift
//
//  ControlItem.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import Combine
import os.log

/// Encapsulates an NSStatusItem with reactive state management.
/// Automatically updates the status item's length and visibility when state changes.
@MainActor
final class ControlItem: ObservableObject {
    
    // MARK: - Published State
    
    /// The current state of the control item
    @Published var state: ControlItemState = .collapsed {
        didSet {
            guard oldValue != state else { return }
            updateStatusItemForState()
        }
    }
    
    /// The current image to display
    @Published var image: ControlItemImage? {
        didSet { updateImage() }
    }
    
    // MARK: - Properties
    
    /// The underlying NSStatusItem
    let statusItem: NSStatusItem
    
    /// The autosave name for position persistence
    var autosaveName: String? {
        get { statusItem.autosaveName }
        set { statusItem.autosaveName = newValue }
    }
    
    /// Direct access to the status bar button
    var button: NSStatusBarButton? {
        statusItem.button
    }
    
    /// The current length of the status item
    var length: CGFloat {
        statusItem.length
    }
    
    // MARK: - Configuration
    
    private let expandedLength: CGFloat
    private let collapsedLength: CGFloat
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.drawer", category: "ControlItem")
    
    // MARK: - Initialization
    
    /// Creates a new ControlItem wrapping an NSStatusItem.
    /// - Parameters:
    ///   - statusItem: The NSStatusItem to manage
    ///   - expandedLength: Length when expanded (default: 20)
    ///   - collapsedLength: Length when collapsed (default: 10000)
    ///   - initialState: Initial state (default: .collapsed)
    init(
        statusItem: NSStatusItem,
        expandedLength: CGFloat = 20,
        collapsedLength: CGFloat = 10000,
        initialState: ControlItemState = .collapsed
    ) {
        self.statusItem = statusItem
        self.expandedLength = expandedLength
        self.collapsedLength = collapsedLength
        self.state = initialState
        
        // Apply initial state
        updateStatusItemForState()
    }
    
    /// Convenience initializer that creates its own NSStatusItem
    /// - Parameters:
    ///   - expandedLength: Length when expanded (default: 20)
    ///   - collapsedLength: Length when collapsed (default: 10000)
    ///   - initialState: Initial state (default: .collapsed)
    convenience init(
        expandedLength: CGFloat = 20,
        collapsedLength: CGFloat = 10000,
        initialState: ControlItemState = .collapsed
    ) {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.init(
            statusItem: statusItem,
            expandedLength: expandedLength,
            collapsedLength: collapsedLength,
            initialState: initialState
        )
    }
    
    // MARK: - State Updates
    
    private func updateStatusItemForState() {
        switch state {
        case .expanded:
            statusItem.isVisible = true
            statusItem.length = expandedLength
            logger.debug("ControlItem state -> expanded, length=\(self.expandedLength)")
            
        case .collapsed:
            statusItem.isVisible = true
            statusItem.length = collapsedLength
            logger.debug("ControlItem state -> collapsed, length=\(self.collapsedLength)")
            
        case .hidden:
            statusItem.isVisible = false
            logger.debug("ControlItem state -> hidden")
        }
    }
    
    private func updateImage() {
        guard let image = image else {
            button?.image = nil
            return
        }
        button?.image = image.render()
        button?.imagePosition = .imageOnly
    }
    
    // MARK: - Actions
    
    /// Sets the target and action for button clicks
    /// - Parameters:
    ///   - target: The target object
    ///   - action: The selector to call
    func setAction(target: AnyObject?, action: Selector?) {
        button?.target = target
        button?.action = action
    }
    
    /// Sets which mouse events trigger the action
    /// - Parameter mask: The event mask (e.g., [.leftMouseUp, .rightMouseUp])
    func setSendAction(on mask: NSEvent.EventTypeMask) {
        button?.sendAction(on: mask)
    }
    
    /// Sets the context menu for right-click
    /// - Parameter menu: The menu to display
    func setMenu(_ menu: NSMenu?) {
        statusItem.menu = menu
    }
}

// MARK: - Identifiable

extension ControlItem: Identifiable {
    nonisolated var id: ObjectIdentifier {
        ObjectIdentifier(self)
    }
}
```

---

## Directory Structure

After implementation:
```
Drawer/Core/Models/
├── ControlItemState.swift    (NEW)
├── ControlItemImage.swift    (NEW)
├── ControlItem.swift         (NEW)
├── DrawerItem.swift          (existing)
└── ... other models
```

---

## Acceptance Criteria

- [ ] `ControlItemState` enum created with `expanded`, `collapsed`, `hidden` cases
- [ ] `ControlItemImage` enum created with SF Symbol, BezierPath, asset, and none cases
- [ ] `ControlItemImage.render()` returns properly configured NSImage
- [ ] `ControlItem` class wraps NSStatusItem with reactive `state` property
- [ ] Setting `ControlItem.state` automatically updates `statusItem.length`
- [ ] Setting `ControlItem.state = .hidden` sets `statusItem.isVisible = false`
- [ ] Setting `ControlItem.image` updates the button image
- [ ] `ControlItem` has convenience initializer that creates its own NSStatusItem
- [ ] All files compile without errors
- [ ] All files have correct copyright headers

---

## Testing

### Unit Test Ideas (for Phase 2C)

```swift
func testControlItemStateChangesLength() {
    let item = ControlItem()
    XCTAssertEqual(item.length, 10000) // Initial collapsed
    
    item.state = .expanded
    XCTAssertEqual(item.length, 20)
    
    item.state = .collapsed
    XCTAssertEqual(item.length, 10000)
}

func testControlItemImageRenders() {
    let image = ControlItemImage.chevronLeft.render()
    XCTAssertNotNil(image)
}
```

### Manual Verification

These models don't have UI on their own yet. Verification will happen in Phase 2B when integrated with `MenuBarManager`.

---

## Notes

- These models are designed to be testable in isolation
- `ControlItem` uses `@MainActor` because NSStatusItem must be accessed on main thread
- The `logger` helps debug state transitions during development
- `ControlItemImage` static properties provide common icons used throughout the app

---

## Files Created

| File | Purpose |
|------|---------|
| `Drawer/Core/Models/ControlItemState.swift` | State enum |
| `Drawer/Core/Models/ControlItemImage.swift` | Image rendering enum |
| `Drawer/Core/Models/ControlItem.swift` | NSStatusItem wrapper |
