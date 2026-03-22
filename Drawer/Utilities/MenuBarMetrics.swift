//
//  MenuBarMetrics.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit

enum MenuBarMetrics {

    static var height: CGFloat {
        height(for: NSScreen.main)
    }
    
    static func height(for screen: NSScreen?) -> CGFloat {
        guard let screen = screen else { return fallbackHeight }
        let menuBarHeight = screen.frame.height - screen.visibleFrame.height - screen.visibleFrame.origin.y
        return max(menuBarHeight, fallbackHeight)
    }

    static let fallbackHeight: CGFloat = 24
}
