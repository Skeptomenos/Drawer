import SwiftUI
import AppKit

/// A section container showing items in a specific menu bar section.
/// Supports drag-and-drop for reordering items within and between sections.
///
/// Drop position detection:
/// - Uses a coordinate space to track mouse position relative to items
/// - Calculates insertion index based on horizontal position over items
/// - Shows visual drop indicator at the calculated insertion point
struct LayoutSectionView: View {

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
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.primary)

                Text("(\(items.count))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
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
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}
