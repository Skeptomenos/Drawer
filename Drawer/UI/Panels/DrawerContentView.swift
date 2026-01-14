//
//  DrawerContentView.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import SwiftUI

// MARK: - Design Constants

/// Visual design constants for the Drawer, based on reference image analysis.
/// See: specs/reference_images/icon-drawer.jpg
enum DrawerDesign {
    /// Horizontal spacing between icons (10pt)
    static let iconSpacing: CGFloat = 10
    
    /// Horizontal padding at leading/trailing edges (16pt)
    static let horizontalPadding: CGFloat = 16
    
    /// Vertical padding at top/bottom (7pt - midpoint of 6-8pt range)
    static let verticalPadding: CGFloat = 7
    
    /// Standard icon size (22pt x 22pt)
    static let iconSize: CGFloat = 22
    
    /// Corner radius for the drawer container (11pt - midpoint of 10-12pt range)
    static let cornerRadius: CGFloat = 11
    
    /// Rim light border width (1pt)
    static let rimLightWidth: CGFloat = 1
    
    /// Rim light opacity (17.5% - midpoint of 15-20% range)
    static let rimLightOpacity: Double = 0.175
    
    /// Shadow radius (12pt - midpoint of 10-15pt range)
    static let shadowRadius: CGFloat = 12
    
    /// Shadow Y offset (3pt - midpoint of 2-4pt range)
    static let shadowYOffset: CGFloat = 3
    
    /// Shadow opacity
    static let shadowOpacity: Double = 0.3
    
    /// Overall drawer height (34pt - midpoint of 32-36pt range)
    static let drawerHeight: CGFloat = 34
}

// MARK: - DrawerContentView

/// The main content view displayed inside the Drawer panel.
/// Renders captured menu bar icons in a horizontal layout with proper styling.
struct DrawerContentView: View {
    
    // MARK: - Properties
    
    /// The drawer items to display
    let items: [DrawerItem]
    
    /// Whether items are currently being loaded
    let isLoading: Bool
    
    /// Optional action when an item is tapped
    var onItemTap: ((DrawerItem) -> Void)?
    
    // MARK: - Initialization
    
    init(
        items: [DrawerItem] = [],
        isLoading: Bool = false,
        onItemTap: ((DrawerItem) -> Void)? = nil
    ) {
        self.items = items
        self.isLoading = isLoading
        self.onItemTap = onItemTap
    }
    
    /// Convenience initializer from CapturedIcons
    init(
        icons: [CapturedIcon],
        isLoading: Bool = false,
        onItemTap: ((DrawerItem) -> Void)? = nil
    ) {
        self.items = icons.toDrawerItems()
        self.isLoading = isLoading
        self.onItemTap = onItemTap
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: DrawerDesign.iconSpacing) {
            if isLoading {
                loadingView
            } else if items.isEmpty {
                emptyStateView
            } else {
                itemsView
            }
        }
        .padding(.horizontal, DrawerDesign.horizontalPadding)
        .padding(.vertical, DrawerDesign.verticalPadding)
        .frame(height: DrawerDesign.drawerHeight)
    }
    
    // MARK: - Subviews
    
    /// Renders the actual drawer items
    private var itemsView: some View {
        ForEach(items) { item in
            DrawerItemView(item: item)
                .onTapGesture {
                    onItemTap?(item)
                }
        }
    }
    
    /// Loading indicator while capturing icons
    private var loadingView: some View {
        HStack(spacing: DrawerDesign.iconSpacing) {
            ProgressView()
                .scaleEffect(0.7)
                .frame(width: DrawerDesign.iconSize, height: DrawerDesign.iconSize)
            
            Text("Capturing...")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
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
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            )
    }
}

// MARK: - DrawerItemView

/// Renders a single drawer item (captured icon)
struct DrawerItemView: View {
    
    let item: DrawerItem
    
    @State private var isHovered: Bool = false
    
    var body: some View {
        Image(decorative: item.image, scale: NSScreen.main?.backingScaleFactor ?? 2.0)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: DrawerDesign.iconSize, height: DrawerDesign.iconSize)
            .scaleEffect(isHovered ? 1.1 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
            .contentShape(Rectangle())
            .accessibilityLabel("Menu bar icon \(item.index + 1)")
            .accessibilityHint("Double tap to activate")
    }
}

// MARK: - Preview

#Preview("With Items") {
    DrawerContentView(items: [])
        .frame(height: DrawerDesign.drawerHeight)
        .background(Color.black.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: DrawerDesign.cornerRadius, style: .continuous))
        .padding()
}

#Preview("Empty State") {
    DrawerContentView(items: [], isLoading: false)
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
