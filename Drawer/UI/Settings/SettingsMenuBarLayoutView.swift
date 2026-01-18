//
//  SettingsMenuBarLayoutView.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import os.log
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Reconciliation Result

/// Result of reconciling captured icons with saved layout.
private struct ReconciliationResult {
    /// Reconciled layout items
    let items: [SettingsLayoutItem]
    /// Cache mapping item IDs to captured images
    let imageCache: [UUID: CGImage]
    /// Number of items matched from saved layout
    let matchedCount: Int
    /// Number of new items not found in saved layout
    let newCount: Int
}

// MARK: - Design Constants

/// Design constants for the menu bar layout settings view.
/// Based on reference image: specs/reference_images/settings-layout.jpg
private enum LayoutDesign {
    /// Corner radius for section containers
    static let sectionCornerRadius: CGFloat = 10

    /// Padding inside section containers
    static let sectionPadding: CGFloat = 12

    /// Minimum height for section containers
    static let sectionMinHeight: CGFloat = 50

    /// Spacing between section header and container
    static let sectionHeaderSpacing: CGFloat = 8

    /// Spacing between sections
    static let sectionSpacing: CGFloat = 16

    /// Icon size in section containers (matches macOS menu bar icon size)
    static let iconSize: CGFloat = 22

    /// Spacing between icons
    static let iconSpacing: CGFloat = 8

    /// Header icon size
    static let headerIconSize: CGFloat = 48

    /// Drop indicator width
    static let dropIndicatorWidth: CGFloat = 2

    /// Item hit zone padding for easier drop targets
    static let itemDropPadding: CGFloat = 4

    /// Default scale factor for icon rendering (used when NSScreen.main is unavailable)
    static let defaultScaleFactor: CGFloat = 2.0
}

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
                .foregroundColor(.orange)

            Text(message)
                .font(.system(size: 12))
                .foregroundColor(.secondary)

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
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                    }

                    Text("Menu Bar Items")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Drag items between sections to re-order your menu bar")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
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
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .buttonStyle(.plain)
        .disabled(isRefreshing)
        .padding(8)
    }

    // MARK: - Palette Section

    /// Palette with action buttons for adding spacers
    private var paletteSection: some View {
        VStack(alignment: .leading, spacing: LayoutDesign.sectionHeaderSpacing) {
            Label("Palette", systemImage: "square.grid.2x2")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)

            HStack(spacing: 12) {
                Button {
                    addSpacer()
                } label: {
                    Text("Add a Spacer")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

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

    /// Refreshes the menu bar items by capturing icons from the menu bar.
    /// Uses IconCapturer to get real menu bar items with their images, then
    /// reconciles with the saved layout to preserve user's section assignments.
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

                // Reconcile captured icons with saved layout
                let reconciled = reconcileLayout(
                    capturedIcons: result.icons,
                    savedLayout: savedLayout
                )

                await MainActor.run {
                    layoutItems = reconciled.items
                    imageCache = reconciled.imageCache
                    isRefreshing = false
                    hasUnsavedChanges = false

                    #if DEBUG
                    let itemCount = reconciled.items.count
                    let matched = reconciled.matchedCount
                    let newItems = reconciled.newCount
                    logger.debug("Refreshed layout: \(itemCount) items (matched: \(matched), new: \(newItems))")
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

    /// Reconciles captured icons with saved layout to preserve user's section assignments.
    ///
    /// Algorithm:
    /// 1. For each captured icon, try to find a matching saved item (by bundle ID + title)
    /// 2. If found, use the saved section and order (user's preference)
    /// 3. If not found, use the captured icon's section (new icon, first time seen)
    /// 4. Spacers from saved layout are preserved
    ///
    /// - Parameters:
    ///   - capturedIcons: Icons captured from the current menu bar state
    ///   - savedLayout: Previously saved layout items
    /// - Returns: Reconciled layout items with image cache and statistics
    private func reconcileLayout(
        capturedIcons: [CapturedIcon],
        savedLayout: [SettingsLayoutItem]
    ) -> ReconciliationResult {
        var reconciledItems: [SettingsLayoutItem] = []
        var newImageCache: [UUID: CGImage] = [:]
        var matchedCount = 0
        var newCount = 0

        // Track which saved items have been matched to avoid duplicates
        var matchedSavedItemIds: Set<UUID> = []

        // Process each captured icon
        for capturedIcon in capturedIcons {
            // Try to find a matching saved item
            if let matchingSaved = savedLayout.first(where: { saved in
                !matchedSavedItemIds.contains(saved.id) && saved.matches(capturedIcon: capturedIcon)
            }) {
                // Use saved section/order but create new item with fresh ID for SwiftUI
                let reconciledItem = SettingsLayoutItem(
                    bundleIdentifier: matchingSaved.bundleIdentifier ?? "",
                    title: matchingSaved.title,
                    section: matchingSaved.section,
                    order: matchingSaved.order
                )
                reconciledItems.append(reconciledItem)
                newImageCache[reconciledItem.id] = capturedIcon.image
                matchedSavedItemIds.insert(matchingSaved.id)
                matchedCount += 1
            } else {
                // New icon not in saved layout - use captured section
                if let newItem = SettingsLayoutItem.from(
                    capturedIcon: capturedIcon,
                    section: capturedIcon.sectionType,
                    order: reconciledItems.count
                ) {
                    reconciledItems.append(newItem)
                    newImageCache[newItem.id] = capturedIcon.image
                    newCount += 1
                }
            }
        }

        // Preserve spacers from saved layout
        for savedItem in savedLayout where savedItem.isSpacer {
            reconciledItems.append(savedItem)
        }

        // Normalize orders within each section to prevent gaps
        reconciledItems = normalizeOrders(reconciledItems)

        return ReconciliationResult(
            items: reconciledItems,
            imageCache: newImageCache,
            matchedCount: matchedCount,
            newCount: newCount
        )
    }

    /// Normalizes order values within each section to be sequential (0, 1, 2, ...).
    /// This prevents order values from growing unboundedly after repeated insertions.
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

// MARK: - LayoutSectionView

/// A section container showing items in a specific menu bar section.
/// Supports drag-and-drop for reordering items within and between sections.
///
/// Drop position detection:
/// - Uses a coordinate space to track mouse position relative to items
/// - Calculates insertion index based on horizontal position over items
/// - Shows visual drop indicator at the calculated insertion point
private struct LayoutSectionView: View {

    // MARK: - Properties

    /// The section type this view represents
    let sectionType: MenuBarSectionType

    /// Items in this section
    let items: [SettingsLayoutItem]

    /// Cache of images keyed by layout item ID
    let imageCache: [UUID: CGImage]

    /// Callback when an item is moved to this section
    var onMoveItem: (SettingsLayoutItem, MenuBarSectionType, Int) -> Void

    // MARK: - State

    /// Whether the section is currently a drop target
    @State private var isDropTargeted: Bool = false

    /// Index where drop would occur (-1 if no active drop target)
    @State private var dropInsertIndex: Int = -1

    /// Tracks the geometry of each item for drop position calculation
    @State private var itemFrames: [UUID: CGRect] = [:]

    // MARK: - Private Constants

    /// Namespace for coordinate space calculations
    private let coordinateSpaceName = "sectionCoordinateSpace"

    // MARK: - Computed Properties

    /// SF Symbol name for the section icon
    private var sectionIcon: String {
        switch sectionType {
        case .visible:
            return "circle.circle"
        case .hidden:
            return "eye.slash"
        case .alwaysHidden:
            return "xmark.circle"
        }
    }

    /// Display name for the section
    private var sectionTitle: String {
        switch sectionType {
        case .visible:
            return "Shown Items"
        case .hidden:
            return "Hidden Items"
        case .alwaysHidden:
            return "Always Hidden Items"
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: LayoutDesign.sectionHeaderSpacing) {
            // Section header with item count
            HStack {
                Label(sectionTitle, systemImage: sectionIcon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)

                Text("(\(items.count))")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            // Section container with drop support
            sectionContainer
        }
    }

    /// The container showing items or empty state with drop support
    private var sectionContainer: some View {
        HStack(spacing: 0) {
            if items.isEmpty {
                emptyStateView
            } else {
                // Leading drop indicator (before first item)
                dropIndicator(at: 0)

                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    itemView(for: item)
                        .background(
                            GeometryReader { geometry in
                                Color.clear
                                    .preference(
                                        key: ItemFramePreferenceKey.self,
                                        value: [item.id: geometry.frame(in: .named(coordinateSpaceName))]
                                    )
                            }
                        )
                        .padding(.horizontal, LayoutDesign.iconSpacing / 2)

                    // Drop indicator after each item
                    dropIndicator(at: index + 1)
                }
            }

            Spacer(minLength: 0)
        }
        .coordinateSpace(name: coordinateSpaceName)
        .onPreferenceChange(ItemFramePreferenceKey.self) { frames in
            itemFrames = frames
        }
        .padding(LayoutDesign.sectionPadding)
        .frame(maxWidth: .infinity, minHeight: LayoutDesign.sectionMinHeight, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: LayoutDesign.sectionCornerRadius)
                .fill(isDropTargeted
                    ? Color.accentColor.opacity(0.15)
                    : Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutDesign.sectionCornerRadius)
                .stroke(isDropTargeted ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .dropDestination(for: SettingsLayoutItem.self) { droppedItems, _ in
            // Handle drop: move first dropped item to this section at calculated index
            guard let item = droppedItems.first else { return false }

            // Use the calculated insert index, or append at end if not determined
            let insertIndex = dropInsertIndex >= 0 ? dropInsertIndex : items.count
            onMoveItem(item, sectionType, insertIndex)

            // Reset drop state
            dropInsertIndex = -1
            return true
        } isTargeted: { targeted in
            isDropTargeted = targeted
            if !targeted {
                dropInsertIndex = -1
            }
        }
        .onDrop(of: [.settingsLayoutItem], delegate: DropPositionDelegate(
            items: items,
            itemFrames: itemFrames,
            dropInsertIndex: $dropInsertIndex
        ))
    }

    /// Creates the item view with conditional draggable modifier.
    /// Immovable items (system icons) cannot be dragged.
    /// - Parameter item: The layout item to display
    /// - Returns: The item view, optionally with .draggable() modifier
    @ViewBuilder
    private func itemView(for item: SettingsLayoutItem) -> some View {
        let layoutItemView = LayoutItemView(item: item, image: imageCache[item.id])
        if item.isImmovable {
            layoutItemView
        } else {
            layoutItemView.draggable(item)
        }
    }

    /// Visual drop indicator shown between items during drag
    /// - Parameter index: The insertion index this indicator represents
    @ViewBuilder
    private func dropIndicator(at index: Int) -> some View {
        if isDropTargeted && dropInsertIndex == index {
            RoundedRectangle(cornerRadius: LayoutDesign.dropIndicatorWidth / 2)
                .fill(Color.accentColor)
                .frame(width: LayoutDesign.dropIndicatorWidth, height: LayoutDesign.iconSize + 4)
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
                .animation(.easeInOut(duration: 0.15), value: dropInsertIndex)
        } else {
            // Invisible spacer to maintain layout consistency
            Color.clear
                .frame(width: LayoutDesign.dropIndicatorWidth, height: LayoutDesign.iconSize)
        }
    }

    /// Empty state shown when section has no items
    private var emptyStateView: some View {
        Text("Drop items here")
            .font(.system(size: 12))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

// MARK: - ItemFramePreferenceKey

/// Preference key for collecting item frames for drop position calculation
private struct ItemFramePreferenceKey: PreferenceKey {
    static var defaultValue: [UUID: CGRect] = [:]

    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}

// MARK: - DropPositionDelegate

/// Drop delegate that calculates insertion index based on drop location.
/// Updates `dropInsertIndex` during drag to show the visual indicator.
private struct DropPositionDelegate: DropDelegate {

    /// Items in the section (ordered)
    let items: [SettingsLayoutItem]

    /// Cached frames of each item in coordinate space
    let itemFrames: [UUID: CGRect]

    /// Binding to the drop insert index for visual feedback
    @Binding var dropInsertIndex: Int

    func dropUpdated(info: DropInfo) -> DropProposal? {
        // Calculate insert index based on horizontal position
        let dropLocation = info.location
        dropInsertIndex = calculateInsertIndex(at: dropLocation)
        return DropProposal(operation: .move)
    }

    func dropExited(info: DropInfo) {
        // Keep the last valid index for the actual drop operation
        // The dropDestination handler will use this value
    }

    func performDrop(info: DropInfo) -> Bool {
        // Let the dropDestination handler perform the actual drop
        // This delegate is only for position tracking
        return false
    }

    func validateDrop(info: DropInfo) -> Bool {
        return true
    }

    /// Calculates the insertion index based on the drop point's horizontal position.
    /// - Parameter point: The drop location in the section's coordinate space
    /// - Returns: The index at which to insert the dropped item
    private func calculateInsertIndex(at point: CGPoint) -> Int {
        guard !items.isEmpty else { return 0 }

        // Sort items by their horizontal position (left to right)
        let sortedFrames = items.compactMap { item -> (Int, CGRect)? in
            guard let frame = itemFrames[item.id],
                  let index = items.firstIndex(where: { $0.id == item.id }) else {
                return nil
            }
            return (index, frame)
        }.sorted { $0.1.minX < $1.1.minX }

        // Find the insertion point based on horizontal position
        for (itemIndex, frame) in sortedFrames {
            let midX = frame.midX
            if point.x < midX {
                return itemIndex
            }
        }

        // If past all items, insert at end
        return items.count
    }
}

// MARK: - LayoutItemView

/// A single item in the layout editor (icon with actual image or spacer).
/// Immovable items (system icons like Control Center, Clock) display a lock indicator
/// and are rendered at 50% opacity.
private struct LayoutItemView: View {

    // MARK: - Properties

    /// The layout item to display
    let item: SettingsLayoutItem

    /// The cached image for this item (nil if not available)
    let image: CGImage?

    // MARK: - Design Constants

    /// Size of the lock icon overlay
    private let lockIconSize: CGFloat = 8

    /// Padding around the lock icon
    private let lockIconPadding: CGFloat = 2

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if item.isSpacer {
                    spacerView
                } else if let cgImage = image {
                    iconImageView(cgImage)
                } else {
                    iconPlaceholder
                }
            }
            .opacity(item.isImmovable ? 0.5 : 1.0)

            // Lock indicator for immovable items
            if item.isImmovable {
                Image(systemName: "lock.fill")
                    .font(.system(size: lockIconSize, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(lockIconPadding)
            }
        }
        .help(item.isImmovable ? "This item cannot be moved by macOS" : item.displayName)
    }

    /// Displays the actual captured icon image
    private func iconImageView(_ cgImage: CGImage) -> some View {
        Image(
            decorative: cgImage,
            scale: NSScreen.main?.backingScaleFactor ?? LayoutDesign.defaultScaleFactor
        )
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(height: LayoutDesign.iconSize)
    }

    /// Placeholder shown when image is not available
    private var iconPlaceholder: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.gray.opacity(0.3))
            .frame(width: LayoutDesign.iconSize, height: LayoutDesign.iconSize)
    }

    /// Visual representation of a spacer
    private var spacerView: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.accentColor.opacity(0.5))
            .frame(width: 8, height: LayoutDesign.iconSize)
    }
}

// MARK: - Preview

#Preview {
    SettingsMenuBarLayoutView()
        .frame(width: 500, height: 600)
        .environmentObject(AppState.shared)
}
