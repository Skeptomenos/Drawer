//
//  OverlayModeManager.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import os.log

// MARK: - OverlayModeManager

/// Manages the Overlay Mode flow - capturing hidden icons and displaying them
/// in a floating panel at menu bar level without expanding the menu bar.
///
/// Overlay Mode provides an alternative to the traditional "expand" mode where
/// icons are revealed by shrinking the separator. Instead, icons are captured
/// and displayed in a floating panel, which works better on MacBooks with a notch.
///
/// ## Flow
/// 1. User clicks toggle
/// 2. Separator stays at 10k (icons remain hidden)
/// 3. Capture hidden icon windows
/// 4. Overlay panel appears at menu bar level
/// 5. User clicks icon in overlay
/// 6. EventSimulator sends click to hidden icon
/// 7. Overlay dismisses
@MainActor
@Observable
final class OverlayModeManager {

    // MARK: - Published State

    /// Whether the overlay panel is currently visible (delegated to overlayController)
    var isOverlayVisible: Bool {
        overlayController.isVisible
    }

    /// Whether icons are currently being captured
    private(set) var isCapturing: Bool = false

    /// The currently displayed items in the overlay
    private(set) var capturedItems: [DrawerItem] = []

    // MARK: - Dependencies

    private let settings: SettingsManager
    private let iconCapturer: IconCapturer
    private let eventSimulator: EventSimulator
    private let overlayController: OverlayPanelController
    private weak var menuBarManager: MenuBarManager?

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.drawer",
        category: "OverlayModeManager"
    )
    @ObservationIgnored private var autoHideTask: Task<Void, Never>?

    // MARK: - Configuration

    /// Delay before auto-hiding the overlay panel (in seconds)
    private let autoHideDelay: TimeInterval = 5.0

    // MARK: - Initialization

    init(
        settings: SettingsManager,
        iconCapturer: IconCapturer,
        eventSimulator: EventSimulator,
        menuBarManager: MenuBarManager,
        overlayController: OverlayPanelController? = nil
    ) {
        self.settings = settings
        self.iconCapturer = iconCapturer
        self.eventSimulator = eventSimulator
        self.menuBarManager = menuBarManager
        self.overlayController = overlayController ?? OverlayPanelController()
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
        guard let menuBarManager = menuBarManager else {
            logger.error("MenuBarManager is nil, cannot show overlay")
            return
        }

        isCapturing = true
        logger.debug("Starting overlay capture...")

        do {
            // Capture icons - this temporarily expands and collapses the menu bar
            let result = try await captureHiddenIconsForOverlay(menuBarManager: menuBarManager)

            // Convert captured icons to drawer items
            let items = result.icons.toDrawerItems()

            capturedItems = items
            isCapturing = false

            guard !items.isEmpty else {
                logger.debug("No hidden icons to display")
                return
            }

            // Calculate position (right edge of separator)
            let xPosition = calculateOverlayPosition(menuBarManager: menuBarManager)

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

    /// Captures hidden icons by briefly expanding the menu bar.
    /// The menu bar is expanded just long enough to capture icons,
    /// then immediately collapsed to maintain the overlay illusion.
    private func captureHiddenIconsForOverlay(
        menuBarManager: MenuBarManager
    ) async throws -> MenuBarCaptureResult {
        let wasCollapsed = menuBarManager.isCollapsed

        if wasCollapsed {
            menuBarManager.expand()
            // Brief delay for icons to settle into position
            try await Task.sleep(nanoseconds: 100_000_000)  // 100ms
        }

        let result = try await iconCapturer.captureHiddenIcons(menuBarManager: menuBarManager)

        // Immediately collapse back to maintain the illusion
        if wasCollapsed {
            menuBarManager.collapse()
        }

        return result
    }

    /// Calculates the X position for the overlay panel.
    /// Positions the panel at the right edge of the separator.
    private func calculateOverlayPosition(menuBarManager: MenuBarManager) -> CGFloat {
        // Position at the separator's right edge
        if let separatorWindow = menuBarManager.separatorControlItem.button?.window {
            return separatorWindow.frame.maxX + 4
        }

        // Fallback: center of main screen
        return (NSScreen.main?.frame.width ?? 1000) / 2 - 100
    }

    /// Handles tap on an icon in the overlay.
    /// Dismisses overlay, expands menu bar briefly, and simulates click.
    private func handleOverlayItemTap(_ item: DrawerItem) async {
        logger.info("Overlay item tapped at index \(item.index)")

        guard let menuBarManager = menuBarManager else {
            logger.error("MenuBarManager is nil, cannot handle tap")
            return
        }

        // Hide overlay first
        hideOverlay()

        // Brief delay
        try? await Task.sleep(nanoseconds: 50_000_000)  // 50ms

        // Expand menu bar to reveal the real icon
        menuBarManager.expand()

        // Wait for icons to settle
        try? await Task.sleep(nanoseconds: 100_000_000)  // 100ms

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
            guard let delay = self?.autoHideDelay else { return }
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            self?.hideOverlay()
        }
    }

    private func cancelAutoHideTimer() {
        autoHideTask?.cancel()
        autoHideTask = nil
    }

}
