//
//  DrawerContainerView.swift
//  Drawer
//
//  Extracted from DrawerPanelController.swift per ARCH-001 (one type per file).
//
//  Copyright © 2026 Drawer. MIT License.
//

import SwiftUI

/// Container view that wraps drawer content with styling.
///
/// Applies consistent drawer styling: fixed height, background blur,
/// rounded corners, rim light overlay, and drop shadow.
struct DrawerContainerView<Content: View>: View {

    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(height: DrawerDesign.drawerHeight)
            .background(DrawerBackgroundView())
            .clipShape(RoundedRectangle(cornerRadius: DrawerDesign.cornerRadius, style: .continuous))
            .overlay(rimLight)
            .shadow(
                color: Color.black.opacity(DrawerDesign.shadowOpacity),
                radius: DrawerDesign.shadowRadius,
                x: 0,
                y: DrawerDesign.shadowYOffset
            )
    }

    private var rimLight: some View {
        RoundedRectangle(cornerRadius: DrawerDesign.cornerRadius, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Color.white.opacity(DrawerDesign.rimLightOpacity),
                        Color.white.opacity(DrawerDesign.rimLightOpacity * 0.5)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: DrawerDesign.rimLightWidth
            )
    }
}
