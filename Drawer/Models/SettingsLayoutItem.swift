//
//  SettingsLayoutItem.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import CoreTransferable
import Foundation
import UniformTypeIdentifiers

// MARK: - SettingsLayoutItemType

/// The type of item that can appear in the settings layout.
///
/// Menu bar items are identified by their owning application's bundle identifier
/// and optional title. Spacers are synthetic items created by the user.
enum SettingsLayoutItemType: Codable, Equatable, Hashable {
    /// A real menu bar item from an application.
    /// - Parameters:
    ///   - bundleIdentifier: The bundle ID of the owning application (e.g., "com.apple.controlcenter")
    ///   - title: Optional window/item title for disambiguation when an app has multiple items
    case menuBarItem(bundleIdentifier: String, title: String?)

    /// A spacer item (flexible space between icons).
    /// - Parameter id: Unique identifier for this spacer instance
    case spacer(id: UUID)

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case type
        case bundleIdentifier
        case title
        case spacerId
    }

    private enum ItemTypeValue: String, Codable {
        case menuBarItem
        case spacer
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ItemTypeValue.self, forKey: .type)

        switch type {
        case .menuBarItem:
            let bundleId = try container.decode(String.self, forKey: .bundleIdentifier)
            let title = try container.decodeIfPresent(String.self, forKey: .title)
            self = .menuBarItem(bundleIdentifier: bundleId, title: title)
        case .spacer:
            let spacerId = try container.decode(UUID.self, forKey: .spacerId)
            self = .spacer(id: spacerId)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .menuBarItem(let bundleIdentifier, let title):
            try container.encode(ItemTypeValue.menuBarItem, forKey: .type)
            try container.encode(bundleIdentifier, forKey: .bundleIdentifier)
            try container.encodeIfPresent(title, forKey: .title)
        case .spacer(let spacerId):
            try container.encode(ItemTypeValue.spacer, forKey: .type)
            try container.encode(spacerId, forKey: .spacerId)
        }
    }
}

// MARK: - SettingsLayoutItem

/// Represents an item in the Settings "Menu Bar Layout" view.
///
/// This model is used for:
/// - Persisting user's icon arrangement preferences
/// - Supporting drag-and-drop reordering in the Settings UI
/// - Syncing with the actual menu bar state
///
/// Unlike `DrawerItem` (which holds transient captured images), this model
/// uses stable identifiers (bundle ID + title) that persist across app launches.
struct SettingsLayoutItem: Identifiable, Codable, Equatable, Hashable {

    // MARK: - Properties

    /// Unique identifier for this layout item
    let id: UUID

    /// The type of item (menu bar item or spacer)
    let itemType: SettingsLayoutItemType

    /// The section this item belongs to
    var section: MenuBarSectionType

    /// Order within the section (lower = further left in menu bar, closer to separator)
    var order: Int

    // MARK: - Initialization

    /// Creates a new settings layout item.
    /// - Parameters:
    ///   - itemType: The type of item (menu bar item or spacer)
    ///   - section: The section this item belongs to
    ///   - order: Order within the section (default: 0)
    init(
        itemType: SettingsLayoutItemType,
        section: MenuBarSectionType,
        order: Int = 0
    ) {
        self.id = UUID()
        self.itemType = itemType
        self.section = section
        self.order = order
    }

    /// Creates a settings layout item from a menu bar item.
    /// - Parameters:
    ///   - bundleIdentifier: The bundle ID of the owning application
    ///   - title: Optional window/item title
    ///   - section: The section this item belongs to
    ///   - order: Order within the section
    init(
        bundleIdentifier: String,
        title: String? = nil,
        section: MenuBarSectionType,
        order: Int = 0
    ) {
        self.id = UUID()
        self.itemType = .menuBarItem(bundleIdentifier: bundleIdentifier, title: title)
        self.section = section
        self.order = order
    }

    /// Creates a new spacer item.
    /// - Parameters:
    ///   - section: The section this spacer belongs to
    ///   - order: Order within the section
    /// - Returns: A new spacer layout item
    static func spacer(section: MenuBarSectionType, order: Int = 0) -> SettingsLayoutItem {
        SettingsLayoutItem(
            itemType: .spacer(id: UUID()),
            section: section,
            order: order
        )
    }

    // MARK: - Computed Properties

    /// Whether this item is a spacer
    var isSpacer: Bool {
        if case .spacer = itemType {
            return true
        }
        return false
    }

    /// The bundle identifier if this is a menu bar item, nil otherwise
    var bundleIdentifier: String? {
        if case .menuBarItem(let bundleId, _) = itemType {
            return bundleId
        }
        return nil
    }

    /// The title if this is a menu bar item, nil otherwise
    var title: String? {
        if case .menuBarItem(_, let title) = itemType {
            return title
        }
        return nil
    }

    /// Whether this item is immovable (locked by macOS).
    /// Uses IconIdentifier's immovableItems set to determine if the item cannot be moved.
    var isImmovable: Bool {
        guard case .menuBarItem(let bundleId, let itemTitle) = itemType else {
            // Spacers are always movable
            return false
        }
        let identifier = IconIdentifier(
            namespace: bundleId,
            title: itemTitle ?? ""
        )
        return identifier.isImmovable
    }

    /// Display name for the item (app name or "Spacer")
    var displayName: String {
        switch itemType {
        case .menuBarItem(let bundleId, let title):
            // Try to get app name from bundle ID
            if let appURL = NSWorkspace.shared.urlForApplication(
                withBundleIdentifier: bundleId
            ) {
                let appName = appURL.deletingPathExtension().lastPathComponent
                if let title, !title.isEmpty {
                    return "\(appName) - \(title)"
                }
                return appName
            }
            // Fallback to bundle ID
            if let title, !title.isEmpty {
                return "\(bundleId) - \(title)"
            }
            return bundleId
        case .spacer:
            return "Spacer"
        }
    }

    // MARK: - Matching

    /// Checks if this layout item matches a captured icon.
    /// - Parameter capturedIcon: The captured icon to match against
    /// - Returns: True if this layout item represents the same menu bar item
    func matches(capturedIcon: CapturedIcon) -> Bool {
        guard case .menuBarItem(let bundleId, let itemTitle) = itemType else {
            return false
        }

        guard let itemInfo = capturedIcon.itemInfo else {
            return false
        }

        // Get bundle ID from PID, with fallback to ownerName
        let capturedBundleId: String?
        if let app = NSRunningApplication(processIdentifier: itemInfo.ownerPID),
           let appBundleId = app.bundleIdentifier {
            capturedBundleId = appBundleId
        } else {
            // Fallback: use ownerName if bundle ID lookup fails
            // This handles testing scenarios and edge cases where PID lookup fails
            capturedBundleId = itemInfo.ownerName
        }

        guard let capturedBundleId else {
            return false
        }

        // Bundle ID must match
        guard capturedBundleId == bundleId else {
            return false
        }

        // If we have a title stored, it must match
        if let itemTitle, !itemTitle.isEmpty {
            return itemInfo.title == itemTitle
        }

        // No title specified means match any item from this app
        return true
    }
}

// MARK: - SettingsLayoutItem + Convenience

extension SettingsLayoutItem {

    /// Creates a layout item from a captured icon's metadata.
    /// - Parameters:
    ///   - capturedIcon: The captured icon to create a layout item from
    ///   - section: The section to assign this item to
    ///   - order: The order within the section
    /// - Returns: A new layout item, or nil if the captured icon lacks required metadata
    static func from(
        capturedIcon: CapturedIcon,
        section: MenuBarSectionType,
        order: Int = 0
    ) -> SettingsLayoutItem? {
        guard let itemInfo = capturedIcon.itemInfo else {
            return nil
        }

        // Get bundle ID from PID
        guard let app = NSRunningApplication(processIdentifier: itemInfo.ownerPID),
              let bundleId = app.bundleIdentifier else {
            return nil
        }

        return SettingsLayoutItem(
            bundleIdentifier: bundleId,
            title: itemInfo.title,
            section: section,
            order: order
        )
    }
}

// MARK: - SettingsLayoutItem + Transferable

/// Custom UTType for dragging SettingsLayoutItem within the app.
/// Uses a custom identifier to prevent conflicts with other apps.
extension UTType {
    /// UTType for dragging SettingsLayoutItem between sections in Settings UI.
    static let settingsLayoutItem = UTType(
        exportedAs: "com.drawer.settings-layout-item"
    )
}

extension SettingsLayoutItem: Transferable {
    /// Transfer representation for drag-and-drop.
    /// Uses JSON encoding via Codable conformance.
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .settingsLayoutItem)
    }
}
