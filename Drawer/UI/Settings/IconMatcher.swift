//
//  IconMatcher.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import Foundation
import os.log

// MARK: - IconMatchResult

/// Result of icon matching operation.
struct IconMatchResult {
    /// The matched IconItem, if found
    let iconItem: IconItem?
    /// The method used to find the match
    let matchMethod: MatchMethod
    /// Whether the match was found
    var isFound: Bool { iconItem != nil }
    
    /// How the icon was matched
    enum MatchMethod {
        /// Matched via cached windowID (fast path)
        case windowIDCache
        /// Matched via exact bundle ID + title
        case exactMatch
        /// Matched via bundle ID only (ignoring title)
        case bundleIDOnly
        /// Matched via owner name fallback
        case ownerName
        /// No match found
        case notFound
        /// Item is a spacer (no physical match exists)
        case spacer
    }
}

// MARK: - IconMatcherProtocol

/// Protocol for icon matching to support testing with mock implementations.
protocol IconMatcherProtocol {
    /// Finds the IconItem matching a SettingsLayoutItem.
    ///
    /// - Parameters:
    ///   - layoutItem: The layout item to find
    ///   - windowIDCache: Cache mapping layout item IDs to window IDs
    ///   - menuBarItems: Current menu bar items to search (defaults to live items)
    /// - Returns: The matching IconItem result with match method
    func findIconItem(
        for layoutItem: SettingsLayoutItem,
        windowIDCache: [UUID: CGWindowID],
        menuBarItems: [IconItem]?
    ) -> IconMatchResult
}

// MARK: - IconMatcher

/// Matches SettingsLayoutItems to live IconItems for repositioning.
///
/// This struct implements the multi-tier matching strategy specified in Spec 5.7:
///
/// 1. **Fast path**: Use cached windowID (most reliable)
/// 2. **Fallback 1**: Exact match (bundle ID + title)
/// 3. **Fallback 2**: Bundle ID match only (for apps with dynamic titles)
/// 4. **Fallback 3**: Owner name match (for apps without bundle ID)
///
/// ## Usage
///
/// ```swift
/// let matcher = IconMatcher()
/// let result = matcher.findIconItem(
///     for: layoutItem,
///     windowIDCache: windowIDCache
/// )
/// if let iconItem = result.iconItem {
///     // Use iconItem for repositioning
/// }
/// ```
struct IconMatcher: IconMatcherProtocol {
    
    // MARK: - Properties
    
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.drawer",
        category: "IconMatcher"
    )
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Public Methods
    
    /// Finds the IconItem matching a SettingsLayoutItem.
    ///
    /// Uses a multi-tier matching strategy (Spec 5.7):
    /// 1. Fast path: Use cached windowID (most reliable)
    /// 2. Fallback: Search by bundle ID with lenient title matching
    ///
    /// - Parameters:
    ///   - layoutItem: The layout item to find
    ///   - windowIDCache: Cache mapping layout item IDs to window IDs
    ///   - menuBarItems: Current menu bar items to search (nil uses live items)
    /// - Returns: The matching IconItem result with match method
    func findIconItem(
        for layoutItem: SettingsLayoutItem,
        windowIDCache: [UUID: CGWindowID],
        menuBarItems: [IconItem]? = nil
    ) -> IconMatchResult {
        logger.debug("=== FIND ICON ITEM START ===")
        logger.debug("Looking for: bundleId=\(layoutItem.bundleIdentifier ?? "nil"), title=\(layoutItem.title ?? "nil")")
        logger.debug("Layout item ID: \(layoutItem.id)")
        
        // Spacers don't have corresponding IconItems
        if layoutItem.isSpacer {
            logger.debug("Item is spacer - no physical match")
            return IconMatchResult(iconItem: nil, matchMethod: .spacer)
        }
        
        guard case .menuBarItem(let bundleId, let title) = layoutItem.itemType else {
            logger.debug("Item type is not menuBarItem - no physical match")
            return IconMatchResult(iconItem: nil, matchMethod: .notFound)
        }
        
        // Fast path: Use cached windowID
        if let windowID = windowIDCache[layoutItem.id] {
            logger.debug("WindowID cache HIT: \(windowID)")
            if let item = findIconItemByWindowID(windowID, in: menuBarItems) {
                logger.debug("  -> Found valid IconItem: \(item.displayName)")
                return IconMatchResult(iconItem: item, matchMethod: .windowIDCache)
            } else {
                logger.debug("  -> WindowID \(windowID) is STALE (window no longer exists)")
            }
        } else {
            logger.debug("WindowID cache MISS")
        }
        
        // Get all current menu bar items
        let allItems = menuBarItems ?? IconItem.getMenuBarItems(onScreenOnly: false, activeSpaceOnly: true)
        logger.debug("Searching \(allItems.count) menu bar items...")
        
        // Log all available items for debugging (only in debug builds)
        #if DEBUG
        for (index, item) in allItems.enumerated() {
            logger.debug("  Available[\(index)]: bundle=\(item.bundleIdentifier ?? "nil"), title=\(item.title ?? "nil"), windowID=\(item.windowID)")
        }
        #endif
        
        // Strategy 1: Exact match (bundle ID + title)
        if let exactMatch = allItems.first(where: { item in
            item.bundleIdentifier == bundleId && item.title == title
        }) {
            logger.debug("Match via EXACT (bundle + title): \(exactMatch.displayName)")
            return IconMatchResult(iconItem: exactMatch, matchMethod: .exactMatch)
        }
        
        // Strategy 2: Bundle ID match only (for apps with dynamic titles)
        if let bundleMatch = allItems.first(where: { item in
            item.bundleIdentifier == bundleId
        }) {
            logger.debug("Match via BUNDLE ID only: \(bundleMatch.displayName)")
            return IconMatchResult(iconItem: bundleMatch, matchMethod: .bundleIDOnly)
        }
        
        // Strategy 3: Owner name match (fallback for apps without bundle ID)
        if let ownerMatch = allItems.first(where: { item in
            item.ownerName == bundleId  // bundleId might actually be ownerName
        }) {
            logger.debug("Match via OWNER NAME: \(ownerMatch.displayName)")
            return IconMatchResult(iconItem: ownerMatch, matchMethod: .ownerName)
        }
        
        logger.warning("=== FIND ICON ITEM FAILED: No match for \(layoutItem.displayName) ===")
        return IconMatchResult(iconItem: nil, matchMethod: .notFound)
    }
    
    // MARK: - Private Methods
    
    /// Finds an IconItem by windowID.
    ///
    /// - Parameters:
    ///   - windowID: The window ID to search for
    ///   - menuBarItems: Items to search (nil uses live items)
    /// - Returns: The matching IconItem, or nil if not found
    private func findIconItemByWindowID(_ windowID: CGWindowID, in menuBarItems: [IconItem]?) -> IconItem? {
        let items = menuBarItems ?? IconItem.getMenuBarItems(onScreenOnly: false, activeSpaceOnly: true)
        return items.first { $0.windowID == windowID }
    }
}
