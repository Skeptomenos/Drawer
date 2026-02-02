import SwiftUI

/// Design constants for the menu bar layout settings view.
/// Based on reference image: specs/reference_images/settings-layout.jpg
enum LayoutDesign {
    /// Corner radius for section containers
    static let sectionCornerRadius: CGFloat = 10

    /// Padding inside section containers
    static let sectionPadding: CGFloat = 12

    /// Minimum height for section containers
    static let sectionMinHeight: CGFloat = 50

    /// Spacing between section header and container
    static let sectionHeaderSpacing: CGFloat = 8

    /// Spacing between sections
    static let sectionSpacing: CGFloat = 16

    /// Icon size in section containers (matches macOS menu bar icon size)
    static let iconSize: CGFloat = 22

    /// Spacing between icons
    static let iconSpacing: CGFloat = 8

    /// Header icon size
    static let headerIconSize: CGFloat = 48

    /// Drop indicator width
    static let dropIndicatorWidth: CGFloat = 2

    /// Item hit zone padding for easier drop targets
    static let itemDropPadding: CGFloat = 4

    /// Default scale factor for icon rendering (used when NSScreen.main is unavailable)
    static let defaultScaleFactor: CGFloat = 2.0
}
