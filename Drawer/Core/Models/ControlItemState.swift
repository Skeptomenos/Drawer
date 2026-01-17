//
//  ControlItemState.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import Foundation

/// Represents the visual state of a control item in the menu bar.
enum ControlItemState: String, CaseIterable {
    /// Item is expanded (separator at small length, icons visible)
    case expanded

    /// Item is collapsed (separator at 10k length, icons hidden)
    case collapsed

    /// Item is completely hidden from the menu bar
    case hidden
}
