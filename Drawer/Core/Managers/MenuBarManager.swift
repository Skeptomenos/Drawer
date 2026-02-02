//
//  MenuBarManager.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import Combine
import os.log

// MARK: - MenuBarManager

@MainActor
@Observable
final class MenuBarManager {

    // MARK: - Callbacks

    @ObservationIgnored var onCollapsedChanged: ((Bool) -> Void)?

    // MARK: - Published State

    private(set) var isCollapsed: Bool = true {
        didSet {
            guard oldValue != isCollapsed else { return }
            onCollapsedChanged?(isCollapsed)
            updateSectionStateForCollapsed(isCollapsed)
        }
    }

    private func updateSectionStateForCollapsed(_ collapsed: Bool) {
        hiddenSection.isExpanded = !collapsed
        visibleSection.controlItem.image = collapsed ? expandImage : collapseImage
        logger.debug("State updated: isCollapsed=\(collapsed), separator length=\(self.hiddenSection.controlItem.length)")
    }
    private(set) var isToggling: Bool = false

    // MARK: - Sections

    /// The always-hidden section (optional, user-enabled)
    /// Icons in this section are never shown in the menu bar - only in the Drawer panel.
    private(set) var alwaysHiddenSection: MenuBarSection?

    /// The invisible spacer for always-hidden section (10k px, pushes icons off-screen)
    /// This is separate from the visible separator so the `≡` icon stays on-screen.
    private var alwaysHiddenSpacer: ControlItem?

    /// The hidden section (separator that expands to hide icons)
    /// Internal storage - use `hiddenSection` computed property for safe access.
    private var _hiddenSection: MenuBarSection?

    /// The visible section (toggle button)
    /// Internal storage - use `visibleSection` computed property for safe access.
    private var _visibleSection: MenuBarSection?

    /// The hidden section (separator that expands to hide icons).
    /// Accessing before `setupSections` completes is a programmer error.
    private(set) var hiddenSection: MenuBarSection {
        get {
            guard let section = _hiddenSection else {
                fatalError("hiddenSection accessed before setupSections completed. This is a programmer error.")
            }
            return section
        }
        set { _hiddenSection = newValue }
    }

    /// The visible section (toggle button).
    /// Accessing before `setupSections` completes is a programmer error.
    private(set) var visibleSection: MenuBarSection {
        get {
            guard let section = _visibleSection else {
                fatalError("visibleSection accessed before setupSections completed. This is a programmer error.")
            }
            return section
        }
        set { _visibleSection = newValue }
    }

    /// All active sections including optional always-hidden
    private var sections: [MenuBarSection] {
        [alwaysHiddenSection, hiddenSection, visibleSection].compactMap { $0 }
    }

    // MARK: - Legacy Accessors (for backward compatibility)

    /// Exposes the separator's control item for legacy code
    var separatorControlItem: ControlItem {
        hiddenSection.controlItem
    }

    /// Exposes the toggle's control item for legacy code
    var toggleControlItem: ControlItem {
        visibleSection.controlItem
    }

    // MARK: - Dependencies

    @ObservationIgnored private let settings: SettingsManager
    @ObservationIgnored private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.drawer", category: "MenuBarManager")
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()
    @ObservationIgnored private var autoCollapseTask: Task<Void, Never>?
    @ObservationIgnored private var toggleDebounceTask: Task<Void, Never>?

    // MARK: - Constants

    private let separatorExpandedLength: CGFloat = 20
    private let separatorCollapsedLength: CGFloat = 10000
    private let debounceDelay: TimeInterval = 0.3
    private let maxRetryAttempts = 3
    private let retryDelayNanoseconds: UInt64 = 200_000_000  // 200ms

    // MARK: - Test Accessors

    /// Exposes the current separator length for testing purposes.
    var currentSeparatorLength: CGFloat {
        hiddenSection.controlItem.length
    }

    var separatorXPosition: CGFloat? {
        hiddenSection.controlItem.button?.window?.frame.origin.x
    }

    /// Exposes the current toggle button image accessibility description for testing purposes.
    var currentToggleImageDescription: String? {
        visibleSection.controlItem.button?.image?.accessibilityDescription
    }

    /// Exposes the expected expand image symbol name for testing purposes.
    var expandImageSymbolName: String {
        isLTRLanguage ? "chevron.left" : "chevron.right"
    }

    /// Exposes the expected collapse image symbol name for testing purposes.
    var collapseImageSymbolName: String {
        isLTRLanguage ? "chevron.right" : "chevron.left"
    }

    /// Exposes whether the current layout is LTR for testing purposes.
    var isLeftToRight: Bool {
        isLTRLanguage
    }

    // MARK: - RTL Support

    private var isLTRLanguage: Bool {
        NSApplication.shared.userInterfaceLayoutDirection == .leftToRight
    }

    /// Validates separator position relative to toggle button.
    /// In LTR: toggle must be >= separator X. In RTL: toggle must be <= separator X.
    /// Prevents 10k hack from triggering when items are in invalid configurations.
    private var isSeparatorValidPosition: Bool {
        guard
            let toggleX = visibleSection.controlItem.button?.window?.frame.origin.x,
            let separatorX = hiddenSection.controlItem.button?.window?.frame.origin.x
        else { return false }

        return isLTRLanguage ? (toggleX >= separatorX) : (toggleX <= separatorX)
    }

    // MARK: - Images (RTL-aware)

    private var expandImage: ControlItemImage {
        .sfSymbol(isLTRLanguage ? "chevron.left" : "chevron.right")
    }

    private var collapseImage: ControlItemImage {
        .sfSymbol(isLTRLanguage ? "chevron.right" : "chevron.left")
    }

    private let separatorImage: ControlItemImage = .sfSymbol("circle.fill", weight: .regular)
    private let alwaysHiddenSeparatorImage: ControlItemImage = .sfSymbol("line.3.horizontal", weight: .regular)

    // MARK: - Callbacks

    /// Callback invoked when the toggle button is pressed.
    /// AppState uses this to decide between expand mode and overlay mode.
    var onTogglePressed: (() -> Void)?

    /// Callback invoked when the drawer should be shown.
    var onShowDrawer: (() -> Void)?

    // MARK: - Initialization

    #if DEBUG
    private var debugTimer: Timer?
    #endif

    init(settings: SettingsManager = .shared) {
        self.settings = settings

        setupSections(attempt: 1)
        setupAlwaysHiddenSection()
        setupSettingsBindings()

        logger.debug("Initialized with section-based architecture")

        #if DEBUG
        setupDebugTimer()
        #endif
    }

    func cleanup() {
        #if DEBUG
        debugTimer?.invalidate()
        #endif
        autoCollapseTask?.cancel()
        toggleDebounceTask?.cancel()
        cancellables.removeAll()
    }

    // MARK: - Setup

    /// Creates the menu bar sections with their control items.
    /// The hidden section manages the separator (10k pixel hack).
    /// The visible section manages the toggle button.
    ///
    /// IMPORTANT: Toggle MUST be created BEFORE Separator.
    /// macOS places new NSStatusItems to the LEFT of existing items.
    /// Creating Toggle first ensures layout: [Separator] [Toggle]
    /// This keeps Toggle visible when Separator expands to 10k pixels.
    private func setupSections(attempt: Int) {
        // Create toggle control item FIRST (for visible section)
        // This ensures Toggle is placed rightmost, staying visible when Separator expands.
        let toggleControl = ControlItem(
            expandedLength: NSStatusItem.variableLength,
            collapsedLength: NSStatusItem.variableLength,
            initialState: .expanded  // Toggle is always visible
        )

        guard toggleControl.button != nil else {
            handleSetupFailure(component: "toggleControl.button", attempt: attempt)
            return
        }

        toggleControl.image = isCollapsed ? expandImage : collapseImage
        toggleControl.autosaveName = "drawer_toggle_v4"
        toggleControl.setAction(target: self, action: #selector(toggleButtonPressed))
        toggleControl.setSendAction(on: [.leftMouseUp, .rightMouseUp])

        visibleSection = MenuBarSection(
            type: .visible,
            controlItem: toggleControl,
            isExpanded: true  // Toggle section is always expanded
        )

        // Create separator control item SECOND (for hidden section)
        // This places Separator to the LEFT of Toggle.
        let separatorControl = ControlItem(
            expandedLength: separatorExpandedLength,
            collapsedLength: separatorCollapsedLength,
            initialState: isCollapsed ? .collapsed : .expanded
        )

        guard separatorControl.button != nil else {
            handleSetupFailure(component: "separatorControl.button", attempt: attempt)
            return
        }

        separatorControl.image = separatorImage
        separatorControl.autosaveName = "drawer_separator_v4"
        separatorControl.setMenu(createContextMenu())

        hiddenSection = MenuBarSection(
            type: .hidden,
            controlItem: separatorControl,
            isExpanded: !isCollapsed
        )

        logger.info("Sections setup complete on attempt \(attempt)")

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 100_000_000)
            self.verifyVisibility()
        }
    }

    /// Sets up or tears down the always-hidden section based on settings.
    ///
    /// Uses a TWO-ITEM approach to solve the visibility bug:
    /// 1. Invisible Spacer (10k px) - pushes icons off-screen, created LAST (leftmost)
    /// 2. Visible Separator (20px) - shows `≡` icon, user can interact with it
    ///
    /// Layout: [Spacer 10k] [≡ 20px] [Hidden Icons] [● 20px] [< Toggle]
    ///
    /// The spacer has no icon and exists purely to push always-hidden icons off-screen.
    /// The separator shows `≡` and is always visible when the feature is enabled.
    private func setupAlwaysHiddenSection() {
        guard settings.alwaysHiddenSectionEnabled else {
            // Remove section and spacer if disabled
            if alwaysHiddenSection != nil || alwaysHiddenSpacer != nil {
                alwaysHiddenSection?.isEnabled = false
                alwaysHiddenSection = nil
                alwaysHiddenSpacer?.state = .hidden
                alwaysHiddenSpacer = nil
                logger.info("Always Hidden section disabled")
            }
            return
        }

        guard alwaysHiddenSection == nil else { return }

        // STEP 1: Create the VISIBLE separator (20px, shows ≡ icon)
        // Created FIRST so it appears to the RIGHT of the spacer
        let alwaysHiddenControl = ControlItem(
            expandedLength: separatorExpandedLength,
            collapsedLength: separatorExpandedLength,  // Always 20px (never collapses)
            initialState: .expanded  // Always visible at 20px
        )

        guard alwaysHiddenControl.button != nil else {
            logger.error("Failed to create always-hidden section: separator button is nil")
            return
        }

        alwaysHiddenControl.image = alwaysHiddenSeparatorImage
        alwaysHiddenControl.autosaveName = "drawer_always_hidden_separator_v2"
        alwaysHiddenControl.setMenu(createContextMenu())

        alwaysHiddenSection = MenuBarSection(
            type: .alwaysHidden,
            controlItem: alwaysHiddenControl,
            isExpanded: true,  // Always expanded (visible at 20px)
            isEnabled: true
        )

        // STEP 2: Create the INVISIBLE spacer (10k px, no icon)
        // Created SECOND so it appears to the LEFT of the separator
        // This pushes always-hidden icons off-screen
        let spacer = ControlItem(
            expandedLength: separatorCollapsedLength,  // 10k px (always pushing)
            collapsedLength: separatorCollapsedLength,
            initialState: .expanded  // Always at 10k px
        )

        guard spacer.button != nil else {
            logger.error("Failed to create always-hidden section: spacer button is nil")
            // Clean up the separator we already created
            alwaysHiddenSection?.isEnabled = false
            alwaysHiddenSection = nil
            return
        }
        
        // No image - this is an invisible spacer
        spacer.autosaveName = "drawer_always_hidden_spacer_v2"
        alwaysHiddenSpacer = spacer
        
        // Verify layout by logging positions after window creation settles
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000)
            if let spacerWindow = spacer.button?.window, let ctrlWindow = alwaysHiddenControl.button?.window {
                self.logger.debug("Always Hidden Setup: Spacer X=\(spacerWindow.frame.origin.x), Ctrl X=\(ctrlWindow.frame.origin.x)")
                self.logger.debug("Spacer Width: \(spacerWindow.frame.width), Ctrl Width: \(ctrlWindow.frame.width)")
            } else {
                self.logger.error("Could not get window frames for Always Hidden section")
            }
        }
        
        logger.info("Always Hidden section enabled and setup")
    }

    private func handleSetupFailure(component: String, attempt: Int) {
        if attempt < maxRetryAttempts {
            logger.warning("\(component) is nil on attempt \(attempt)/\(self.maxRetryAttempts). Retrying...")
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: retryDelayNanoseconds)
                self.setupSections(attempt: attempt + 1)
            }
        } else {
            logger.error("CRITICAL: \(component) is nil after \(self.maxRetryAttempts) attempts. Menu bar icons will not appear.")
            NotificationCenter.default.post(name: .menuBarSetupFailed, object: nil)
        }
    }

    private func setupSettingsBindings() {
        settings.autoCollapseSettingsChanged
            .sink { [weak self] in
                self?.restartAutoCollapseTimerIfNeeded()
            }
            .store(in: &cancellables)

        settings.alwaysHiddenSettingsChanged
            .sink { [weak self] in
                self?.setupAlwaysHiddenSection()
            }
            .store(in: &cancellables)
    }



    #if DEBUG
    private func setupDebugTimer() {
        debugTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.logger.debug("--- SECTION DEBUG ---")
                self.logger.debug("Hidden: expanded=\(self.hiddenSection.isExpanded), length=\(self.hiddenSection.controlItem.length)")
                self.logger.debug("Visible: expanded=\(self.visibleSection.isExpanded)")
                if let toggleBtn = self.visibleSection.controlItem.button {
                    let frame = toggleBtn.window?.frame ?? .zero
                    self.logger.debug("Toggle: Frame=\(NSStringFromRect(frame)), Alpha=\(toggleBtn.alphaValue)")
                }
                if let sepBtn = self.hiddenSection.controlItem.button {
                    let frame = sepBtn.window?.frame ?? .zero
                    self.logger.debug("Separator: Frame=\(NSStringFromRect(frame)), Alpha=\(sepBtn.alphaValue)")
                }
                self.logger.debug("---------------------")
            }
        }
    }
    #endif

    private func verifyVisibility() {
        let toggleVisible = visibleSection.controlItem.button?.window?.frame.width ?? 0 > 0
        let separatorVisible = hiddenSection.controlItem.button?.window?.frame.width ?? 0 > 0

        if toggleVisible && separatorVisible {
            logger.info("Menu bar icons verified visible")
        } else {
            logger.warning("Visibility check failed. Toggle: \(toggleVisible), Separator: \(separatorVisible)")
        }
    }

    private func createContextMenu() -> NSMenu {
        let menu = NSMenu()

        let drawerItem = NSMenuItem(
            title: "Show Drawer",
            action: #selector(showDrawerPressed),
            keyEquivalent: "d"
        )
        drawerItem.target = self
        menu.addItem(drawerItem)

        menu.addItem(NSMenuItem.separator())

        let preferencesItem = NSMenuItem(
            title: "Preferences...",
            action: #selector(openPreferences),
            keyEquivalent: ","
        )
        preferencesItem.target = self
        menu.addItem(preferencesItem)

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(
            title: "Quit Drawer",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))

        return menu
    }

    // MARK: - Actions

    @objc private func toggleButtonPressed(_ sender: NSStatusBarButton) {
        logger.debug("Toggle Button Pressed")
        guard let event = NSApp.currentEvent else { return }

        let isOptionKeyPressed = event.modifierFlags.contains(.option)

        if event.type == .leftMouseUp && !isOptionKeyPressed {
            // Delegate to AppState which decides expand vs overlay mode
            if let callback = onTogglePressed {
                callback()
            } else {
                // Fallback: direct toggle (for standalone usage)
                toggle()
            }
        }
    }

    @objc private func showDrawerPressed() {
        onShowDrawer?()
    }

    @objc private func openPreferences() {
        AppDelegate.shared?.openSettings()
    }

    // MARK: - Toggle Logic

    func toggle() {
        logger.debug("toggle() called. isToggling: \(self.isToggling), isCollapsed: \(self.isCollapsed)")
        guard !isToggling else { return }
        isToggling = true

        if isCollapsed {
            expand()
        } else {
            collapse()
        }

        // Cancel any previous debounce task and start a new one
        // This uses Task + Task.sleep instead of DispatchQueue.main.asyncAfter per CONC-001
        toggleDebounceTask?.cancel()
        toggleDebounceTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(self?.debounceDelay ?? 0.3))
            guard !Task.isCancelled else { return }
            self?.isToggling = false
        }
    }

    func expand() {
        guard isCollapsed else { return }
        logger.debug("Expanding...")

        // Reactive binding handles section state and toggle image via setupStateBindings()
        isCollapsed = false

        startAutoCollapseTimer()
        logger.debug("Expanded. Separator Length: \(self.hiddenSection.controlItem.length)")
    }

    func collapse() {
        guard isSeparatorValidPosition, !isCollapsed else {
            logger.debug("Collapse aborted. ValidPos: \(self.isSeparatorValidPosition), IsCollapsed: \(self.isCollapsed)")
            return
        }
        logger.debug("Collapsing...")

        cancelAutoCollapseTimer()
        // Reactive binding handles section state and toggle image via setupStateBindings()
        isCollapsed = true
        logger.debug("Collapsed. Separator Length: \(self.hiddenSection.controlItem.length)")
    }

    // MARK: - Auto-Collapse Timer

    private func startAutoCollapseTimer() {
        guard settings.autoCollapseEnabled else { return }

        cancelAutoCollapseTimer()

        let delay = settings.autoCollapseDelay
        autoCollapseTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            self?.collapse()
        }
    }

    private func cancelAutoCollapseTimer() {
        autoCollapseTask?.cancel()
        autoCollapseTask = nil
    }

    private func restartAutoCollapseTimerIfNeeded() {
        guard !isCollapsed else { return }
        startAutoCollapseTimer()
    }
}
