import SwiftUI
import AppKit

/// A single item in the layout editor (icon with actual image or spacer).
/// Immovable items (system icons like Control Center, Clock) display a lock indicator
/// and are rendered at 50% opacity.
struct LayoutItemView: View {

    // MARK: - Properties

    /// The layout item to display
    let item: SettingsLayoutItem

    /// The cached image for this item (nil if not available)
    let image: CGImage?

    // MARK: - Design Constants

    /// Size of the lock icon overlay
    private let lockIconSize: CGFloat = 8

    /// Padding around the lock icon
    private let lockIconPadding: CGFloat = 2

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if item.isSpacer {
                    spacerView
                } else if let cgImage = image {
                    iconImageView(cgImage)
                } else {
                    iconPlaceholder
                }
            }
            .opacity(item.isImmovable ? 0.5 : 1.0)

            // Lock indicator for immovable items
            if item.isImmovable {
                Image(systemName: "lock.fill")
                    .font(.system(size: lockIconSize, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(lockIconPadding)
            }
        }
        .help(item.isImmovable ? "This item cannot be moved by macOS" : item.displayName)
    }

    /// Displays the actual captured icon image
    private func iconImageView(_ cgImage: CGImage) -> some View {
        Image(
            decorative: cgImage,
            scale: NSScreen.main?.backingScaleFactor ?? LayoutDesign.defaultScaleFactor
        )
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: LayoutDesign.iconSize, height: LayoutDesign.iconSize)
    }

    /// Placeholder shown when image is not available
    private var iconPlaceholder: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.gray.opacity(0.3))
            .frame(width: LayoutDesign.iconSize, height: LayoutDesign.iconSize)
    }

    /// Visual representation of a spacer
    private var spacerView: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.accentColor.opacity(0.5))
            .frame(width: 8, height: LayoutDesign.iconSize)
    }
}
