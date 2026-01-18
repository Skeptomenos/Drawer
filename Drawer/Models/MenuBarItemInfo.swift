//
//  MenuBarItemInfo.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import Foundation

// MARK: - MenuBarItemInfo

/// A lightweight identifier for a menu bar item.
/// Used to track items across window list refreshes and for persistence.
struct MenuBarItemInfo: Hashable, Codable, Equatable {

    // MARK: - Properties

    /// The namespace (typically bundle identifier) of the owning app.
    let namespace: String

    /// The title of the menu bar item window.
    let title: String

    // MARK: - Known Control Items

    /// Identifier for Drawer's hidden section control item (separator).
    static let hiddenControlItem = MenuBarItemInfo(
        namespace: Bundle.main.bundleIdentifier ?? "com.drawer",
        title: "HiddenControlItem"
    )

    /// Identifier for Drawer's always-hidden section control item.
    static let alwaysHiddenControlItem = MenuBarItemInfo(
        namespace: Bundle.main.bundleIdentifier ?? "com.drawer",
        title: "AlwaysHiddenControlItem"
    )

    // MARK: - Immovable Items

    /// System items that macOS does not allow to be repositioned.
    /// These are locked to specific positions in the menu bar by the system.
    static let immovableItems: Set<MenuBarItemInfo> = [
        // Control Center items
        MenuBarItemInfo(namespace: "com.apple.controlcenter", title: "BentoBox"),
        MenuBarItemInfo(namespace: "com.apple.controlcenter", title: "Clock"),
        // Siri
        MenuBarItemInfo(namespace: "com.apple.Siri", title: "Siri"),
        // Spotlight
        MenuBarItemInfo(namespace: "com.apple.Spotlight", title: "Spotlight"),
    ]

    /// Returns true if this item is a system item that cannot be moved.
    var isImmovable: Bool {
        Self.immovableItems.contains(self)
    }
}
