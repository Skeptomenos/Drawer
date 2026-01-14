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
    
    // MARK: - Constants
    
    private let separatorExpandedLength: CGFloat = 20
    private let separatorCollapsedLength: CGFloat = 10000  // The "10k pixel hack"
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
    
    init() {
        self.toggleItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.separatorItem = NSStatusBar.system.statusItem(withLength: 1)
        
        setupUI()
        
        // Delay collapse to allow menu bar to settle (matches original Hidden Bar behavior)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.collapse()
        }
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
    }
    
    func collapse() {
        guard isSeparatorValidPosition, !isCollapsed else { return }
        
        separatorItem.length = separatorCollapsedLength
        toggleItem.button?.image = expandImage
        isCollapsed = true
    }
}
