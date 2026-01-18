//
//  SettingsMenuBarLayoutView.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

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

    // MARK: - State

    /// Items for display (will be replaced with real data from IconCapturer in Phase 4.2)
    @State private var layoutItems: [SettingsLayoutItem] = []

    /// Whether a refresh is in progress
    @State private var isRefreshing: Bool = false

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LayoutDesign.sectionSpacing) {
                headerSection

                ForEach(MenuBarSectionType.allCases) { sectionType in
                    LayoutSectionView(
                        sectionType: sectionType,
                        items: items(for: sectionType),
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

    /// Refreshes the menu bar items
    private func refreshItems() {
        isRefreshing = true

        // TODO: Phase 4.2 - Integrate with IconCapturer to get real items
        // For now, simulate a refresh delay
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            await MainActor.run {
                isRefreshing = false
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
/// Supports drag-and-drop for reordering items between sections.
private struct LayoutSectionView: View {

    // MARK: - Properties

    /// The section type this view represents
    let sectionType: MenuBarSectionType

    /// Items in this section
    let items: [SettingsLayoutItem]

    /// Callback when an item is moved to this section
    var onMoveItem: (SettingsLayoutItem, MenuBarSectionType, Int) -> Void

    // MARK: - State

    /// Whether the section is currently a drop target
    @State private var isDropTargeted: Bool = false

    /// Index where drop would occur (-1 if none)
    @State private var dropInsertIndex: Int = -1

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
            // Section header
            Label(sectionTitle, systemImage: sectionIcon)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)

            // Section container with drop support
            sectionContainer
        }
    }

    /// The container showing items or empty state with drop support
    private var sectionContainer: some View {
        HStack(spacing: LayoutDesign.iconSpacing) {
            if items.isEmpty {
                emptyStateView
            } else {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    LayoutItemView(item: item)
                        .draggable(item)
                }
            }

            Spacer(minLength: 0)
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
            // Handle drop: move first dropped item to this section
            guard let item = droppedItems.first else { return false }
            onMoveItem(item, sectionType, items.count)
            return true
        } isTargeted: { targeted in
            isDropTargeted = targeted
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

// MARK: - LayoutItemView

/// A single item in the layout editor (icon placeholder or spacer).
private struct LayoutItemView: View {

    // MARK: - Properties

    /// The layout item to display
    let item: SettingsLayoutItem

    // MARK: - Body

    var body: some View {
        Group {
            if item.isSpacer {
                spacerView
            } else {
                iconPlaceholder
            }
        }
        .help(item.displayName)
    }

    /// Placeholder for menu bar icon
    /// In Phase 4.2, this will show the actual captured icon image
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
}
