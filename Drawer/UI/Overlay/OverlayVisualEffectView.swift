//
//  OverlayVisualEffectView.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import SwiftUI

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
