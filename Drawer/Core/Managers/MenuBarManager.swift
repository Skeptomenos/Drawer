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

/// Implements the "10k pixel hack" - hides menu bar icons by expanding a separator to 10,000px,
/// pushing icons off-screen. This is the HEART of the app.
///
/// Architecture: Uses a section-based design with `MenuBarSection` objects wrapping `ControlItem`s.
/// This prepares for future features like "Always Hidden" section while maintaining backward compatibility.
@MainActor
final class MenuBarManager: ObservableObject {

    // MARK: - Published State

    @Published private(set) var isCollapsed: Bool = true
    @Published private(set) var isToggling: Bool = false

    // MARK: - Sections

    /// The always-hidden section (optional, user-enabled)
    /// Icons in this section are never shown in the menu bar - only in the Drawer panel.
    private(set) var alwaysHiddenSection: MenuBarSection?

    /// The hidden section (separator that expands to hide icons)
    private(set) var hiddenSection: MenuBarSection!

    /// The visible section (toggle button)
    private(set) var visibleSection: MenuBarSection!

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

    private let settings: SettingsManager
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.drawer", category: "MenuBarManager")
    private var cancellables = Set<AnyCancellable>()
    private var autoCollapseTask: Task<Void, Never>?

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
        setupStateBindings()

        logger.debug("Initialized with section-based architecture")

        #if DEBUG
        setupDebugTimer()
        #endif
    }

    deinit {
        #if DEBUG
        debugTimer?.invalidate()
        #endif
        autoCollapseTask?.cancel()
        cancellables.removeAll()
    }

    // MARK: - Setup

    /// Creates the menu bar sections with their control items.
    /// The hidden section manages the separator (10k pixel hack).
    /// The visible section manages the toggle button.
    private func setupSections(attempt: Int) {
        // Create separator control item (for hidden section)
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
        separatorControl.autosaveName = "drawer_separator_v3"
        separatorControl.setMenu(createContextMenu())

        hiddenSection = MenuBarSection(
            type: .hidden,
            controlItem: separatorControl,
            isExpanded: !isCollapsed
        )

        // Create toggle control item (for visible section)
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
        toggleControl.autosaveName = "drawer_toggle_v3"
        toggleControl.setAction(target: self, action: #selector(toggleButtonPressed))
        toggleControl.setSendAction(on: [.leftMouseUp, .rightMouseUp])

        visibleSection = MenuBarSection(
            type: .visible,
            controlItem: toggleControl,
            isExpanded: true  // Toggle section is always expanded
        )

        logger.info("Sections setup complete on attempt \(attempt)")

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 100_000_000)
            self.verifyVisibility()
        }
    }

    /// Sets up or tears down the always-hidden section based on settings.
    /// The always-hidden section stays at 10k pixels permanently - icons to its left
    /// are only visible in the Drawer panel.
    private func setupAlwaysHiddenSection() {
        guard settings.alwaysHiddenSectionEnabled else {
            // Remove section if disabled
            if alwaysHiddenSection != nil {
                alwaysHiddenSection?.isEnabled = false
                alwaysHiddenSection = nil
                logger.info("Always Hidden section disabled")
            }
            return
        }

        guard alwaysHiddenSection == nil else { return }

        // Create always-hidden control item
        let alwaysHiddenControl = ControlItem(
            expandedLength: separatorExpandedLength,
            collapsedLength: separatorCollapsedLength,
            initialState: .collapsed  // Always stays collapsed (10k pixels)
        )

        guard alwaysHiddenControl.button != nil else {
            logger.error("Failed to create always-hidden section: button is nil")
            return
        }

        alwaysHiddenControl.image = alwaysHiddenSeparatorImage
        alwaysHiddenControl.autosaveName = "drawer_always_hidden_v1"
        alwaysHiddenControl.setMenu(createContextMenu())

        alwaysHiddenSection = MenuBarSection(
            type: .alwaysHidden,
            controlItem: alwaysHiddenControl,
            isExpanded: false,  // Never expands
            isEnabled: true
        )

        logger.info("Always Hidden section enabled")
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

    /// Reactive binding: changes to `isCollapsed` automatically update section state and toggle image.
    /// This eliminates manual synchronization in expand()/collapse() methods and prevents desync bugs.
    /// See: specs/phase1-reactive-state-binding.md
    private func setupStateBindings() {
        $isCollapsed
            .dropFirst()  // Skip initial value (already handled in setupSections)
            .sink { [weak self] collapsed in
                guard let self = self else { return }
                // Update hidden section's expanded state
                self.hiddenSection.isExpanded = !collapsed
                // Note: alwaysHiddenSection stays collapsed (never expands) - no update needed
                // Update toggle button image
                self.visibleSection.controlItem.image = collapsed
                    ? self.expandImage
                    : self.collapseImage
                self.logger.debug("State binding triggered: isCollapsed=\(collapsed), separator length=\(self.hiddenSection.controlItem.length)")
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

        DispatchQueue.main.asyncAfter(deadline: .now() + debounceDelay) { [weak self] in
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
            await self?.collapse()
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
