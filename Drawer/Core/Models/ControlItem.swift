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
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.drawer",
        category: "ControlItem"
    )

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
