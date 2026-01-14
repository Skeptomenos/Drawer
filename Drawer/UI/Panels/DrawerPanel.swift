//
//  DrawerPanel.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit

// MARK: - DrawerPanel

/// A floating, non-activating panel that hosts the Drawer UI.
/// Positioned below the menu bar to display hidden menu bar icons.
///
/// Key characteristics:
/// - Borderless (no title bar or window chrome)
/// - Non-activating (doesn't steal focus from other apps)
/// - Floats above normal windows but below menus
/// - Appears on all Spaces
/// - Has shadow for depth
final class DrawerPanel: NSPanel {
    
    // MARK: - Constants
    
    /// Height of the macOS menu bar (standard is 24pt, but can vary with notch)
    private static let menuBarHeight: CGFloat = 24
    
    /// Gap between menu bar and drawer panel
    private static let menuBarGap: CGFloat = 4
    
    /// Default panel height (slightly taller than menu bar for visual balance)
    static let defaultHeight: CGFloat = 36
    
    /// Default panel width (will be adjusted based on content)
    static let defaultWidth: CGFloat = 200
    
    /// Corner radius matching reference design (10-12pt)
    static let cornerRadius: CGFloat = 10
    
    // MARK: - Initialization
    
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: Self.defaultWidth, height: Self.defaultHeight),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        configurePanel()
    }
    
    private func configurePanel() {
        // Window level: above normal windows, at status bar level
        level = .statusBar
        
        // Appear on all Spaces and work with full screen apps
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        
        // Transparent background (content view provides visual effect)
        isOpaque = false
        backgroundColor = .clear
        
        // Enable shadow for depth
        hasShadow = true
        
        // Don't show in window lists or Expose
        hidesOnDeactivate = false
        
        // Allow mouse events to pass through when appropriate
        ignoresMouseEvents = false
        
        // Animation behavior
        animationBehavior = .utilityWindow
    }
    
    // MARK: - Window Behavior Overrides
    
    /// Prevent panel from becoming key window (stealing focus)
    override var canBecomeKey: Bool { false }
    
    /// Prevent panel from becoming main window
    override var canBecomeMain: Bool { false }
    
    // MARK: - Positioning
    
    /// Positions the panel below the menu bar on the specified screen.
    /// - Parameter screen: The screen to position on. Defaults to main screen.
    func position(on screen: NSScreen? = nil) {
        guard let targetScreen = screen ?? NSScreen.main else { return }
        
        // Get the visible frame (excludes menu bar and dock)
        let visibleFrame = targetScreen.visibleFrame
        let fullFrame = targetScreen.frame
        
        // Calculate menu bar height for this screen (accounts for notch on newer Macs)
        let menuBarHeight = fullFrame.maxY - visibleFrame.maxY
        
        // Position panel just below menu bar, centered horizontally
        let panelWidth = frame.width
        let panelHeight = frame.height
        
        let x = fullFrame.midX - (panelWidth / 2)
        let y = fullFrame.maxY - menuBarHeight - Self.menuBarGap - panelHeight
        
        setFrameOrigin(NSPoint(x: x, y: y))
    }
    
    /// Positions the panel below the menu bar, aligned to a specific X coordinate.
    /// Useful for aligning with the toggle button position.
    /// - Parameters:
    ///   - xPosition: The X coordinate to align the panel's leading edge to.
    ///   - screen: The screen to position on. Defaults to main screen.
    func position(alignedTo xPosition: CGFloat, on screen: NSScreen? = nil) {
        guard let targetScreen = screen ?? NSScreen.main else { return }
        
        let visibleFrame = targetScreen.visibleFrame
        let fullFrame = targetScreen.frame
        
        let menuBarHeight = fullFrame.maxY - visibleFrame.maxY
        let panelHeight = frame.height
        
        // Clamp X position to keep panel on screen
        let maxX = fullFrame.maxX - frame.width
        let clampedX = min(max(xPosition, fullFrame.minX), maxX)
        
        let y = fullFrame.maxY - menuBarHeight - Self.menuBarGap - panelHeight
        
        setFrameOrigin(NSPoint(x: clampedX, y: y))
    }
    
    // MARK: - Size Management
    
    /// Updates the panel width to accommodate content.
    /// - Parameter width: The new width for the panel.
    func updateWidth(_ width: CGFloat) {
        var newFrame = frame
        let oldMidX = newFrame.midX
        newFrame.size.width = max(width, Self.defaultWidth)
        // Keep centered at same position
        newFrame.origin.x = oldMidX - (newFrame.width / 2)
        setFrame(newFrame, display: true)
    }
}
