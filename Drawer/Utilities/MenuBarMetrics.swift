//
//  MenuBarMetrics.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit

enum MenuBarMetrics {

    static var height: CGFloat {
        guard let screen = NSScreen.main else { return 24 }
        return screen.frame.height - screen.visibleFrame.height - screen.visibleFrame.origin.y
    }

    static let fallbackHeight: CGFloat = 24
}
