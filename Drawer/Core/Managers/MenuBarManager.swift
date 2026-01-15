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
@MainActor
final class MenuBarManager: ObservableObject {
    
    // MARK: - Published State
    
    @Published private(set) var isCollapsed: Bool = true
    @Published private(set) var isToggling: Bool = false
    
    // MARK: - Status Bar Items
    
    private let toggleItem: NSStatusItem
    private let separatorItem: NSStatusItem
    
    // MARK: - Dependencies
    
    private let settings: SettingsManager
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.drawer", category: "MenuBarManager")
    private var cancellables = Set<AnyCancellable>()
    private var autoCollapseTask: Task<Void, Never>?
    
    // MARK: - Constants
    
    private let separatorExpandedLength: CGFloat = 20
    private let separatorCollapsedLength: CGFloat = 10000
    
    /// Exposes the current separator length for testing purposes.
    var currentSeparatorLength: CGFloat {
        separatorItem.length
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
    private let debounceDelay: TimeInterval = 0.3
    private let maxRetryAttempts = 3
    private let retryDelayNanoseconds: UInt64 = 200_000_000  // 200ms
    
    // MARK: - RTL Support
    
    private var isLTRLanguage: Bool {
        NSApplication.shared.userInterfaceLayoutDirection == .leftToRight
    }
    
    /// Validates separator position relative to toggle button.
    /// In LTR: toggle must be >= separator X. In RTL: toggle must be <= separator X.
    /// Prevents 10k hack from triggering when items are in invalid configurations.
    private var isSeparatorValidPosition: Bool {
        guard
            let toggleX = toggleItem.button?.window?.frame.origin.x,
            let separatorX = separatorItem.button?.window?.frame.origin.x
        else { return false }
        
        return isLTRLanguage ? (toggleX >= separatorX) : (toggleX <= separatorX)
    }
    
    // MARK: - Images (RTL-aware)
    
    private var expandImage: NSImage? {
        return NSImage(systemSymbolName: isLTRLanguage ? "chevron.left" : "chevron.right", accessibilityDescription: "Expand")
    }
    
    private var collapseImage: NSImage? {
        return NSImage(systemSymbolName: isLTRLanguage ? "chevron.right" : "chevron.left", accessibilityDescription: "Collapse")
    }
    
    private let separatorImage = NSImage(systemSymbolName: "circle.fill", accessibilityDescription: "Separator")
    
    // MARK: - Initialization
    
    #if DEBUG
    private var debugTimer: Timer?
    #endif

    init(settings: SettingsManager = .shared) {
        self.settings = settings
        self.toggleItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.separatorItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        setupUI(attempt: 1)
        setupSettingsBindings()
        
        logger.debug("Initialized. Toggle button: \(String(describing: self.toggleItem.button)), Separator button: \(String(describing: self.separatorItem.button))")
        
        #if DEBUG
        // Debug Timer to monitor status items (DEBUG only)
        debugTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.logger.debug("--- STATUS ITEM DEBUG ---")
                if let toggleBtn = self.toggleItem.button {
                    let frame = toggleBtn.window?.frame ?? .zero
                    self.logger.debug("Toggle: Frame=\(NSStringFromRect(frame)), Alpha=\(toggleBtn.alphaValue), Hidden=\(toggleBtn.isHidden)")
                } else {
                    self.logger.debug("Toggle: NO BUTTON")
                }
                
                if let sepBtn = self.separatorItem.button {
                    let frame = sepBtn.window?.frame ?? .zero
                    self.logger.debug("Separator: Frame=\(NSStringFromRect(frame)), Length=\(self.separatorItem.length), Alpha=\(sepBtn.alphaValue)")
                } else {
                    self.logger.debug("Separator: NO BUTTON")
                }
                self.logger.debug("-------------------------")
            }
        }
        #endif
    }
    
    deinit {
        #if DEBUG
        debugTimer?.invalidate()
        #endif
        autoCollapseTask?.cancel()
        cancellables.removeAll()
    }
    
    private func setupSettingsBindings() {
        settings.autoCollapseSettingsChanged
            .sink { [weak self] in
                self?.restartAutoCollapseTimerIfNeeded()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Setup
    
    private func setupUI(attempt: Int) {
        guard let toggleButton = toggleItem.button else {
            handleSetupFailure(component: "toggleItem.button", attempt: attempt)
            return
        }
        
        guard let separatorButton = separatorItem.button else {
            handleSetupFailure(component: "separatorItem.button", attempt: attempt)
            return
        }
        
        separatorButton.title = ""
        separatorButton.image = separatorImage ?? NSImage(named: NSImage.touchBarHistoryTemplateName)
        separatorButton.imagePosition = .imageOnly
        separatorItem.length = separatorExpandedLength
        separatorItem.menu = createContextMenu()
        separatorItem.autosaveName = "drawer_separator_v3"
        
        toggleButton.title = ""
        toggleButton.image = collapseImage ?? NSImage(named: NSImage.touchBarGoForwardTemplateName)
        toggleButton.target = self
        toggleButton.action = #selector(toggleButtonPressed)
        toggleButton.sendAction(on: [.leftMouseUp, .rightMouseUp])
        toggleButton.imagePosition = .imageOnly
        toggleItem.autosaveName = "drawer_toggle_v3"
        
        logger.info("Menu bar UI setup complete on attempt \(attempt)")
        
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 100_000_000)
            self.verifyVisibility()
        }
    }
    
    private func handleSetupFailure(component: String, attempt: Int) {
        if attempt < maxRetryAttempts {
            logger.warning("\(component) is nil on attempt \(attempt)/\(self.maxRetryAttempts). Retrying...")
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: retryDelayNanoseconds)
                self.setupUI(attempt: attempt + 1)
            }
        } else {
            logger.error("CRITICAL: \(component) is nil after \(self.maxRetryAttempts) attempts. Menu bar icons will not appear.")
            NotificationCenter.default.post(name: .menuBarSetupFailed, object: nil)
        }
    }
    
    private func verifyVisibility() {
        let toggleVisible = toggleItem.button?.window?.frame.width ?? 0 > 0
        let separatorVisible = separatorItem.button?.window?.frame.width ?? 0 > 0
        
        if toggleVisible && separatorVisible {
            logger.info("Menu bar icons verified visible")
        } else {
            logger.warning("Menu bar visibility check failed. Toggle: \(toggleVisible), Separator: \(separatorVisible)")
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
    
    var onShowDrawer: (() -> Void)?
    
    @objc private func showDrawerPressed() {
        onShowDrawer?()
    }
    
    // MARK: - Actions
    
    @objc private func toggleButtonPressed(_ sender: NSStatusBarButton) {
        logger.debug("Toggle Button Pressed")
        guard let event = NSApp.currentEvent else { return }
        
        let isOptionKeyPressed = event.modifierFlags.contains(.option)
        
        if event.type == .leftMouseUp && !isOptionKeyPressed {
            toggle()
        }
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
        
        separatorItem.length = separatorExpandedLength
        toggleItem.button?.image = collapseImage
        isCollapsed = false
        
        startAutoCollapseTimer()
        logger.debug("Expanded. Separator Length: \(self.separatorItem.length)")
    }
    
    func collapse() {
        guard isSeparatorValidPosition, !isCollapsed else {
            logger.debug("Collapse aborted. ValidPos: \(self.isSeparatorValidPosition), IsCollapsed: \(self.isCollapsed)")
            return
        }
        logger.debug("Collapsing...")
        
        cancelAutoCollapseTimer()
        separatorItem.length = separatorCollapsedLength
        toggleItem.button?.image = expandImage
        isCollapsed = true
        logger.debug("Collapsed. Separator Length: \(self.separatorItem.length)")
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
