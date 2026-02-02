//
//  DrawerDesign.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import SwiftUI

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
