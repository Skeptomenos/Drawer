//
//  DrawerManager.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import Combine
import Foundation
import os.log

// MARK: - DrawerManager

/// Manages the state and items displayed in the Drawer.
///
/// This manager is responsible for:
/// - Storing the current drawer items (captured icons)
/// - Converting captured icons to drawer items
/// - Managing drawer visibility state
/// - Coordinating with IconCapturer for refreshing items
@MainActor
final class DrawerManager: ObservableObject {

    // MARK: - Singleton

    static let shared = DrawerManager()

    // MARK: - Logger

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.drawer", category: "DrawerManager")

    // MARK: - Published State

    /// The items currently displayed in the drawer
    @Published private(set) var items: [DrawerItem] = []

    /// Whether the drawer is currently visible
    @Published var isVisible: Bool = false

    /// Whether items are currently being loaded/captured
    @Published private(set) var isLoading: Bool = false

    /// The last error that occurred during item loading
    @Published private(set) var lastError: Error?

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        logger.debug("DrawerManager initialized")
    }

    deinit {
        cancellables.removeAll()
    }

    // MARK: - Public API

    /// Updates the drawer items from a capture result
    /// - Parameter captureResult: The result from IconCapturer
    func updateItems(from captureResult: MenuBarCaptureResult) {
        let newItems = captureResult.icons.toDrawerItems()
        items = newItems
        lastError = nil
        logger.info("Updated drawer with \(newItems.count) items")
    }

    /// Updates the drawer items from an array of captured icons
    /// - Parameter capturedIcons: Array of captured icons
    func updateItems(from capturedIcons: [CapturedIcon]) {
        let newItems = capturedIcons.toDrawerItems()
        items = newItems
        lastError = nil
        logger.info("Updated drawer with \(newItems.count) items from icons array")
    }

    /// Clears all items from the drawer
    func clearItems() {
        items = []
        lastError = nil
        logger.debug("Cleared drawer items")
    }

    /// Sets the loading state
    /// - Parameter loading: Whether items are being loaded
    func setLoading(_ loading: Bool) {
        isLoading = loading
    }

    /// Records an error that occurred during item loading
    /// - Parameter error: The error that occurred
    func setError(_ error: Error?) {
        lastError = error
        if let error = error {
            logger.error("Drawer error: \(error.localizedDescription)")
        }
    }

    /// Shows the drawer
    func show() {
        isVisible = true
        logger.debug("Drawer shown")
    }

    /// Hides the drawer
    func hide() {
        isVisible = false
        logger.debug("Drawer hidden")
    }

    /// Toggles drawer visibility
    func toggle() {
        isVisible.toggle()
        logger.debug("Drawer toggled: \(self.isVisible ? "visible" : "hidden")")
    }

    // MARK: - Computed Properties

    /// Whether the drawer has any items to display
    var hasItems: Bool {
        !items.isEmpty
    }

    /// The number of items in the drawer
    var itemCount: Int {
        items.count
    }

    /// Whether the drawer is in an empty state (no items and not loading)
    var isEmpty: Bool {
        items.isEmpty && !isLoading
    }
}
