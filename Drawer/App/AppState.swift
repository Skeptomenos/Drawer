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
final class AppState: ObservableObject {

    @Published var isCollapsed: Bool = true
    @Published private(set) var isDrawerVisible: Bool = false
    @Published private(set) var hasRequiredPermissions: Bool = false
    @Published private(set) var isCapturing: Bool = false
    @Published private(set) var captureError: CaptureError?

    let menuBarManager: MenuBarManager
    let settings: SettingsManager
    let permissions: PermissionManager
    let drawerController: DrawerPanelController
    let drawerManager: DrawerManager
    let iconCapturer: IconCapturer
    let eventSimulator: EventSimulator
    let hoverManager: HoverManager
    let overlayModeManager: OverlayModeManager

    static let shared = AppState()

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.drawer", category: "AppState")
    private var cancellables = Set<AnyCancellable>()

    var hasCompletedOnboarding: Bool {
        get { settings.hasCompletedOnboarding }
        set { settings.hasCompletedOnboarding = newValue }
    }

    init(
        settings: SettingsManager = .shared,
        permissions: PermissionManager = .shared,
        drawerManager: DrawerManager = .shared,
        iconCapturer: IconCapturer = .shared,
        eventSimulator: EventSimulator = .shared,
        hoverManager: HoverManager = .shared
    ) {
        self.settings = settings
        self.permissions = permissions
        self.drawerManager = drawerManager
        self.iconCapturer = iconCapturer
        self.eventSimulator = eventSimulator
        self.hoverManager = hoverManager
        self.menuBarManager = MenuBarManager(settings: settings)
        self.drawerController = DrawerPanelController()

        // Initialize overlay mode manager for alternative display mode
        self.overlayModeManager = OverlayModeManager(
            settings: settings,
            iconCapturer: iconCapturer,
            eventSimulator: eventSimulator,
            menuBarManager: menuBarManager
        )

        // Using assign(to:) with &$ is safe - no retain cycle created
        // See: https://developer.apple.com/documentation/combine/publisher/assign(to:)
        menuBarManager.$isCollapsed
            .assign(to: &$isCollapsed)

        setupPermissionBindings()
        setupDrawerBindings()
        setupCapturerBindings()
        setupHoverBindings()
        setupMenuBarFailureObserver()
        setupToggleCallback()
    }

    private func setupMenuBarFailureObserver() {
        NotificationCenter.default.addObserver(
            forName: .menuBarSetupFailed,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.logger.error("Menu bar setup failed after all retry attempts")
        }
    }

    private func setupPermissionBindings() {
        permissions.permissionStatusChanged
            .sink { [weak self] in
                self?.hasRequiredPermissions = self?.permissions.hasAllPermissions ?? false
            }
            .store(in: &cancellables)

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
        drawerController.$isVisible
            .assign(to: &$isDrawerVisible)

        drawerManager.$isVisible
            .sink { [weak self] visible in
                if !visible {
                    self?.drawerController.hide()
                }
            }
            .store(in: &cancellables)

        menuBarManager.onShowDrawer = { [weak self] in
            self?.showDrawerWithCapture()
        }
    }

    private func setupCapturerBindings() {
        iconCapturer.$isCapturing
            .assign(to: &$isCapturing)

        iconCapturer.$lastError
            .assign(to: &$captureError)

        iconCapturer.$lastCaptureResult
            .compactMap { $0 }
            .sink { [weak self] result in
                self?.drawerManager.updateItems(from: result)
            }
            .store(in: &cancellables)
    }

    private func setupHoverBindings() {
        // Callbacks from HoverManager - no need to check settings here
        // HoverManager already checks the appropriate setting for each trigger type
        hoverManager.onShouldShowDrawer = { [weak self] in
            self?.showDrawerWithCapture()
        }

        hoverManager.onShouldHideDrawer = { [weak self] in
            self?.hideDrawer()
        }

        $isDrawerVisible
            .sink { [weak self] visible in
                self?.hoverManager.setDrawerVisible(visible)
            }
            .store(in: &cancellables)

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
        if settings.showOnHover || settings.showOnScrollDown || settings.hideOnScrollUp || settings.hideOnClickOutside || settings.hideOnMouseAway {
            hoverManager.startMonitoring()
        }
    }

    deinit {
        cancellables.removeAll()
    }

    func showDrawerWithCapture() {
        Task {
            await captureAndShowDrawer()
        }
    }

    func captureAndShowDrawer() async {
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

            drawerController.show(content: contentView)
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
            drawerController.show(content: contentView)
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
