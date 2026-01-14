//
//  MenuBarManager.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import Combine

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
    private var cancellables = Set<AnyCancellable>()
    private var autoCollapseTask: Task<Void, Never>?
    
    // MARK: - Constants
    
    private let separatorExpandedLength: CGFloat = 20
    private let separatorCollapsedLength: CGFloat = 10000
    private let debounceDelay: TimeInterval = 0.3
    
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
        NSImage(named: isLTRLanguage ? "ic_expand" : "ic_collapse")
    }
    
    private var collapseImage: NSImage? {
        NSImage(named: isLTRLanguage ? "ic_collapse" : "ic_expand")
    }
    
    private let separatorImage = NSImage(named: "ic_line")
    
    // MARK: - Initialization
    
    init(settings: SettingsManager = .shared) {
        self.settings = settings
        self.toggleItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.separatorItem = NSStatusBar.system.statusItem(withLength: 1)
        
        setupUI()
        setupSettingsBindings()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.collapse()
        }
    }
    
    private func setupSettingsBindings() {
        settings.autoCollapseSettingsChanged
            .sink { [weak self] in
                self?.restartAutoCollapseTimerIfNeeded()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        if let button = separatorItem.button {
            button.image = separatorImage
        }
        separatorItem.menu = createContextMenu()
        
        if let button = toggleItem.button {
            button.image = collapseImage
            button.target = self
            button.action = #selector(toggleButtonPressed)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        // Position persistence - using Hidden Bar names for migration compatibility
        toggleItem.autosaveName = "hiddenbar_expandcollapse"
        separatorItem.autosaveName = "hiddenbar_separate"
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
        guard let event = NSApp.currentEvent else { return }
        
        let isOptionKeyPressed = event.modifierFlags.contains(.option)
        
        if event.type == .leftMouseUp && !isOptionKeyPressed {
            toggle()
        }
    }
    
    @objc private func openPreferences() {
        if #available(macOS 13.0, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
    }
    
    // MARK: - Toggle Logic
    
    func toggle() {
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
        
        separatorItem.length = separatorExpandedLength
        toggleItem.button?.image = collapseImage
        isCollapsed = false
        
        startAutoCollapseTimer()
    }
    
    func collapse() {
        guard isSeparatorValidPosition, !isCollapsed else { return }
        
        cancelAutoCollapseTimer()
        separatorItem.length = separatorCollapsedLength
        toggleItem.button?.image = expandImage
        isCollapsed = true
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
