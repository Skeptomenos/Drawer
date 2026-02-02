//
//  SettingsMenuBarLayoutView.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import CoreGraphics
import os.log
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Reconciliation
// Uses LayoutReconciler for layout reconciliation (Spec 5.6, 5.7)
// See LayoutReconciler.swift for algorithm details

// MARK: - SettingsMenuBarLayoutView

/// Settings view for configuring menu bar icon layout.
///
/// Displays three sections (Shown, Hidden, Always Hidden) where users can:
/// - See which icons are in each section
/// - Drag and drop icons between sections
/// - Add spacers between icons (Phase 4.2.4)
///
/// This view is the foundation for the drag-and-drop layout editor.
struct SettingsMenuBarLayoutView: View {

    // MARK: - Environment

    @EnvironmentObject private var appState: AppState

    // MARK: - State

    /// Items for display, populated from IconCapturer and reconciled with saved layout
    @State private var layoutItems: [SettingsLayoutItem] = []

    /// Cache mapping layout item IDs to captured CGImages
    @State private var imageCache: [UUID: CGImage] = [:]

    /// Whether a refresh is in progress
    @State private var isRefreshing: Bool = false

    /// Error message if capture fails
    @State private var errorMessage: String?

    /// Whether layout has been modified (for save indication)
    @State private var hasUnsavedChanges: Bool = false

    /// Cache mapping layout item IDs to window IDs for repositioning (Spec 5.7)
    @State private var windowIDCache: [UUID: CGWindowID] = [:]

    /// Whether to show the reset confirmation alert
    @State private var showResetConfirmation: Bool = false

    /// Reconciler instance for layout reconciliation (Spec 5.6)
    private let reconciler = LayoutReconciler()

    /// Matcher instance for finding IconItems from SettingsLayoutItems (Spec 5.7)
    private let iconMatcher = IconMatcher()

    /// Logger for debugging
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.drawer",
        category: "SettingsMenuBarLayoutView"
    )

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LayoutDesign.sectionSpacing) {
                headerSection

                if let errorMessage {
                    errorView(errorMessage)
                }

                ForEach(MenuBarSectionType.allCases) { sectionType in
                    LayoutSectionView(
                        sectionType: sectionType,
                        items: items(for: sectionType),
                        imageCache: imageCache,
                        onMoveItem: { item, targetSection, insertIndex in
                            moveItem(item, to: targetSection, at: insertIndex)
                        }
                    )
                }

                paletteSection

                Spacer(minLength: 16)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            // Auto-refresh on appear if no items are loaded
            if layoutItems.isEmpty && !isRefreshing {
                refreshItems()
            }
        }
    }

    // MARK: - Error View

    /// Displays an error message when capture fails
    private func errorView(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)

            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(LayoutDesign.sectionPadding)
        .background(
            RoundedRectangle(cornerRadius: LayoutDesign.sectionCornerRadius)
                .fill(Color.orange.opacity(0.1))
        )
    }

    // MARK: - Header Section

    /// Header with icon, title, description, and refresh button
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                Spacer()

                VStack(spacing: 8) {
                    // Menu bar icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(nsColor: .controlBackgroundColor))
                            .frame(width: LayoutDesign.headerIconSize, height: LayoutDesign.headerIconSize)

                        Image(systemName: "menubar.rectangle")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }

                    Text("Menu Bar Items")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Drag items between sections to re-order your menu bar")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Spacer()
            }
            .overlay(alignment: .topTrailing) {
                refreshButton
            }
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: LayoutDesign.sectionCornerRadius)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        )
    }

    /// Refresh button to reload menu bar items
    private var refreshButton: some View {
        Button {
            refreshItems()
        } label: {
            Image(systemName: "arrow.clockwise")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .disabled(isRefreshing)
        .padding(8)
    }

    // MARK: - Palette Section

    /// Palette with action buttons for adding spacers and resetting positions
    private var paletteSection: some View {
        VStack(alignment: .leading, spacing: LayoutDesign.sectionHeaderSpacing) {
            Label("Palette", systemImage: "square.grid.2x2")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.primary)

            HStack(spacing: 12) {
                Button {
                    addSpacer()
                } label: {
                    Text("Add a Spacer")
                        .font(.caption.weight(.medium))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                Button {
                    showResetConfirmation = true
                } label: {
                    Text("Reset Icon Positions")
                        .font(.caption.weight(.medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .alert("Reset Icon Positions?", isPresented: $showResetConfirmation) {
                    Button("Cancel", role: .cancel) { }
                    Button("Reset", role: .destructive) {
                        resetIconPositions()
                    }
                } message: {
                    Text("This will clear all saved icon position preferences. Icons will stay in their current positions but won't be restored on next launch.")
                }

                // Future: Add menu bar item group button (Phase 4.2.4)
                // Button("Add a menu bar item group") { }
            }
            .padding(LayoutDesign.sectionPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: LayoutDesign.sectionCornerRadius)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
        }
    }

    // MARK: - Private Methods

    /// Returns items for a given section type
    private func items(for sectionType: MenuBarSectionType) -> [SettingsLayoutItem] {
        layoutItems.filter { $0.section == sectionType }
            .sorted { $0.order < $1.order }
    }

    /// Moves an item to a new section at the specified index.
    /// - Parameters:
    ///   - item: The item to move
    ///   - targetSection: The section to move the item to
    ///   - insertIndex: The position within the section to insert at
    private func moveItem(_ item: SettingsLayoutItem, to targetSection: MenuBarSectionType, at insertIndex: Int) {
        guard let sourceIndex = layoutItems.firstIndex(where: { $0.id == item.id }) else {
            return
        }

        // Skip spacers for physical repositioning (they don't exist in the real menu bar)
        // Also skip immovable items
        let shouldReposition = !item.isSpacer && !item.isImmovable

        // Trigger physical repositioning asynchronously (before updating UI state)
        if shouldReposition {
            Task {
                await performReposition(item: item, to: targetSection, at: insertIndex)
            }
        }

        // Remove from current position
        var movedItem = layoutItems.remove(at: sourceIndex)

        // Update section
        movedItem.section = targetSection

        // Get items in target section and determine new order
        let targetItems = items(for: targetSection)
        let clampedIndex = min(insertIndex, targetItems.count)

        // Calculate new order based on insertion index
        if clampedIndex == 0 {
            // Insert at beginning
            movedItem.order = (targetItems.first?.order ?? 0) - 1
        } else if clampedIndex >= targetItems.count {
            // Insert at end
            movedItem.order = (targetItems.last?.order ?? 0) + 1
        } else {
            // Insert between items - use average of surrounding orders
            let prevOrder = targetItems[clampedIndex - 1].order
            let nextOrder = targetItems[clampedIndex].order
            movedItem.order = (prevOrder + nextOrder) / 2

            // Handle case where orders are adjacent integers
            if movedItem.order == prevOrder || movedItem.order == nextOrder {
                movedItem.order = prevOrder + 1
                // Shift subsequent items
                for index in layoutItems.indices where layoutItems[index].section == targetSection
                    && layoutItems[index].order >= movedItem.order {
                    layoutItems[index].order += 1
                }
            }
        }

        layoutItems.append(movedItem)

        // Persist changes to SettingsManager
        saveLayout()
    }

    /// Saves the current layout to SettingsManager for persistence.
    private func saveLayout() {
        SettingsManager.shared.saveMenuBarLayout(layoutItems)
        hasUnsavedChanges = false

        #if DEBUG
        logger.debug("Saved layout with \(self.layoutItems.count) items")
        #endif
    }

    // MARK: - Repositioning (Task 5.4.2)

    /// Performs physical repositioning of a menu bar icon using IconRepositioner.
    ///
    /// This method:
    /// 1. Finds the IconItem matching the dropped SettingsLayoutItem
    /// 2. Calculates the destination using control items as section boundaries
    /// 3. Calls IconRepositioner.shared.move(item:to:)
    /// 4. Refreshes icons on success, shows error on failure
    ///
    /// - Parameters:
    ///   - item: The layout item being moved
    ///   - targetSection: The section to move the item to
    ///   - insertIndex: The position within the section to insert at
    @MainActor
    private func performReposition(
        item: SettingsLayoutItem,
        to targetSection: MenuBarSectionType,
        at insertIndex: Int
    ) async {
        // Find the IconItem that matches this layout item
        guard let iconItem = findIconItem(for: item) else {
            logger.warning("Could not find IconItem for \(item.displayName)")
            return
        }

        // Calculate the destination based on section and position
        guard let destination = calculateDestination(
            for: targetSection,
            at: insertIndex,
            excludingItem: iconItem
        ) else {
            logger.warning("Could not calculate destination for \(item.displayName)")
            return
        }

        do {
            try await IconRepositioner.shared.move(item: iconItem, to: destination)
            logger.info("Successfully repositioned \(item.displayName) to \(String(describing: targetSection))")

            // Save the new positions to persist across app restarts
            await saveCurrentPositions(for: targetSection)

            // Refresh icons after successful move
            refreshItems()
        } catch let error as RepositionError {
            logger.error("Failed to reposition \(item.displayName): \(error.localizedDescription)")
            showRepositionError(error)
        } catch {
            logger.error("Unexpected error repositioning \(item.displayName): \(error.localizedDescription)")
        }
    }

    /// Finds the IconItem matching a SettingsLayoutItem.
    ///
    /// Uses a multi-tier matching strategy (Spec 5.7):
    /// 1. Fast path: Use cached windowID (most reliable)
    /// 2. Fallback 1: Exact match (bundle ID + title)
    /// 3. Fallback 2: Bundle ID match only (for apps with dynamic titles)
    /// 4. Fallback 3: Owner name match (for apps without bundle ID)
    ///
    /// - Parameter layoutItem: The layout item to find
    /// - Returns: The matching IconItem, or nil if not found
    private func findIconItem(for layoutItem: SettingsLayoutItem) -> IconItem? {
        let result = iconMatcher.findIconItem(
            for: layoutItem,
            windowIDCache: windowIDCache,
            menuBarItems: nil  // Use live items
        )
        
        // Log the match method for debugging
        switch result.matchMethod {
        case .windowIDCache:
            logger.debug("[Match] Fast path: windowID cache hit for \(layoutItem.displayName)")
        case .exactMatch:
            logger.debug("[Match] Exact match for \(layoutItem.displayName)")
        case .bundleIDOnly:
            logger.debug("[Match] Bundle ID only match for \(layoutItem.displayName)")
        case .ownerName:
            logger.debug("[Match] Owner name fallback for \(layoutItem.displayName)")
        case .notFound:
            logger.warning("[Match] No match found for \(layoutItem.displayName)")
        case .spacer:
            logger.debug("[Match] Spacer item - no physical match needed")
        }
        
        return result.iconItem
    }

    /// Calculates the MoveDestination for a target section and insert index.
    ///
    /// Section boundaries are defined by Drawer's control items:
    /// - Visible section: items to the right of `hiddenControlItem`
    /// - Hidden section: items between `alwaysHiddenControlItem` and `hiddenControlItem`
    /// - Always Hidden: items to the left of `alwaysHiddenControlItem`
    ///
    /// Within a section, the destination is calculated relative to adjacent items.
    ///
    /// - Parameters:
    ///   - targetSection: The section to move to
    ///   - insertIndex: Position within the section (0 = leftmost)
    ///   - excludingItem: Item being moved (excluded from position calculations)
    /// - Returns: The MoveDestination, or nil if no valid destination found
    private func calculateDestination(
        for targetSection: MenuBarSectionType,
        at insertIndex: Int,
        excludingItem: IconItem
    ) -> MoveDestination? {
        // Get all current menu bar items
        let allItems = IconItem.getMenuBarItems(onScreenOnly: false, activeSpaceOnly: true)
            .filter { $0.windowID != excludingItem.windowID }

        // Find Drawer's control items (section separators)
        let hiddenControlItem = allItems.first { $0.identifier == .hiddenControlItem }
        let alwaysHiddenControlItem = allItems.first { $0.identifier == .alwaysHiddenControlItem }

        // Get items in the target section (sorted left-to-right by frame.minX)
        let sectionItems = getSectionItems(
            for: targetSection,
            from: allItems,
            hiddenControlItem: hiddenControlItem,
            alwaysHiddenControlItem: alwaysHiddenControlItem
        )

        // Calculate destination based on section and index
        switch targetSection {
        case .visible:
            // Visible items are to the RIGHT of hiddenControlItem
            if insertIndex == 0 {
                // Insert at start of visible section (right of hidden control)
                if let controlItem = hiddenControlItem {
                    return .rightOfItem(controlItem)
                }
            } else if insertIndex <= sectionItems.count, let targetItem = sectionItems[safe: insertIndex - 1] {
                // Insert after existing item
                return .rightOfItem(targetItem)
            } else if let lastItem = sectionItems.last {
                // Insert at end
                return .rightOfItem(lastItem)
            } else if let controlItem = hiddenControlItem {
                // Empty section, place right of control
                return .rightOfItem(controlItem)
            }

        case .hidden:
            // Hidden items are between alwaysHiddenControlItem and hiddenControlItem
            if insertIndex == 0 {
                // Insert at start of hidden section (right of always-hidden control)
                if let controlItem = alwaysHiddenControlItem {
                    return .rightOfItem(controlItem)
                }
            } else if insertIndex <= sectionItems.count, let targetItem = sectionItems[safe: insertIndex - 1] {
                // Insert after existing item
                return .rightOfItem(targetItem)
            } else if let lastItem = sectionItems.last {
                // Insert at end (but before hidden control)
                return .rightOfItem(lastItem)
            } else if let controlItem = alwaysHiddenControlItem {
                // Empty section, place right of control
                return .rightOfItem(controlItem)
            }

        case .alwaysHidden:
            // Always-hidden items are to the LEFT of alwaysHiddenControlItem
            if let controlItem = alwaysHiddenControlItem {
                if insertIndex == 0 {
                    // Insert at start (leftmost in always-hidden)
                    if let firstItem = sectionItems.first {
                        return .leftOfItem(firstItem)
                    }
                    return .leftOfItem(controlItem)
                } else if insertIndex <= sectionItems.count, let targetItem = sectionItems[safe: insertIndex - 1] {
                    // Insert after existing item
                    return .rightOfItem(targetItem)
                } else {
                    // Insert at end (just before control item)
                    return .leftOfItem(controlItem)
                }
            }
        }

        return nil
    }

    /// Returns items belonging to a specific section based on control item positions.
    ///
    /// - Parameters:
    ///   - section: The section to get items for
    ///   - allItems: All menu bar items
    ///   - hiddenControlItem: Drawer's hidden section separator
    ///   - alwaysHiddenControlItem: Drawer's always-hidden section separator
    /// - Returns: Items in the specified section, sorted by X position (left to right)
    private func getSectionItems(
        for section: MenuBarSectionType,
        from allItems: [IconItem],
        hiddenControlItem: IconItem?,
        alwaysHiddenControlItem: IconItem?
    ) -> [IconItem] {
        let hiddenControlX = hiddenControlItem?.frame.minX ?? CGFloat.infinity
        let alwaysHiddenControlX = alwaysHiddenControlItem?.frame.minX ?? CGFloat.infinity

        return allItems.filter { item in
            // Skip control items themselves
            if item.identifier == .hiddenControlItem || item.identifier == .alwaysHiddenControlItem {
                return false
            }

            let itemX = item.frame.minX

            switch section {
            case .visible:
                // Visible: items to the right of hiddenControlItem
                return itemX > hiddenControlX
            case .hidden:
                // Hidden: items between alwaysHiddenControlItem and hiddenControlItem
                return itemX > alwaysHiddenControlX && itemX < hiddenControlX
            case .alwaysHidden:
                // Always Hidden: items to the left of alwaysHiddenControlItem
                return itemX < alwaysHiddenControlX
            }
        }.sorted { $0.frame.minX < $1.frame.minX }
    }

    /// Shows an error alert for repositioning failures.
    ///
    /// - Parameter error: The RepositionError that occurred
    private func showRepositionError(_ error: RepositionError) {
        // Create and show alert on main thread
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Could Not Move Icon"
        alert.informativeText = error.localizedDescription
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    /// Saves the current menu bar icon positions to persist across app restarts.
    ///
    /// After a successful repositioning, this method queries the current menu bar state
    /// and saves the icon positions for the affected section and related sections.
    ///
    /// - Parameter affectedSection: The section that was modified by the move
    @MainActor
    private func saveCurrentPositions(for affectedSection: MenuBarSectionType) async {
        // Small delay to let the menu bar fully settle after the move
        try? await Task.sleep(for: .milliseconds(100))

        // Get current menu bar items
        let allItems = IconItem.getMenuBarItems()
        guard !allItems.isEmpty else {
            logger.warning("No menu bar items found when saving positions")
            return
        }

        // Find control items to determine section boundaries
        let hiddenControlItem = allItems.first { $0.identifier == .hiddenControlItem }
        let alwaysHiddenControlItem = allItems.first { $0.identifier == .alwaysHiddenControlItem }

        // Save positions for all sections to ensure consistency
        // (moving an item affects both source and destination sections)
        for section in MenuBarSectionType.allCases {
            let sectionItems = getSectionItems(
                for: section,
                from: allItems,
                hiddenControlItem: hiddenControlItem,
                alwaysHiddenControlItem: alwaysHiddenControlItem
            )

            // Convert IconItems to IconIdentifiers (left-to-right order)
            let identifiers = sectionItems.map { $0.identifier }

            // Save to SettingsManager
            SettingsManager.shared.updateSavedPositions(for: section, icons: identifiers)
        }

        logger.info("Saved icon positions for all sections after moving to \(affectedSection.displayName)")
    }

    /// Refreshes the menu bar items by capturing icons from the menu bar.
    /// Uses IconCapturer to get real menu bar items with their images, then
    /// reconciles with the saved layout to preserve user's section assignments.
    ///
    /// Spec 5.6: Uses LayoutReconciler to ensure captured X-position order is used
    /// Spec 5.7: Stores windowIDCache for reliable icon matching during repositioning
    private func refreshItems() {
        isRefreshing = true
        errorMessage = nil

        Task {
            do {
                // Capture icons using IconCapturer
                let result = try await appState.iconCapturer.captureHiddenIcons(
                    menuBarManager: appState.menuBarManager
                )

                // Load saved layout for reconciliation
                let savedLayout = SettingsManager.shared.menuBarLayout

                // Spec 5.6: Use LayoutReconciler for correct ordering and section handling
                // Spec 5.7: reconciler populates windowIDCache for repositioning
                let reconciled = reconciler.reconcile(
                    capturedIcons: result.icons,
                    savedLayout: savedLayout
                )

                await MainActor.run {
                    layoutItems = reconciled.items
                    imageCache = reconciled.imageCache
                    windowIDCache = reconciled.windowIDCache  // Spec 5.7
                    isRefreshing = false
                    hasUnsavedChanges = false

                    #if DEBUG
                    let itemCount = reconciled.items.count
                    let matched = reconciled.matchedCount
                    let newItems = reconciled.newCount
                    logger.debug("Refreshed layout: \(itemCount) items (matched: \(matched), new: \(newItems), windowIDs: \(reconciled.windowIDCache.count))")
                    #endif
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isRefreshing = false
                    logger.error("Failed to capture icons: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Legacy Reconciliation (Removed)
    // The legacy reconcileLayout() and normalizeOrders() methods have been removed.
    // Reconciliation is now handled by LayoutReconciler.swift (Spec 5.6, 5.7)

    /// Resets all saved icon position preferences.
    ///
    /// Clears the saved positions from SettingsManager. Icons will remain
    /// in their current positions but will not be restored on next launch.
    private func resetIconPositions() {
        SettingsManager.shared.clearSavedPositions()
        logger.info("Reset icon positions - cleared all saved preferences")
    }

    /// Adds a spacer to the hidden section.
    ///
    /// Spacers are added to the Hidden section by default, at the end.
    /// Users can drag the spacer to other sections as needed.
    /// The spacer is persisted immediately to SettingsManager.
    private func addSpacer() {
        // Calculate order as one past the last item in Hidden section
        let hiddenItems = items(for: .hidden)
        let newOrder = (hiddenItems.last?.order ?? -1) + 1

        let newSpacer = SettingsLayoutItem.spacer(
            section: .hidden,
            order: newOrder
        )
        layoutItems.append(newSpacer)

        // Persist the new spacer immediately
        saveLayout()

        #if DEBUG
        logger.debug("Added spacer to Hidden section at order \(newOrder)")
        #endif
    }
}

// MARK: - Safe Array Subscript

/// Extension for safe array access, returns nil for out-of-bounds indices.
private extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0 && index < count else { return nil }
        return self[index]
    }
}

// MARK: - Preview

#Preview {
    SettingsMenuBarLayoutView()
        .frame(width: 500, height: 600)
        .environmentObject(AppState.shared)
}
