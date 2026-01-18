//
//  IconItem.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import CoreGraphics
import Foundation
import os.log

// MARK: - IconItem

/// A full representation of a menu bar icon with window information.
/// Used for repositioning operations where we need the window ID and frame.
/// This type is used by the repositioning system (IconRepositioner).
struct IconItem: Hashable, Equatable {

    // MARK: - Properties

    /// The window identifier for this menu bar item.
    let windowID: CGWindowID

    /// The frame of the item's window in screen coordinates.
    let frame: CGRect

    /// The process identifier of the owning application.
    let ownerPID: pid_t

    /// The name of the owning application.
    let ownerName: String?

    /// The title of the menu bar item window.
    let title: String?

    /// The bundle identifier of the owning application.
    let bundleIdentifier: String?

    // MARK: - Computed Properties

    /// The unique identifier for this item, used for persistence and matching.
    /// Computed from bundleIdentifier (or ownerName) and title.
    var identifier: IconIdentifier {
        let namespace = bundleIdentifier ?? ownerName ?? "unknown"
        return IconIdentifier(namespace: namespace, title: title ?? "")
    }

    /// Returns true if this item can be repositioned.
    /// System items like Control Center and Clock cannot be moved.
    var isMovable: Bool {
        !identifier.isImmovable
    }

    /// A display name suitable for showing to users.
    /// Prefers title, falls back to ownerName, then "Unknown".
    var displayName: String {
        if let title, !title.isEmpty {
            return title
        }
        if let ownerName, !ownerName.isEmpty {
            return ownerName
        }
        return "Unknown"
    }

    // MARK: - Hashable & Equatable

    /// Hash based on windowID only, as it uniquely identifies the item.
    func hash(into hasher: inout Hasher) {
        hasher.combine(windowID)
    }

    /// Equality based on windowID only.
    static func == (lhs: IconItem, rhs: IconItem) -> Bool {
        lhs.windowID == rhs.windowID
    }

    // MARK: - Initializers

    /// Internal memberwise initializer for testing.
    ///
    /// - Note: This initializer is internal to allow test targets to create mock IconItems.
    ///   It should not be used in production code.
    init(
        windowID: CGWindowID,
        frame: CGRect,
        ownerPID: pid_t,
        ownerName: String?,
        title: String?,
        bundleIdentifier: String?
    ) {
        self.windowID = windowID
        self.frame = frame
        self.ownerPID = ownerPID
        self.ownerName = ownerName
        self.title = title
        self.bundleIdentifier = bundleIdentifier
    }

    /// Creates an IconItem from a window information dictionary.
    /// Returns nil if the dictionary doesn't represent a valid menu bar item.
    ///
    /// - Parameter windowInfo: Dictionary from CGWindowListCopyWindowInfo
    init?(windowInfo: [String: Any]) {
        // Extract windowID (required)
        guard let windowNumber = windowInfo[kCGWindowNumber as String] as? CGWindowID else {
            return nil
        }
        self.windowID = windowNumber

        // Extract frame from bounds dictionary (required)
        guard let boundsDict = windowInfo[kCGWindowBounds as String] as? [String: Any],
              let x = boundsDict["X"] as? CGFloat,
              let y = boundsDict["Y"] as? CGFloat,
              let width = boundsDict["Width"] as? CGFloat,
              let height = boundsDict["Height"] as? CGFloat else {
            return nil
        }
        self.frame = CGRect(x: x, y: y, width: width, height: height)

        // Extract ownerPID (required)
        guard let pid = windowInfo[kCGWindowOwnerPID as String] as? pid_t else {
            return nil
        }
        self.ownerPID = pid

        // Extract ownerName (optional)
        self.ownerName = windowInfo[kCGWindowOwnerName as String] as? String

        // Extract title (optional)
        self.title = windowInfo[kCGWindowName as String] as? String

        // Get bundle identifier from running application
        if let app = NSRunningApplication(processIdentifier: pid) {
            self.bundleIdentifier = app.bundleIdentifier
        } else {
            self.bundleIdentifier = nil
        }
    }

    /// Creates an IconItem from a window ID by fetching current window info.
    /// Returns nil if the window is invalid or unavailable.
    ///
    /// - Parameter windowID: The window ID to look up
    init?(windowID: CGWindowID) {
        // Get the frame via Bridging
        guard let frame = Bridging.getWindowFrame(for: windowID) else {
            return nil
        }

        // Get full window info via CGWindowListCopyWindowInfo
        guard let windowInfoList = CGWindowListCopyWindowInfo([.optionIncludingWindow], windowID) as? [[String: Any]],
              let windowInfo = windowInfoList.first else {
            return nil
        }

        // Extract ownerPID (required)
        guard let pid = windowInfo[kCGWindowOwnerPID as String] as? pid_t else {
            return nil
        }

        self.windowID = windowID
        self.frame = frame
        self.ownerPID = pid
        self.ownerName = windowInfo[kCGWindowOwnerName as String] as? String
        self.title = windowInfo[kCGWindowName as String] as? String

        // Get bundle identifier from running application
        if let app = NSRunningApplication(processIdentifier: pid) {
            self.bundleIdentifier = app.bundleIdentifier
        } else {
            self.bundleIdentifier = nil
        }
    }
}

// MARK: - Static Methods

extension IconItem {

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.drawer",
        category: "IconItem"
    )

    /// Returns all current menu bar items, sorted by X position (left to right).
    ///
    /// - Parameters:
    ///   - onScreenOnly: If true, only return items currently visible on screen.
    ///   - activeSpaceOnly: If true, only return items on the active space. Default is true.
    /// - Returns: Array of IconItem sorted by X position.
    static func getMenuBarItems(onScreenOnly: Bool = false, activeSpaceOnly: Bool = true) -> [IconItem] {
        // Build the option set
        var options: Bridging.WindowListOption = [.menuBarItems]
        if onScreenOnly {
            options.insert(.onScreen)
        }
        if activeSpaceOnly {
            options.insert(.activeSpace)
        }

        // Get window IDs
        let windowIDs = Bridging.getWindowList(option: options)

        // Get window info for all windows at once for efficiency
        guard let windowInfoList = CGWindowListCopyWindowInfo(
            [.optionAll],
            kCGNullWindowID
        ) as? [[String: Any]] else {
            logger.warning("Failed to get window info list")
            return []
        }

        // Create a lookup dictionary for faster access
        var windowInfoByID: [CGWindowID: [String: Any]] = [:]
        for info in windowInfoList {
            if let id = info[kCGWindowNumber as String] as? CGWindowID {
                windowInfoByID[id] = info
            }
        }

        // Convert to IconItems
        var items: [IconItem] = []
        for windowID in windowIDs {
            if let info = windowInfoByID[windowID],
               let item = IconItem(windowInfo: info) {
                items.append(item)
            }
        }

        // Sort by X position (left to right)
        items.sort { $0.frame.minX < $1.frame.minX }

        return items
    }

    /// Finds a menu bar item matching the given identifier.
    ///
    /// - Parameter identifier: The IconIdentifier to match against.
    /// - Returns: The matching IconItem, or nil if not found.
    static func find(matching identifier: IconIdentifier) -> IconItem? {
        let items = getMenuBarItems(onScreenOnly: false, activeSpaceOnly: true)
        return items.first { $0.identifier == identifier }
    }
}
