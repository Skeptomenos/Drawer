//
//  OverlayContentView.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import SwiftUI

// MARK: - OverlayContentView

/// Horizontal strip of hidden icons, styled like the menu bar.
/// Displays DrawerItems in a compact horizontal layout suitable for
/// rendering at menu bar level as an alternative to expand mode.
struct OverlayContentView: View {

    // MARK: - Properties

    let items: [DrawerItem]
    let onItemTap: ((DrawerItem) -> Void)?

    @State private var hoveredItemId: UUID?

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                OverlayIconView(
                    item: item,
                    isHovered: hoveredItemId == item.id,
                    onTap: { onItemTap?(item) }
                )
                .onHover { isHovered in
                    hoveredItemId = isHovered ? item.id : nil
                }
            }
        }
        .padding(.horizontal, 4)
        .frame(height: NSStatusBar.system.thickness)
        .background(OverlayBackground())
    }
}

// MARK: - OverlayIconView

/// Individual icon in the overlay panel.
/// Displays a captured menu bar icon with hover and press states.
struct OverlayIconView: View {

    // MARK: - Properties

    let item: DrawerItem
    let isHovered: Bool
    let onTap: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            Image(decorative: item.image, scale: NSScreen.main?.backingScaleFactor ?? 2.0)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 18, height: 18)
        }
        .buttonStyle(OverlayIconButtonStyle(isHovered: isHovered))
        .frame(width: 24, height: 22)
    }
}

// MARK: - OverlayIconButtonStyle

/// Button style matching menu bar icon appearance.
/// Provides subtle hover and pressed state backgrounds.
struct OverlayIconButtonStyle: ButtonStyle {

    let isHovered: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(backgroundColor(configuration: configuration))
            )
    }

    private func backgroundColor(configuration: Configuration) -> Color {
        if configuration.isPressed {
            return Color.primary.opacity(0.15)
        } else if isHovered {
            return Color.primary.opacity(0.08)
        }
        return .clear
    }
}

// MARK: - OverlayBackground

/// Menu bar style background using NSVisualEffectView.
/// Provides the translucent material effect matching macOS menu bar.
struct OverlayBackground: View {

    var body: some View {
        OverlayVisualEffectView(material: .menu, blendingMode: .behindWindow)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - OverlayVisualEffectView

/// NSVisualEffectView bridged to SwiftUI for overlay panel background.
struct OverlayVisualEffectView: NSViewRepresentable {

    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        view.wantsLayer = true
        view.layer?.cornerRadius = 6
        view.layer?.masksToBounds = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - Preview

#if DEBUG
struct OverlayContentView_Previews: PreviewProvider {
    static var previews: some View {
        OverlayContentView(
            items: [],
            onItemTap: nil
        )
        .frame(width: 200)
    }
}
#endif
