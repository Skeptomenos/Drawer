//
//  OverlayPanel.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit

// MARK: - OverlayPanel

/// A floating panel that renders at menu bar level to display hidden icons.
/// Styled to match the system menu bar appearance.
///
/// Unlike DrawerPanel which appears below the menu bar, OverlayPanel
/// positions itself AT the menu bar level as an alternative display mode.
/// This definitively solves the MacBook Notch problem by keeping icons
/// hidden while displaying them in a floating panel.
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

    // MARK: - Configuration

    private func configure() {
        // Panel behavior - appear at status bar level
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true

        // Don't steal focus from other apps
        hidesOnDeactivate = false
        isMovable = false
        isMovableByWindowBackground = false

        // Hide window chrome
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        standardWindowButton(.closeButton)?.isHidden = true
        standardWindowButton(.miniaturizeButton)?.isHidden = true
        standardWindowButton(.zoomButton)?.isHidden = true
    }

    // MARK: - Window Behavior Overrides

    /// Prevent panel from becoming key window (stealing focus)
    override var canBecomeKey: Bool { false }

    /// Prevent panel from becoming main window
    override var canBecomeMain: Bool { false }

    // MARK: - Positioning

    /// Positions the panel at menu bar level, aligned to the right of the separator.
    /// - Parameters:
    ///   - xPosition: X position to align left edge (typically separator's right edge)
    ///   - screen: Screen to display on
    func positionAtMenuBar(alignedTo xPosition: CGFloat, on screen: NSScreen) {
        let menuBarHeight = NSStatusBar.system.thickness
        let panelHeight = frame.height

        // Position just below the menu bar (2px gap for visual separation)
        let yPosition = screen.frame.maxY - menuBarHeight - panelHeight - 2

        // Clamp X to stay within screen bounds
        let maxX = screen.frame.maxX - frame.width
        let clampedX = min(max(xPosition, screen.frame.minX), maxX)

        let origin = NSPoint(x: clampedX, y: yPosition)
        setFrameOrigin(origin)
    }
}
