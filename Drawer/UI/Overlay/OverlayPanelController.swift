//
//  OverlayPanelController.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import Combine
import os.log
import SwiftUI

// MARK: - OverlayPanelController

/// Manages the overlay panel lifecycle and positioning.
///
/// Responsible for:
/// - Creating and caching the OverlayPanel instance
/// - Showing/hiding with fade animations
/// - Positioning at menu bar level
/// - Updating content when items change
@MainActor
final class OverlayPanelController: ObservableObject {

    // MARK: - Published State

    /// Whether the overlay panel is currently visible
    @Published private(set) var isVisible: Bool = false

    // MARK: - Properties

    private var panel: OverlayPanel?
    private var hostingView: NSHostingView<AnyView>?
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.drawer",
        category: "OverlayPanelController"
    )

    // MARK: - Configuration

    /// Width allocated per icon item
    private let itemWidth: CGFloat = 24

    /// Horizontal padding on each side
    private let horizontalPadding: CGFloat = 8

    /// Animation duration for showing panel
    private let showDuration: TimeInterval = 0.15

    /// Animation duration for hiding panel
    private let hideDuration: TimeInterval = 0.1

    // MARK: - Initialization

    init() {}

    // MARK: - Public Interface

    /// The current frame of the panel (for hit testing)
    var panelFrame: CGRect {
        panel?.frame ?? .zero
    }

    /// Shows the overlay panel with the given items.
    /// - Parameters:
    ///   - items: The icons to display
    ///   - xPosition: X position to align the panel's left edge
    ///   - screen: Screen to display on (defaults to main)
    ///   - onItemTap: Callback when an icon is tapped
    func show(
        items: [DrawerItem],
        alignedTo xPosition: CGFloat,
        on screen: NSScreen? = nil,
        onItemTap: @escaping (DrawerItem) -> Void
    ) {
        guard let targetScreen = screen ?? NSScreen.main ?? NSScreen.screens.first else {
            logger.warning("No screen available for overlay panel")
            return
        }

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

        NSAnimationContext.runAnimationGroup { [showDuration] context in
            context.duration = showDuration
            panel.animator().alphaValue = 1
        }

        isVisible = true
        logger.debug("Overlay shown with \(items.count) items at x=\(xPosition)")
    }

    /// Hides the overlay panel with a fade animation.
    func hide() {
        guard let panel = panel, isVisible else { return }

        NSAnimationContext.runAnimationGroup({ [hideDuration] context in
            context.duration = hideDuration
            panel.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            panel.orderOut(nil)
            self?.isVisible = false
            self?.logger.debug("Overlay hidden")
        })
    }

    /// Toggles overlay visibility.
    /// - Parameters:
    ///   - items: The icons to display when showing
    ///   - xPosition: X position to align the panel
    ///   - screen: Screen to display on (defaults to main)
    ///   - onItemTap: Callback when an icon is tapped
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

    /// Cleans up panel resources.
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
