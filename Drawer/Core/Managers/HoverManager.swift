//
//  HoverManager.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import os.log

@MainActor
@Observable
final class HoverManager {

    static let shared = HoverManager()
    
    @ObservationIgnored private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.drawer", category: "HoverManager")

    private(set) var isMouseInTriggerZone: Bool = false
    private(set) var isMouseInDrawerArea: Bool = false
    private(set) var isMonitoring: Bool = false

    private var menuBarHeight: CGFloat { MenuBarMetrics.height }
    private let debounceInterval: TimeInterval = 0.15
    private let hideDebounceInterval: TimeInterval = 0.3

    @ObservationIgnored private var mouseMonitor: GlobalEventMonitor?
    @ObservationIgnored private var scrollMonitor: GlobalEventMonitor?
    @ObservationIgnored private var clickMonitor: GlobalEventMonitor?
    @ObservationIgnored private var appDeactivationObserver: NSObjectProtocol?
    @ObservationIgnored private var showDebounceTimer: Timer?
    @ObservationIgnored private var hideDebounceTimer: Timer?

    // MARK: - Scroll Gesture Properties

    /// Accumulated scroll delta for threshold detection
    private var accumulatedScrollDelta: CGFloat = 0

    /// Threshold in points before scroll triggers action (prevents accidental triggers)
    private let scrollThreshold: CGFloat = 30

    /// Track last scroll direction to reset on direction change
    private var lastScrollDirection: ScrollDirection = .none

    private enum ScrollDirection {
        case none, up, down
    }

    var onShouldShowDrawer: ((NSScreen?) -> Void)?
    var onShouldHideDrawer: (() -> Void)?
    
    private var triggerScreen: NSScreen?

    private var drawerFrame: CGRect = .zero
    private var isDrawerVisible: Bool = false

    private init() {}

    nonisolated deinit {
        #if DEBUG
        print("HoverManager deallocated - ensure stopMonitoring() was called before deallocation")
        #endif
    }

    func startMonitoring() {
        guard !isMonitoring else { 
            logger.debug("Already monitoring, skipping start")
            return 
        }

        logger.debug("Starting monitoring...")
        logger.debug("Settings: showOnHover=\(SettingsManager.shared.showOnHover), showOnScrollDown=\(SettingsManager.shared.showOnScrollDown)")
        
        mouseMonitor = GlobalEventMonitor(mask: .mouseMoved) { [weak self] event in
            Task { @MainActor in
                self?.handleMouseMoved(event)
            }
        }
        mouseMonitor?.start()
        logger.debug("Mouse monitor started, isRunning=\(self.mouseMonitor?.isRunning == true)")

        scrollMonitor = GlobalEventMonitor(mask: .scrollWheel) { [weak self] event in
            Task { @MainActor in
                self?.handleScrollEvent(event)
            }
        }
        scrollMonitor?.start()
        logger.debug("Scroll monitor started, isRunning=\(self.scrollMonitor?.isRunning == true)")

        clickMonitor = GlobalEventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            Task { @MainActor in
                self?.handleClickEvent(event)
            }
        }
        clickMonitor?.start()
        logger.debug("Click monitor started, isRunning=\(self.clickMonitor?.isRunning == true)")

        // Subscribe to app deactivation notifications for focus-loss detection.
        // Hides drawer when user switches to another application (Cmd+Tab, clicking another app).
        appDeactivationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didDeactivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                self?.handleAppDeactivation(notification)
            }
        }

        isMonitoring = true
        logger.debug("Monitoring started successfully, isMonitoring=\(self.isMonitoring)")
    }

    func stopMonitoring() {
        mouseMonitor?.stop()
        mouseMonitor = nil
        scrollMonitor?.stop()
        scrollMonitor = nil
        clickMonitor?.stop()
        clickMonitor = nil
        if let observer = appDeactivationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            appDeactivationObserver = nil
        }
        showDebounceTimer?.invalidate()
        showDebounceTimer = nil
        hideDebounceTimer?.invalidate()
        hideDebounceTimer = nil
        resetScrollState()
        isMonitoring = false
        isMouseInTriggerZone = false
        isMouseInDrawerArea = false
    }

    func updateDrawerFrame(_ frame: CGRect) {
        drawerFrame = frame
    }

    func setDrawerVisible(_ visible: Bool) {
        isDrawerVisible = visible
        if !visible {
            isMouseInDrawerArea = false
        }
    }

    private func handleMouseMoved(_ event: NSEvent?) {
        let mouseLocation = NSEvent.mouseLocation
        let eventScreen = NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) })

        let wasInTriggerZone = isMouseInTriggerZone
        let wasInDrawerArea = isMouseInDrawerArea

        isMouseInTriggerZone = isInMenuBarTriggerZone(mouseLocation)
        isMouseInDrawerArea = isDrawerVisible && isInDrawerArea(mouseLocation)

        if isMouseInTriggerZone && !wasInTriggerZone {
            logger.debug("ENTERED trigger zone, drawerVisible=\(self.isDrawerVisible), showOnHover=\(SettingsManager.shared.showOnHover)")
        } else if !isMouseInTriggerZone && wasInTriggerZone {
            logger.debug("LEFT trigger zone")
        }

        if isMouseInTriggerZone && !wasInTriggerZone && !isDrawerVisible && SettingsManager.shared.showOnHover {
            logger.debug("Scheduling show drawer (hover)")
            triggerScreen = eventScreen
            scheduleShowDrawer()
        } else if !isMouseInTriggerZone && wasInTriggerZone && !isDrawerVisible {
            cancelShowDrawer()
        }

        if isDrawerVisible {
            let isInSafeArea = isMouseInTriggerZone || isMouseInDrawerArea

            if !isInSafeArea && (wasInTriggerZone || wasInDrawerArea) {
                // Only schedule hide if hideOnMouseAway setting is enabled
                if SettingsManager.shared.hideOnMouseAway {
                    scheduleHideDrawer()
                }
            } else if isInSafeArea {
                cancelHideDrawer()
            }
        }
    }

    func isInMenuBarTriggerZone(_ point: NSPoint) -> Bool {
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(point) }) else {
            logger.debug("isInMenuBarTriggerZone: no screen contains point \(point.x, privacy: .public),\(point.y, privacy: .public)")
            return false
        }

        let screenTop = screen.frame.maxY
        let screenMenuBarHeight = MenuBarMetrics.height(for: screen)
        let triggerZoneBottom = screenTop - screenMenuBarHeight
        
        return point.y >= triggerZoneBottom && point.y <= screenTop
    }

    func isInDrawerArea(_ point: NSPoint) -> Bool {
        guard !drawerFrame.isEmpty else { return false }

        let expandedFrame = drawerFrame.insetBy(dx: -10, dy: -10)
        return expandedFrame.contains(point)
    }

    private func scheduleShowDrawer() {
        showDebounceTimer?.invalidate()
        showDebounceTimer = Timer.scheduledTimer(withTimeInterval: debounceInterval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, self.isMouseInTriggerZone else { return }
                self.onShouldShowDrawer?(self.triggerScreen)
            }
        }
    }

    private func cancelShowDrawer() {
        showDebounceTimer?.invalidate()
        showDebounceTimer = nil
    }

    private func scheduleHideDrawer() {
        hideDebounceTimer?.invalidate()
        hideDebounceTimer = Timer.scheduledTimer(withTimeInterval: hideDebounceInterval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                let isInSafeArea = self.isMouseInTriggerZone || self.isMouseInDrawerArea
                if !isInSafeArea {
                    self.onShouldHideDrawer?()
                }
            }
        }
    }

    private func cancelHideDrawer() {
        hideDebounceTimer?.invalidate()
        hideDebounceTimer = nil
    }

    // MARK: - Scroll Gesture Handling

    /// Handles scroll wheel events for gesture-based drawer control.
    /// Respects natural scrolling preference and accumulates delta until threshold is met.
    /// Only triggers actions if the corresponding settings (showOnScrollDown, hideOnScrollUp) are enabled.
    private func handleScrollEvent(_ event: NSEvent?) {
        guard let event = event else { return }

        // Early exit if both scroll settings are disabled
        let settings = SettingsManager.shared
        guard settings.showOnScrollDown || settings.hideOnScrollUp else {
            return
        }

        let mouseLocation = NSEvent.mouseLocation
        let eventScreen = NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) })
        
        let isInTriggerZone = isInMenuBarTriggerZone(mouseLocation)
        let isInDrawer = isDrawerVisible && isInDrawerArea(mouseLocation)

        guard isInTriggerZone || isInDrawer else {
            resetScrollState()
            return
        }
        
        triggerScreen = eventScreen

        // Get scroll delta, accounting for natural scrolling preference.
        // scrollingDeltaY is positive for scroll-up gesture (content moves down).
        // With natural scrolling inverted, the physical gesture direction is reversed.
        var deltaY = event.scrollingDeltaY

        // If natural scrolling is enabled, the delta is already inverted by the system.
        // We want physical gesture direction: swipe down = show, swipe up = hide.
        // With natural scrolling OFF: swipe down = negative deltaY, swipe up = positive deltaY
        // With natural scrolling ON: swipe down = positive deltaY, swipe up = negative deltaY
        // We normalize so that negative = physical down, positive = physical up
        if event.isDirectionInvertedFromDevice {
            deltaY = -deltaY
        }

        // Determine current scroll direction
        let currentDirection: ScrollDirection = deltaY > 0 ? .up : (deltaY < 0 ? .down : .none)

        // Reset accumulated delta if direction changed
        if currentDirection != lastScrollDirection && currentDirection != .none {
            accumulatedScrollDelta = 0
            lastScrollDirection = currentDirection
        }

        // Accumulate scroll delta
        accumulatedScrollDelta += abs(deltaY)

        // Check if we've reached the threshold
        if accumulatedScrollDelta >= scrollThreshold {
            if currentDirection == .down && !isDrawerVisible && settings.showOnScrollDown {
                logger.debug("Scroll threshold reached (down), calling onShouldShowDrawer on screen: \(self.triggerScreen?.localizedName ?? "nil", privacy: .public)")
                onShouldShowDrawer?(triggerScreen)
                resetScrollState()
            } else if currentDirection == .up && isDrawerVisible && settings.hideOnScrollUp {
                logger.debug("Scroll threshold reached (up), calling onShouldHideDrawer")
                onShouldHideDrawer?()
                resetScrollState()
            }
        }

        // Reset on gesture end
        if event.phase == .ended || event.phase == .cancelled {
            resetScrollState()
        }
    }

    /// Resets scroll tracking state
    private func resetScrollState() {
        accumulatedScrollDelta = 0
        lastScrollDirection = .none
    }

    // MARK: - Click-Outside Detection

    /// Handles click events for click-outside-to-dismiss behavior.
    /// Only triggers hide when drawer is visible and click is outside drawer area.
    private func handleClickEvent(_ event: NSEvent?) {
        // Only process if drawer is visible and setting is enabled
        guard isDrawerVisible,
              SettingsManager.shared.hideOnClickOutside else {
            return
        }

        let clickLocation = NSEvent.mouseLocation

        // Check if click is inside the drawer area (with small padding for tolerance)
        let isInsideDrawer = isInDrawerArea(clickLocation)

        // Also check if click is in menu bar area (toggle icon clicks should not dismiss)
        let isInMenuBar = isInMenuBarTriggerZone(clickLocation)

        // If click is outside both drawer and menu bar, trigger hide
        if !isInsideDrawer && !isInMenuBar {
            onShouldHideDrawer?()
        }
    }

    // MARK: - App Deactivation Detection

    /// Handles app deactivation (focus-loss) events.
    /// Hides drawer when user switches to another application (Cmd+Tab, clicking another app window).
    /// Respects the `hideOnClickOutside` setting since focus-loss is a related behavior.
    private func handleAppDeactivation(_ notification: Notification) {
        // Only process if drawer is visible and setting is enabled
        guard isDrawerVisible,
              SettingsManager.shared.hideOnClickOutside else {
            return
        }

        // Verify that our app (Drawer) was the one that was deactivated
        // The notification's object is the NSRunningApplication that was deactivated
        if let deactivatedApp = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
           deactivatedApp.bundleIdentifier == Bundle.main.bundleIdentifier {
            onShouldHideDrawer?()
        }
    }
}
