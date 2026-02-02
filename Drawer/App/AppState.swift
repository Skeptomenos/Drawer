//
//  AppState.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import Combine
import os.log

@MainActor
@Observable
final class AppState {

    var isCollapsed: Bool = true
    private(set) var isDrawerVisible: Bool = false {
        didSet {
            if oldValue != isDrawerVisible {
                hoverManager.setDrawerVisible(isDrawerVisible)
            }
        }
    }
    private(set) var hasRequiredPermissions: Bool = false
    private(set) var isCapturing: Bool = false
    private(set) var captureError: CaptureError?

    @ObservationIgnored let menuBarManager: MenuBarManager
    @ObservationIgnored let settings: SettingsManager
    @ObservationIgnored let permissions: PermissionManager
    @ObservationIgnored let drawerController: DrawerPanelController
    @ObservationIgnored let drawerManager: DrawerManager
    @ObservationIgnored let iconCapturer: IconCapturer
    @ObservationIgnored let eventSimulator: EventSimulator
    @ObservationIgnored let hoverManager: HoverManager
    @ObservationIgnored let overlayModeManager: OverlayModeManager

    static let shared = AppState()

    @ObservationIgnored private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.drawer", category: "AppState")
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()
    @ObservationIgnored private var menuBarFailureObserver: NSObjectProtocol?

    var hasCompletedOnboarding: Bool {
        get { settings.hasCompletedOnboarding }
        set { settings.hasCompletedOnboarding = newValue }
    }

    init(
        settings: SettingsManager? = nil,
        permissions: PermissionManager? = nil,
        drawerManager: DrawerManager? = nil,
        iconCapturer: IconCapturer? = nil,
        eventSimulator: EventSimulator? = nil,
        hoverManager: HoverManager? = nil
    ) {
        let resolvedSettings = settings ?? .shared
        let resolvedPermissions = permissions ?? .shared
        let resolvedDrawerManager = drawerManager ?? .shared
        let resolvedIconCapturer = iconCapturer ?? .shared
        let resolvedEventSimulator = eventSimulator ?? .shared
        let resolvedHoverManager = hoverManager ?? .shared
        
        self.settings = resolvedSettings
        self.permissions = resolvedPermissions
        self.drawerManager = resolvedDrawerManager
        self.iconCapturer = resolvedIconCapturer
        self.eventSimulator = resolvedEventSimulator
        self.hoverManager = resolvedHoverManager
        self.menuBarManager = MenuBarManager(settings: resolvedSettings)
        self.drawerController = DrawerPanelController()

        self.overlayModeManager = OverlayModeManager(
            settings: resolvedSettings,
            iconCapturer: resolvedIconCapturer,
            eventSimulator: resolvedEventSimulator,
            menuBarManager: menuBarManager
        )

        menuBarManager.onCollapsedChanged = { [weak self] collapsed in
            self?.isCollapsed = collapsed
        }
        isCollapsed = menuBarManager.isCollapsed

        setupPermissionBindings()
        setupDrawerBindings()
        setupCapturerBindings()
        setupHoverBindings()
        setupMenuBarFailureObserver()
        setupToggleCallback()
    }

    private func setupMenuBarFailureObserver() {
        menuBarFailureObserver = NotificationCenter.default.addObserver(
            forName: .menuBarSetupFailed,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.logger.error("Menu bar setup failed after all retry attempts")
        }
    }

    private func setupPermissionBindings() {
        permissions.onPermissionStatusChanged = { [weak self] in
            self?.hasRequiredPermissions = self?.permissions.hasAllPermissions ?? false
        }
        hasRequiredPermissions = permissions.hasAllPermissions
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
    }

    /// Toggles the menu bar - respects overlay mode setting.
    /// When overlay mode is enabled, shows the overlay panel instead of expanding the menu bar.
    func toggleMenuBar() {
        if settings.overlayModeEnabled {
            Task {
                await overlayModeManager.toggleOverlay()
            }
        } else {
            menuBarManager.toggle()
        }
    }

    /// Sets up the toggle callback from MenuBarManager to AppState.
    /// This allows the toggle button to route through AppState, which decides
    /// whether to use traditional expand mode or overlay mode.
    private func setupToggleCallback() {
        menuBarManager.onTogglePressed = { [weak self] in
            self?.toggleMenuBar()
        }
    }

    func toggleDrawer() {
        if isDrawerVisible {
            hideDrawer()
        } else {
            showDrawerWithCapture()
        }
    }

    func showDrawer() {
        showDrawerWithCapture()
    }

    func hideDrawer() {
        drawerController.hide()
        drawerManager.hide()
        isDrawerVisible = false
    }

    private func setupDrawerBindings() {
        drawerManager.onVisibilityChanged = { [weak self] visible in
            self?.isDrawerVisible = visible
            if !visible {
                self?.drawerController.hide()
            }
        }
        
        drawerController.onVisibilityChanged = { [weak self] visible in
            self?.isDrawerVisible = visible
        }

        menuBarManager.onShowDrawer = { [weak self] in
            self?.showDrawerWithCapture()
        }
    }

    private func setupCapturerBindings() {
        iconCapturer.onCaptureCompleted = { [weak self] result in
            self?.drawerManager.updateItems(from: result)
            self?.isCapturing = false
        }
        
        iconCapturer.onCaptureStarted = { [weak self] in
            self?.isCapturing = true
        }
        
        iconCapturer.onCaptureError = { [weak self] error in
            self?.captureError = error
            self?.isCapturing = false
        }
    }

    private func setupHoverBindings() {
        logger.debug("setupHoverBindings() called")
        
        hoverManager.onShouldShowDrawer = { [weak self] screen in
            self?.showDrawerWithCapture(on: screen)
        }

        hoverManager.onShouldHideDrawer = { [weak self] in
            self?.hideDrawer()
        }

        // Subscribe to all gesture trigger setting changes
        // Monitor should run if ANY gesture trigger is enabled
        let anyGestureTriggerEnabled = Publishers.CombineLatest4(
            settings.showOnHoverSubject.prepend(settings.showOnHover),
            settings.showOnScrollDownSubject.prepend(settings.showOnScrollDown),
            settings.hideOnScrollUpSubject.prepend(settings.hideOnScrollUp),
            settings.hideOnClickOutsideSubject.prepend(settings.hideOnClickOutside)
        )
        .combineLatest(settings.hideOnMouseAwaySubject.prepend(settings.hideOnMouseAway))
        .map { combined, hideOnMouseAway in
            let (showOnHover, showOnScrollDown, hideOnScrollUp, hideOnClickOutside) = combined
            return showOnHover || showOnScrollDown || hideOnScrollUp || hideOnClickOutside || hideOnMouseAway
        }

        anyGestureTriggerEnabled
            .removeDuplicates()
            .sink { [weak self] enabled in
                if enabled {
                    self?.hoverManager.startMonitoring()
                } else {
                    self?.hoverManager.stopMonitoring()
                }
            }
            .store(in: &cancellables)

        // Start monitoring on init if any gesture trigger is enabled
        let shouldStart = settings.showOnHover || settings.showOnScrollDown || settings.hideOnScrollUp || settings.hideOnClickOutside || settings.hideOnMouseAway
        logger.debug("Checking hover monitoring: showOnHover=\(self.settings.showOnHover), showOnScrollDown=\(self.settings.showOnScrollDown), hideOnScrollUp=\(self.settings.hideOnScrollUp), hideOnClickOutside=\(self.settings.hideOnClickOutside), hideOnMouseAway=\(self.settings.hideOnMouseAway) -> shouldStart=\(shouldStart)")
        if shouldStart {
            logger.debug("Calling hoverManager.startMonitoring()")
            hoverManager.startMonitoring()
        }
    }

    func cleanup() {
        if let observer = menuBarFailureObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        cancellables.removeAll()
    }

    func showDrawerWithCapture(on screen: NSScreen? = nil) {
        Task {
            await captureAndShowDrawer(on: screen)
        }
    }

    func captureAndShowDrawer(on screen: NSScreen? = nil) async {
        #if DEBUG
        logger.debug("=== CAPTURE AND SHOW DRAWER (B2.3) ===")
        logger.debug("hasScreenRecording: \(self.permissions.hasScreenRecording)")
        #endif

        guard permissions.hasScreenRecording else {
            logger.warning("Screen recording permission not granted, requesting...")
            permissions.requestScreenRecording()
            return
        }

        drawerManager.setLoading(true)

        do {
            #if DEBUG
            logger.debug("Starting icon capture...")
            #endif

            let result = try await iconCapturer.captureHiddenIcons(menuBarManager: menuBarManager)

            #if DEBUG
            logger.debug("Capture succeeded: \(result.icons.count) icons")
            #endif

            drawerManager.updateItems(from: result)
            drawerManager.setLoading(false)

            let contentView = DrawerContentView(
                items: drawerManager.items,
                isLoading: false,
                onItemTap: { [weak self] item in
                    self?.handleItemTap(item)
                }
            )

            #if DEBUG
            logger.debug("Showing drawer panel with \(self.drawerManager.items.count) items")
            #endif

            let separatorX = menuBarManager.separatorXPosition
            drawerController.show(content: contentView, alignedTo: separatorX, on: screen)
            drawerManager.show()
            hoverManager.updateDrawerFrame(drawerController.panelFrame)

            #if DEBUG
            logger.debug("=== END CAPTURE AND SHOW DRAWER ===")
            #endif
        } catch {
            logger.error("Capture failed: \(error.localizedDescription)")
            drawerManager.setError(error)
            drawerManager.setLoading(false)
            captureError = error as? CaptureError

            let contentView = DrawerContentView(
                items: [],
                isLoading: false,
                error: error
            )
            let separatorX = menuBarManager.separatorXPosition
            drawerController.show(content: contentView, alignedTo: separatorX, on: screen)
            drawerManager.show()
        }
    }

    private func handleItemTap(_ item: DrawerItem) {
        Task {
            await performClickThrough(on: item)
        }
    }

    private func performClickThrough(on item: DrawerItem) async {
        logger.info("Click-through initiated for item at index \(item.index)")

        guard permissions.hasAccessibility else {
            logger.warning("Accessibility permission not granted, requesting...")
            permissions.requestAccessibility()
            return
        }

        hideDrawer()

        try? await Task.sleep(nanoseconds: 50_000_000)

        menuBarManager.expand()

        try? await Task.sleep(nanoseconds: 100_000_000)

        do {
            try await eventSimulator.simulateClick(at: item.clickTarget)
            logger.info("Click-through completed successfully")
        } catch {
            logger.error("Click-through failed: \(error.localizedDescription)")
        }
    }
}
