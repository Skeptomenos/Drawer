//
//  IconIdentifier.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import Foundation

// MARK: - IconIdentifier

/// A lightweight, persistable identifier for a menu bar icon.
/// Used to track icons across window list refreshes and for position persistence.
/// This type is used by the repositioning system (IconRepositioner).
struct IconIdentifier: Hashable, Codable, Equatable {

    // MARK: - Properties

    /// The namespace (typically bundle identifier) of the owning app.
    let namespace: String

    /// The title of the menu bar item window.
    let title: String

    // MARK: - Known Control Items

    /// Identifier for Drawer's hidden section control item (separator).
    static let hiddenControlItem = IconIdentifier(
        namespace: Bundle.main.bundleIdentifier ?? "com.drawer",
        title: "HiddenControlItem"
    )

    /// Identifier for Drawer's always-hidden section control item.
    static let alwaysHiddenControlItem = IconIdentifier(
        namespace: Bundle.main.bundleIdentifier ?? "com.drawer",
        title: "AlwaysHiddenControlItem"
    )

    // MARK: - Immovable Items

    /// System items that macOS does not allow to be repositioned.
    /// These are locked to specific positions in the menu bar by the system.
    static let immovableItems: Set<IconIdentifier> = [
        // Control Center items
        IconIdentifier(namespace: "com.apple.controlcenter", title: "BentoBox"),
        IconIdentifier(namespace: "com.apple.controlcenter", title: "Clock"),
        // Siri
        IconIdentifier(namespace: "com.apple.Siri", title: "Siri"),
        // Spotlight
        IconIdentifier(namespace: "com.apple.Spotlight", title: "Spotlight"),
    ]

    /// Returns true if this item is a system item that cannot be moved.
    var isImmovable: Bool {
        Self.immovableItems.contains(self)
    }
}
