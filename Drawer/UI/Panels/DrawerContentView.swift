//
//  DrawerContentView.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import os.log
import SwiftUI

// MARK: - DrawerContentView

/// The main content view displayed inside the Drawer panel.
/// Renders captured menu bar icons in a horizontal layout with proper styling.
/// Supports section headers for "Always Hidden" and "Hidden" sections.
struct DrawerContentView: View {

    // MARK: - Logger

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.drawer",
        category: "DrawerContentView"
    )

    // MARK: - Properties

    /// The drawer items to display
    let items: [DrawerItem]

    /// Whether items are currently being loaded
    let isLoading: Bool

    /// Error that occurred during capture, if any
    let error: Error?

    /// Optional action when an item is tapped
    var onItemTap: ((DrawerItem) -> Void)?

    // MARK: - Computed Properties

    /// Items in the always-hidden section
    private var alwaysHiddenItems: [DrawerItem] {
        items.filter { $0.sectionType == .alwaysHidden }
    }

    /// Items in the hidden section
    private var hiddenItems: [DrawerItem] {
        items.filter { $0.sectionType == .hidden }
    }

    /// Whether to show section headers (only when always-hidden section has items)
    private var showSectionHeaders: Bool {
        !alwaysHiddenItems.isEmpty
    }

    // MARK: - Initialization

    init(
        items: [DrawerItem] = [],
        isLoading: Bool = false,
        error: Error? = nil,
        onItemTap: ((DrawerItem) -> Void)? = nil
    ) {
        self.items = items
        self.isLoading = isLoading
        self.error = error
        self.onItemTap = onItemTap
    }

    /// Convenience initializer from CapturedIcons
    init(
        icons: [CapturedIcon],
        isLoading: Bool = false,
        error: Error? = nil,
        onItemTap: ((DrawerItem) -> Void)? = nil
    ) {
        self.items = icons.toDrawerItems()
        self.isLoading = isLoading
        self.error = error
        self.onItemTap = onItemTap
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: DrawerDesign.iconSpacing) {
            if isLoading {
                loadingView
            } else if let error = error {
                errorView(error)
            } else if items.isEmpty {
                emptyStateView
            } else {
                itemsView
            }
        }
        .padding(.horizontal, DrawerDesign.horizontalPadding)
        .padding(.vertical, DrawerDesign.verticalPadding)
        .frame(minHeight: DrawerDesign.drawerHeight)
    }

    // MARK: - Subviews

    /// Renders the actual drawer items, grouped by section when applicable
    @ViewBuilder
    private var itemsView: some View {
        if showSectionHeaders {
            sectionedItemsView
        } else {
            flatItemsView
        }
    }

    /// Renders items with section headers
    private var sectionedItemsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Always Hidden section
            if !alwaysHiddenItems.isEmpty {
                SectionHeader(title: "Always Hidden")
                IconRow(items: alwaysHiddenItems, onItemTap: onItemTap)
            }

            // Hidden section
            if !hiddenItems.isEmpty {
                if !alwaysHiddenItems.isEmpty {
                    Divider()
                }
                SectionHeader(title: "Hidden")
                IconRow(items: hiddenItems, onItemTap: onItemTap)
            }
        }
    }

    /// Renders items without section headers (flat layout)
    private var flatItemsView: some View {
        ForEach(items) { item in
            Button {
                onItemTap?(item)
            } label: {
                DrawerItemView(item: item)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Menu bar icon \(item.index + 1)")
            .accessibilityHint("Double tap to activate")
        }
    }

    /// Loading indicator while capturing icons
    private var loadingView: some View {
        HStack(spacing: DrawerDesign.iconSpacing) {
            ProgressView()
                .scaleEffect(0.7)
                .frame(width: DrawerDesign.iconSize, height: DrawerDesign.iconSize)

            Text("Capturing...")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }

    /// Error state when capture fails
    private func errorView(_ error: Error) -> some View {
        #if DEBUG
        Self.logger.error("Capture failed: \(error.localizedDescription)")
        #endif

        return HStack(spacing: DrawerDesign.iconSpacing) {
            Image(systemName: "exclamationmark.triangle")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.orange)

            Text("Capture failed")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }

    /// Empty state when no icons are available
    private var emptyStateView: some View {
        HStack(spacing: DrawerDesign.iconSpacing) {
            ForEach(0..<5, id: \.self) { index in
                placeholderIcon(for: index)
            }
        }
    }

    /// Creates a placeholder icon for empty state
    private func placeholderIcon(for index: Int) -> some View {
        let iconNames = ["wifi", "battery.100", "speaker.wave.2", "clock", "gear"]
        let iconName = iconNames[index % iconNames.count]

        return Circle()
            .fill(Color.white.opacity(0.15))
            .frame(width: DrawerDesign.iconSize - 4, height: DrawerDesign.iconSize - 4)
            .overlay(
                Image(systemName: iconName)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.6))
            )
    }
}

// MARK: - Preview

#Preview("Empty State") {
    DrawerContentView(items: [])
        .frame(height: DrawerDesign.drawerHeight)
        .background(Color.black.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: DrawerDesign.cornerRadius, style: .continuous))
        .padding()
}

#Preview("Loading") {
    DrawerContentView(items: [], isLoading: true)
        .frame(height: DrawerDesign.drawerHeight)
        .background(Color.black.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: DrawerDesign.cornerRadius, style: .continuous))
        .padding()
}

#Preview("Error State") {
    DrawerContentView(items: [], isLoading: false, error: CaptureError.permissionDenied)
        .frame(height: DrawerDesign.drawerHeight)
        .background(Color.black.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: DrawerDesign.cornerRadius, style: .continuous))
        .padding()
}

#Preview("With Mock Icons") {
    DrawerContentView(items: PreviewHelpers.createMockDrawerItems(count: 5))
        .frame(height: DrawerDesign.drawerHeight)
        .background(Color.black.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: DrawerDesign.cornerRadius, style: .continuous))
        .padding()
}

#Preview("With Many Icons") {
    DrawerContentView(items: PreviewHelpers.createMockDrawerItems(count: 10))
        .frame(height: DrawerDesign.drawerHeight)
        .background(Color.black.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: DrawerDesign.cornerRadius, style: .continuous))
        .padding()
}

#Preview("Full Container") {
    DrawerContainerView {
        DrawerContentView(
            items: PreviewHelpers.createMockDrawerItems(count: 6),
            onItemTap: { item in
                print("Tapped item \(item.index)")
            }
        )
    }
    .padding()
}

// MARK: - Preview Helpers

/// Helpers for creating mock data in Xcode Previews
enum PreviewHelpers {

    /// Creates a solid color CGImage for testing
    /// - Parameters:
    ///   - color: The fill color
    ///   - size: The image size in points
    /// - Returns: A CGImage filled with the specified color
    static func createTestImage(color: NSColor = .white, size: CGSize = CGSize(width: 22, height: 22)) -> CGImage? {
        let scale: CGFloat = 2.0
        let pixelWidth = Int(size.width * scale)
        let pixelHeight = Int(size.height * scale)

        guard let context = CGContext(
            data: nil,
            width: pixelWidth,
            height: pixelHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        // Fill with color
        context.setFillColor(color.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: pixelWidth, height: pixelHeight))

        // Draw a simple icon shape (circle with inner detail)
        let centerX = CGFloat(pixelWidth) / 2
        let centerY = CGFloat(pixelHeight) / 2
        let radius = min(centerX, centerY) * 0.8

        // Outer circle
        context.setFillColor(NSColor.white.withAlphaComponent(0.9).cgColor)
        context.fillEllipse(in: CGRect(
            x: centerX - radius,
            y: centerY - radius,
            width: radius * 2,
            height: radius * 2
        ))

        // Inner detail
        let innerRadius = radius * 0.4
        context.setFillColor(NSColor.gray.cgColor)
        context.fillEllipse(in: CGRect(
            x: centerX - innerRadius,
            y: centerY - innerRadius,
            width: innerRadius * 2,
            height: innerRadius * 2
        ))

        return context.makeImage()
    }

    /// Creates an array of mock DrawerItems for preview
    /// - Parameter count: Number of items to create
    /// - Returns: Array of DrawerItems with test images
    static func createMockDrawerItems(count: Int) -> [DrawerItem] {
        let colors: [NSColor] = [
            .systemBlue, .systemGreen, .systemOrange, .systemPink,
            .systemPurple, .systemRed, .systemTeal, .systemYellow,
            .systemIndigo, .systemBrown
        ]

        return (0..<count).compactMap { index in
            let color = colors[index % colors.count]
            guard let image = createTestImage(color: color) else { return nil }

            return DrawerItem(
                image: image,
                originalFrame: CGRect(
                    x: CGFloat(index) * 30,
                    y: 0,
                    width: 22,
                    height: 22
                ),
                index: index
            )
        }
    }
}
