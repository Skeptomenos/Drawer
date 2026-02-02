//
//  DrawerBackgroundView.swift
//  Drawer
//
//  Extracted from DrawerPanelController.swift per ARCH-001 (one type per file).
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import SwiftUI

/// NSViewRepresentable that provides the drawer's frosted glass background.
///
/// Uses NSVisualEffectView with `.hudWindow` material for a translucent,
/// system-consistent appearance that adapts to light/dark mode.
struct DrawerBackgroundView: NSViewRepresentable {

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.state = .active
        view.wantsLayer = true
        view.layer?.cornerRadius = DrawerDesign.cornerRadius
        view.layer?.masksToBounds = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
