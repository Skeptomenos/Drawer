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

    /// Icon size in section containers
    static let iconSize: CGFloat = 16

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

    /// Items for display, populated from IconCapturer
    @State private var layoutItems: [SettingsLayoutItem] = []

    /// Cache mapping layout item IDs to captured CGImages
    @State private var imageCache: [UUID: CGImage] = [:]

    /// Whether a refresh is in progress
    @State private var isRefreshing: Bool = false

    /// Error message if capture fails
    @State private var errorMessage: String?

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
    }

    /// Refreshes the menu bar items by capturing icons from the menu bar.
    /// Uses IconCapturer to get real menu bar items with their images.
    private func refreshItems() {
        isRefreshing = true
        errorMessage = nil

        Task {
            do {
                // Capture icons using IconCapturer
                let result = try await appState.iconCapturer.captureHiddenIcons(
                    menuBarManager: appState.menuBarManager
                )

                // Convert CapturedIcons to SettingsLayoutItems and cache images
                var newItems: [SettingsLayoutItem] = []
                var newImageCache: [UUID: CGImage] = [:]

                for (index, capturedIcon) in result.icons.enumerated() {
                    // Create SettingsLayoutItem from captured icon
                    if let layoutItem = SettingsLayoutItem.from(
                        capturedIcon: capturedIcon,
                        section: capturedIcon.sectionType,
                        order: index
                    ) {
                        newItems.append(layoutItem)
                        // Cache the image using the layout item's ID
                        newImageCache[layoutItem.id] = capturedIcon.image
                    }
                }

                await MainActor.run {
                    layoutItems = newItems
                    imageCache = newImageCache
                    isRefreshing = false

                    #if DEBUG
                    logger.debug("Refreshed layout with \(newItems.count) items")
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

    /// Adds a spacer to the hidden section
    private func addSpacer() {
        // TODO: Phase 4.2.4 - Implement spacer addition
        // For now, add a spacer to the hidden section
        let newSpacer = SettingsLayoutItem.spacer(
            section: .hidden,
            order: items(for: .hidden).count
        )
        layoutItems.append(newSpacer)
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
                    LayoutItemView(item: item, image: imageCache[item.id])
                        .draggable(item)
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
private struct LayoutItemView: View {

    // MARK: - Properties

    /// The layout item to display
    let item: SettingsLayoutItem

    /// The cached image for this item (nil if not available)
    let image: CGImage?

    // MARK: - Body

    var body: some View {
        Group {
            if item.isSpacer {
                spacerView
            } else if let cgImage = image {
                iconImageView(cgImage)
            } else {
                iconPlaceholder
            }
        }
        .help(item.displayName)
    }

    /// Displays the actual captured icon image
    private func iconImageView(_ cgImage: CGImage) -> some View {
        Image(
            decorative: cgImage,
            scale: NSScreen.main?.backingScaleFactor ?? LayoutDesign.defaultScaleFactor
        )
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: LayoutDesign.iconSize, height: LayoutDesign.iconSize)
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
