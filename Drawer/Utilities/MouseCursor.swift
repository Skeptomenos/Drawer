//
//  MouseCursor.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import CoreGraphics

/// Utilities for managing the mouse cursor during repositioning operations.
enum MouseCursor {
    /// Returns the current cursor location in CoreGraphics screen coordinates.
    static var location: CGPoint? {
        CGEvent(source: nil)?.location
    }
    
    /// Hides the mouse cursor.
    static func hide() {
        CGDisplayHideCursor(CGMainDisplayID())
    }
    
    /// Shows the mouse cursor.
    static func show() {
        CGDisplayShowCursor(CGMainDisplayID())
    }
    
    /// Warps (teleports) the cursor to the specified location.
    ///
    /// - Parameter point: The target location in screen coordinates.
    static func warp(to point: CGPoint) {
        CGWarpMouseCursorPosition(point)
    }
}
