//
//  IconPositionRestorer.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import Foundation
import os.log

// MARK: - IconPositionRestorer

/// Restores saved menu bar icon positions on app launch.
///
/// This manager reads saved icon positions from `SettingsManager` and uses
/// `IconRepositioner` to move icons back to their saved locations. Icons are
/// processed section by section, with a brief pause between moves to avoid
/// overwhelming the system.
///
/// ## Restoration Order
///
/// Sections are restored in this order to avoid conflicts:
/// 1. Always Hidden section (leftmost)
/// 2. Hidden section
/// 3. Visible section (rightmost)
///
/// ## Error Handling
///
/// - Missing icons (e.g., uninstalled apps) are skipped gracefully
/// - Failed moves are logged but don't stop the restoration process
/// - If the hidden control item is not found, restoration is skipped entirely
@MainActor
final class IconPositionRestorer {
    
    // MARK: - Singleton
    
    /// Shared instance for position restoration operations.
    static let shared = IconPositionRestorer()
    
    // MARK: - Dependencies
    
    private let settingsManager: SettingsManager
    private let repositioner: IconRepositioner
    
    // MARK: - Logger
    
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.drawer",
        category: "IconPositionRestorer"
    )
    
    // MARK: - Configuration
    
    /// Delay between individual icon moves to avoid overwhelming the system.
    private let delayBetweenMoves: Duration = .milliseconds(100)
    
    // MARK: - Initialization
    
    /// Creates an IconPositionRestorer with the specified dependencies.
    ///
    /// - Parameters:
    ///   - settingsManager: The settings manager to read saved positions from.
    ///   - repositioner: The repositioner to use for moving icons.
    init(
        settingsManager: SettingsManager? = nil,
        repositioner: IconRepositioner? = nil
    ) {
        self.settingsManager = settingsManager ?? .shared
        self.repositioner = repositioner ?? .shared
    }
    
    // MARK: - Public Methods
    
    /// Restores saved icon positions for all sections.
    ///
    /// This method reads saved positions from `SettingsManager` and moves
    /// each icon to its saved position using `IconRepositioner`. Icons are
    /// processed section by section, with a brief pause between moves.
    ///
    /// ## Graceful Degradation
    ///
    /// - If no saved positions exist, returns immediately
    /// - If the hidden control item is not found, skips restoration
    /// - Missing icons are logged and skipped
    /// - Failed moves are logged but don't stop the process
    func restorePositions() async {
        logger.info("Starting position restoration")
        
        // Load saved positions
        let savedPositions = settingsManager.loadIconPositions()
        
        guard !savedPositions.isEmpty else {
            logger.debug("No saved positions to restore")
            return
        }
        
        // Get current menu bar state
        let currentItems = IconItem.getMenuBarItems(onScreenOnly: false, activeSpaceOnly: true)
        
        guard !currentItems.isEmpty else {
            logger.warning("No menu bar items found, skipping restoration")
            return
        }
        
        // Find control items for section boundary detection
        guard let hiddenControlItem = IconItem.find(matching: .hiddenControlItem) else {
            logger.warning("Hidden control item not found, skipping restoration")
            return
        }
        
        // alwaysHiddenControlItem is optional (user may not have enabled always-hidden section)
        let alwaysHiddenControlItem = IconItem.find(matching: .alwaysHiddenControlItem)
        
        logger.debug("Found control items - hidden: \(hiddenControlItem.displayName), alwaysHidden: \(alwaysHiddenControlItem?.displayName ?? "nil")")
        
        // Restore sections in order: alwaysHidden -> hidden -> visible
        // This order prevents icons from being temporarily placed in wrong sections
        
        // 1. Restore always-hidden section (if control item exists)
        if let alwaysHiddenControl = alwaysHiddenControlItem,
           let alwaysHiddenIcons = savedPositions[MenuBarSectionType.alwaysHidden.rawValue] {
            await restoreSection(
                .alwaysHidden,
                savedIcons: alwaysHiddenIcons,
                targetItem: alwaysHiddenControl,
                destination: { .leftOfItem($0) },
                currentItems: currentItems
            )
        }
        
        // 2. Restore hidden section
        if let hiddenIcons = savedPositions[MenuBarSectionType.hidden.rawValue] {
            await restoreSection(
                .hidden,
                savedIcons: hiddenIcons,
                targetItem: hiddenControlItem,
                destination: { .leftOfItem($0) },
                currentItems: currentItems
            )
        }
        
        // 3. Restore visible section
        if let visibleIcons = savedPositions[MenuBarSectionType.visible.rawValue] {
            await restoreSection(
                .visible,
                savedIcons: visibleIcons,
                targetItem: hiddenControlItem,
                destination: { .rightOfItem($0) },
                currentItems: currentItems
            )
        }
        
        logger.info("Position restoration complete")
    }
    
    // MARK: - Private Methods
    
    /// Restores a single section of the menu bar.
    ///
    /// - Parameters:
    ///   - section: The section type being restored.
    ///   - savedIcons: The saved icon identifiers for this section, in order.
    ///   - targetItem: The control item that defines the section boundary.
    ///   - destination: A closure that creates the move destination for a given target item.
    ///   - currentItems: The current menu bar items for checking positions.
    private func restoreSection(
        _ section: MenuBarSectionType,
        savedIcons: [IconIdentifier],
        targetItem: IconItem,
        destination: (IconItem) -> MoveDestination,
        currentItems: [IconItem]
    ) async {
        logger.debug("Restoring \(section.rawValue) section with \(savedIcons.count) icons")
        
        var restoredCount = 0
        var skippedCount = 0
        var failedCount = 0
        
        for identifier in savedIcons {
            // Skip immovable items
            guard !identifier.isImmovable else {
                logger.debug("Skipping immovable item: \(identifier.namespace)/\(identifier.title)")
                skippedCount += 1
                continue
            }
            
            // Find the current IconItem for this identifier
            guard let item = IconItem.find(matching: identifier) else {
                logger.debug("Item not found (may be uninstalled): \(identifier.namespace)/\(identifier.title)")
                skippedCount += 1
                continue
            }
            
            // Check if item is already in the correct section
            let refreshedItems = IconItem.getMenuBarItems(onScreenOnly: false, activeSpaceOnly: true)
            if isItemInSection(item, section: section, currentItems: refreshedItems) {
                logger.debug("Item already in correct section: \(item.displayName)")
                restoredCount += 1
                continue
            }
            
            // Get the current target item (it may have moved)
            guard let currentTarget = IconItem.find(matching: targetItem.identifier) else {
                logger.warning("Target control item no longer found, stopping section restoration")
                break
            }
            
            // Move the item
            do {
                try await repositioner.move(item: item, to: destination(currentTarget))
                restoredCount += 1
                logger.debug("Moved item: \(item.displayName)")
                
                // Pause between moves to avoid overwhelming the system
                try? await Task.sleep(for: delayBetweenMoves)
            } catch {
                failedCount += 1
                logger.warning("Failed to move '\(item.displayName)': \(error.localizedDescription)")
                
                // Pause briefly even on failure before trying the next item
                try? await Task.sleep(for: delayBetweenMoves)
            }
        }
        
        logger.info("Section \(section.rawValue): restored=\(restoredCount), skipped=\(skippedCount), failed=\(failedCount)")
    }
    
    /// Checks if an item is currently in the specified section.
    ///
    /// Uses the control items to determine section boundaries:
    /// - Visible: Right of the hidden control item
    /// - Hidden: Between always-hidden control (if present) and hidden control
    /// - Always Hidden: Left of the always-hidden control item
    ///
    /// - Parameters:
    ///   - item: The item to check.
    ///   - section: The target section.
    ///   - currentItems: The current menu bar items, sorted by X position.
    /// - Returns: True if the item is in the specified section.
    private func isItemInSection(
        _ item: IconItem,
        section: MenuBarSectionType,
        currentItems: [IconItem]
    ) -> Bool {
        // Find control items in current items
        let hiddenControlItem = currentItems.first { $0.identifier == .hiddenControlItem }
        let alwaysHiddenControlItem = currentItems.first { $0.identifier == .alwaysHiddenControlItem }
        
        guard let hiddenControl = hiddenControlItem else {
            // Can't determine section without hidden control item
            return false
        }
        
        let itemX = item.frame.minX
        let hiddenControlX = hiddenControl.frame.minX
        
        switch section {
        case .visible:
            // Visible items are to the right of the hidden control
            return itemX > hiddenControlX
            
        case .hidden:
            if let alwaysHiddenControl = alwaysHiddenControlItem {
                // Hidden items are between always-hidden control and hidden control
                return itemX > alwaysHiddenControl.frame.minX && itemX < hiddenControlX
            } else {
                // Without always-hidden control, hidden items are just left of hidden control
                return itemX < hiddenControlX
            }
            
        case .alwaysHidden:
            if let alwaysHiddenControl = alwaysHiddenControlItem {
                // Always-hidden items are to the left of the always-hidden control
                return itemX < alwaysHiddenControl.frame.minX
            } else {
                // No always-hidden section configured
                return false
            }
        }
    }
}
