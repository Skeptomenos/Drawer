//
//  LayoutReconciler.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import Foundation
import os.log

// MARK: - ReconciliationResult

/// Result of reconciling captured icons with saved layout.
struct ReconciliationResult {
    /// Reconciled layout items
    let items: [SettingsLayoutItem]
    /// Cache mapping item IDs to captured images
    let imageCache: [UUID: CGImage]
    /// Cache mapping item IDs to window IDs for repositioning (Spec 5.7)
    let windowIDCache: [UUID: CGWindowID]
    /// Number of items matched from saved layout (with section override)
    let matchedCount: Int
    /// Number of new items not found in saved layout
    let newCount: Int
}

// MARK: - LayoutReconciler

/// Reconciles captured menu bar icons with saved layout configuration.
///
/// This struct encapsulates the core reconciliation algorithm for the Menu Bar Layout
/// feature, implementing the fixes specified in:
/// - **Spec 5.6**: Uses captured X-position order as source of truth (not saved order)
/// - **Spec 5.7**: Builds windowID cache for reliable icon matching during repositioning
///
/// ## Algorithm Overview
///
/// 1. **Sort by X-position**: Captured icons are sorted left-to-right by their
///    `originalFrame.minX` coordinate - this is the ground truth for display order.
///
/// 2. **Section from capture**: Each icon's section is determined by its captured
///    `sectionType` (based on separator positions in the menu bar).
///
/// 3. **Section overrides only**: Saved layout is consulted ONLY to detect user
///    section overrides (when user intentionally dragged an item to a different section).
///
/// 4. **Order from position**: Order values are assigned based on position within
///    each section, not from saved order values.
///
/// ## Usage
///
/// ```swift
/// let reconciler = LayoutReconciler()
/// let result = reconciler.reconcile(
///     capturedIcons: capturedIcons,
///     savedLayout: savedLayout
/// )
/// // result.items are ordered by captured X-position
/// // result.windowIDCache can be used for findIconItem()
/// ```
struct LayoutReconciler {

    // MARK: - Properties

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.drawer",
        category: "LayoutReconciler"
    )

    // MARK: - Initialization

    init() {}

    // MARK: - Public Methods

    /// Reconciles captured icons with saved layout.
    ///
    /// Algorithm (Spec 5.6 fix):
    /// 1. Sort captured icons by X position (left to right) - this is the ground truth
    /// 2. For each captured icon, determine its section from the capture (based on separator positions)
    /// 3. Only check saved layout for section OVERRIDES (user intentionally moved item)
    /// 4. Assign order based on captured position within each section
    ///
    /// This ensures the display always matches the actual menu bar order.
    ///
    /// - Parameters:
    ///   - capturedIcons: Icons captured from the current menu bar state
    ///   - savedLayout: Previously saved layout items (used only for section overrides)
    /// - Returns: Reconciled layout items with image cache, windowID cache, and statistics
    func reconcile(
        capturedIcons: [CapturedIcon],
        savedLayout: [SettingsLayoutItem]
    ) -> ReconciliationResult {
        var reconciledItems: [SettingsLayoutItem] = []
        var newImageCache: [UUID: CGImage] = [:]
        var newWindowIDCache: [UUID: CGWindowID] = [:]
        var matchedCount = 0
        var newCount = 0

        // Spec 5.6: Sort captured icons by X position (left to right) - this is the source of truth
        let sortedIcons = capturedIcons.sorted { $0.originalFrame.minX < $1.originalFrame.minX }

        logger.debug("[Reconcile] Sorted \(sortedIcons.count) icons by X-position")

        // Track order counters per section for proper ordering
        var sectionOrderCounters: [MenuBarSectionType: Int] = [:]
        for section in MenuBarSectionType.allCases {
            sectionOrderCounters[section] = 0
        }

        // Process each captured icon in X-position order
        for capturedIcon in sortedIcons {
            // Try to find a matching saved item - only for section override detection
            let matchingSaved = findMatchingSavedItem(
                for: capturedIcon,
                in: savedLayout
            )

            // Spec 5.6: Use captured section as default, but respect user's section override
            let effectiveSection: MenuBarSectionType
            let hasSectionOverride: Bool

            if let saved = matchingSaved, saved.section != capturedIcon.sectionType {
                // User has overridden the section - respect their preference
                effectiveSection = saved.section
                hasSectionOverride = true
                matchedCount += 1
                logger.debug("[Reconcile] Icon \(capturedIcon.itemInfo?.ownerName ?? "unknown"): captured=\(capturedIcon.sectionType.displayName), override=\(saved.section.displayName)")
            } else {
                // Use the captured section (ground truth)
                effectiveSection = capturedIcon.sectionType
                hasSectionOverride = false
                newCount += 1
                logger.debug("[Reconcile] Icon \(capturedIcon.itemInfo?.ownerName ?? "unknown"): captured=\(capturedIcon.sectionType.displayName), no override")
            }

            // Spec 5.6: Assign order based on position within section (not saved order)
            let order = sectionOrderCounters[effectiveSection] ?? 0
            sectionOrderCounters[effectiveSection] = order + 1

            // Create the layout item
            if let item = createLayoutItem(
                from: capturedIcon,
                section: effectiveSection,
                order: order
            ) {
                reconciledItems.append(item)
                newImageCache[item.id] = capturedIcon.image

                // Spec 5.7: Cache windowID for later use in findIconItem()
                if let windowID = capturedIcon.itemInfo?.windowID {
                    newWindowIDCache[item.id] = windowID
                }

                logger.debug("[Reconcile] Icon \(item.displayName): order=\(order) in section \(effectiveSection.displayName)")
            }
        }

        // Preserve spacers from saved layout (spacers are user-created, not captured)
        for savedItem in savedLayout where savedItem.isSpacer {
            reconciledItems.append(savedItem)
        }

        // Normalize orders to be sequential within each section
        reconciledItems = normalizeOrders(reconciledItems)

        logger.info("[Reconcile] Complete: \(reconciledItems.count) items (\(matchedCount) overrides, \(newCount) from capture)")

        return ReconciliationResult(
            items: reconciledItems,
            imageCache: newImageCache,
            windowIDCache: newWindowIDCache,
            matchedCount: matchedCount,
            newCount: newCount
        )
    }

    // MARK: - Private Methods

    /// Finds a matching saved layout item for a captured icon.
    ///
    /// Matching is based on bundle ID and optional title.
    ///
    /// - Parameters:
    ///   - capturedIcon: The captured icon to match
    ///   - savedLayout: The saved layout items to search
    /// - Returns: The matching saved item, or nil if not found
    private func findMatchingSavedItem(
        for capturedIcon: CapturedIcon,
        in savedLayout: [SettingsLayoutItem]
    ) -> SettingsLayoutItem? {
        return savedLayout.first { saved in
            saved.matches(capturedIcon: capturedIcon)
        }
    }

    /// Creates a SettingsLayoutItem from a captured icon.
    ///
    /// - Parameters:
    ///   - capturedIcon: The captured icon
    ///   - section: The section to assign
    ///   - order: The order within the section
    /// - Returns: A new layout item, or nil if the icon lacks required metadata
    private func createLayoutItem(
        from capturedIcon: CapturedIcon,
        section: MenuBarSectionType,
        order: Int
    ) -> SettingsLayoutItem? {
        guard let itemInfo = capturedIcon.itemInfo else {
            logger.warning("[Reconcile] Skipping icon without itemInfo at x=\(capturedIcon.originalFrame.minX)")
            return nil
        }

        // Get bundle ID from PID
        guard let app = NSRunningApplication(processIdentifier: itemInfo.ownerPID),
              let bundleId = app.bundleIdentifier else {
            // Fallback: use ownerName if bundle ID not available
            if let ownerName = itemInfo.ownerName {
                return SettingsLayoutItem(
                    bundleIdentifier: ownerName,
                    title: itemInfo.title,
                    section: section,
                    order: order
                )
            }
            logger.warning("[Reconcile] Skipping icon without bundle ID: PID=\(itemInfo.ownerPID)")
            return nil
        }

        return SettingsLayoutItem(
            bundleIdentifier: bundleId,
            title: itemInfo.title,
            section: section,
            order: order
        )
    }

    /// Normalizes order values within each section to be sequential (0, 1, 2, ...).
    ///
    /// This prevents order values from growing unboundedly after repeated operations.
    ///
    /// - Parameter items: The items to normalize
    /// - Returns: Items with normalized order values
    private func normalizeOrders(_ items: [SettingsLayoutItem]) -> [SettingsLayoutItem] {
        var normalized: [SettingsLayoutItem] = []

        for sectionType in MenuBarSectionType.allCases {
            let sectionItems = items
                .filter { $0.section == sectionType }
                .sorted { $0.order < $1.order }

            for (index, var item) in sectionItems.enumerated() {
                item.order = index
                normalized.append(item)
            }
        }

        return normalized
    }
}
