//
//  DrawerItem.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import CoreGraphics
import Foundation

// MARK: - DrawerItem

/// Represents a single item displayed in the Drawer.
///
/// This model wraps a captured icon image with additional metadata
/// needed for rendering and interaction in the Drawer UI.
struct DrawerItem: Identifiable, Equatable {

    // MARK: - Properties

    /// Unique identifier for this drawer item
    let id: UUID

    /// The captured icon image
    let image: CGImage

    /// The original position of this icon in the menu bar (screen coordinates)
    let originalFrame: CGRect

    /// When this icon was captured
    let capturedAt: Date

    /// Index of this item in the drawer (for ordering)
    let index: Int

    // MARK: - Initialization

    /// Creates a DrawerItem from a CapturedIcon
    /// - Parameters:
    ///   - capturedIcon: The captured icon data
    ///   - index: The position index in the drawer
    init(from capturedIcon: CapturedIcon, index: Int) {
        self.id = capturedIcon.id
        self.image = capturedIcon.image
        self.originalFrame = capturedIcon.originalFrame
        self.capturedAt = capturedIcon.capturedAt
        self.index = index
    }

    /// Creates a DrawerItem directly
    /// - Parameters:
    ///   - image: The icon image
    ///   - originalFrame: The original position in the menu bar
    ///   - index: The position index in the drawer
    init(image: CGImage, originalFrame: CGRect, index: Int) {
        self.id = UUID()
        self.image = image
        self.originalFrame = originalFrame
        self.capturedAt = Date()
        self.index = index
    }

    // MARK: - Equatable

    static func == (lhs: DrawerItem, rhs: DrawerItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - DrawerItem + Convenience

extension DrawerItem {

    /// The center X position of this icon in the original menu bar
    var originalCenterX: CGFloat {
        originalFrame.midX
    }

    /// The center Y position of this icon in the original menu bar
    var originalCenterY: CGFloat {
        originalFrame.midY
    }

    /// The click target point for this icon in CGEvent coordinates (top-left origin).
    /// Note: `originalFrame` from CGWindowList is already in Quartz display coordinates
    /// (top-left origin), so no conversion is needed for CGEvent usage.
    var clickTarget: CGPoint {
        CGPoint(x: originalCenterX, y: originalCenterY)
    }
}

// MARK: - Array Extension

extension Array where Element == CapturedIcon {

    /// Converts an array of CapturedIcons to DrawerItems
    func toDrawerItems() -> [DrawerItem] {
        enumerated().map { index, icon in
            DrawerItem(from: icon, index: index)
        }
    }
}
