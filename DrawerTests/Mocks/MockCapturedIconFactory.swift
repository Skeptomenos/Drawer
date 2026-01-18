//
//  MockCapturedIconFactory.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import CoreGraphics
import Foundation

@testable import Drawer

// MARK: - MockCapturedIconFactory

/// Factory for creating test `CapturedIcon` instances with controllable properties.
///
/// This factory is used by `SettingsMenuBarLayoutViewTests` to create mock icons
/// with specific X-positions, section types, and metadata for testing:
/// - Spec 5.6: Ordering logic uses X-position as source of truth
/// - Spec 5.7: Icon matching uses windowID cache with multi-tier fallback
///
/// ## Usage
/// ```swift
/// let factory = MockCapturedIconFactory()
///
/// // Create icons at specific X positions
/// let iconA = factory.createIcon(bundleId: "com.apple.Safari", xPosition: 100)
/// let iconB = factory.createIcon(bundleId: "com.apple.Mail", xPosition: 200)
///
/// // Create icons in specific sections
/// let hiddenIcon = factory.createIcon(bundleId: "com.test.app", section: .hidden)
/// ```
final class MockCapturedIconFactory {

    // MARK: - Properties

    /// Counter for generating unique window IDs
    private var nextWindowID: CGWindowID = 1000

    /// Counter for generating unique PIDs
    private var nextPID: pid_t = 10000

    /// Default icon size (typical menu bar icon dimensions)
    let defaultIconSize: CGSize = CGSize(width: 22, height: 24)

    /// Default menu bar height
    let menuBarHeight: CGFloat = 24

    // MARK: - Initialization

    init() {}

    // MARK: - Icon Creation

    /// Creates a `CapturedIcon` with the specified properties.
    ///
    /// - Parameters:
    ///   - bundleId: The bundle identifier (e.g., "com.apple.Safari")
    ///   - title: Optional window title for disambiguation
    ///   - xPosition: The X coordinate for the icon's position (left edge)
    ///   - section: The menu bar section type (default: .hidden)
    ///   - windowID: Optional specific window ID (auto-generated if nil)
    ///   - ownerPID: Optional specific PID (auto-generated if nil)
    ///   - ownerName: Optional owner name (derived from bundleId if nil)
    /// - Returns: A `CapturedIcon` instance
    func createIcon(
        bundleId: String,
        title: String? = nil,
        xPosition: CGFloat,
        section: MenuBarSectionType = .hidden,
        windowID: CGWindowID? = nil,
        ownerPID: pid_t? = nil,
        ownerName: String? = nil
    ) -> CapturedIcon {
        let effectiveWindowID = windowID ?? generateWindowID()
        let effectivePID = ownerPID ?? generatePID()
        // Store bundle ID in ownerName so tests can extract it later
        // (since NSRunningApplication won't work with fake PIDs)
        let effectiveOwnerName = ownerName ?? bundleId

        let frame = CGRect(
            x: xPosition,
            y: 0,
            width: defaultIconSize.width,
            height: defaultIconSize.height
        )

        let itemInfo = MenuBarItemInfo(
            testWindowID: effectiveWindowID,
            ownerPID: effectivePID,
            ownerName: effectiveOwnerName,
            title: title
        )

        guard let image = createMockImage() else {
            fatalError("Failed to create mock image for test icon")
        }

        return CapturedIcon(
            image: image,
            originalFrame: frame,
            itemInfo: itemInfo,
            sectionType: section
        )
    }

    /// Creates a `CapturedIcon` without item info (simulates icons that couldn't be matched to a window).
    ///
    /// - Parameters:
    ///   - xPosition: The X coordinate for the icon's position
    ///   - section: The menu bar section type
    /// - Returns: A `CapturedIcon` with nil itemInfo
    func createIconWithoutInfo(
        xPosition: CGFloat,
        section: MenuBarSectionType = .hidden
    ) -> CapturedIcon {
        let frame = CGRect(
            x: xPosition,
            y: 0,
            width: defaultIconSize.width,
            height: defaultIconSize.height
        )

        guard let image = createMockImage() else {
            fatalError("Failed to create mock image for test icon")
        }

        return CapturedIcon(
            image: image,
            originalFrame: frame,
            itemInfo: nil,
            sectionType: section
        )
    }

    /// Creates multiple icons arranged left-to-right at even intervals.
    ///
    /// - Parameters:
    ///   - bundleIds: Array of bundle identifiers
    ///   - startX: Starting X position (default: 100)
    ///   - spacing: Space between icons (default: 26 = 22px icon + 4px gap)
    ///   - section: The menu bar section type
    /// - Returns: Array of `CapturedIcon` instances ordered by X position
    func createIconsInOrder(
        bundleIds: [String],
        startX: CGFloat = 100,
        spacing: CGFloat = 26,
        section: MenuBarSectionType = .hidden
    ) -> [CapturedIcon] {
        return bundleIds.enumerated().map { index, bundleId in
            createIcon(
                bundleId: bundleId,
                xPosition: startX + CGFloat(index) * spacing,
                section: section
            )
        }
    }

    /// Creates icons with explicit X positions (useful for testing out-of-order scenarios).
    ///
    /// - Parameters:
    ///   - items: Array of tuples containing (bundleId, xPosition)
    ///   - section: The menu bar section type
    /// - Returns: Array of `CapturedIcon` instances (NOT sorted - order matches input)
    func createIconsWithPositions(
        _ items: [(bundleId: String, xPosition: CGFloat)],
        section: MenuBarSectionType = .hidden
    ) -> [CapturedIcon] {
        return items.map { item in
            createIcon(
                bundleId: item.bundleId,
                xPosition: item.xPosition,
                section: section
            )
        }
    }

    /// Creates icons for a mixed-section scenario.
    ///
    /// - Parameters:
    ///   - items: Array of tuples containing (bundleId, xPosition, section)
    /// - Returns: Array of `CapturedIcon` instances
    func createIconsWithSections(
        _ items: [(bundleId: String, xPosition: CGFloat, section: MenuBarSectionType)]
    ) -> [CapturedIcon] {
        return items.map { item in
            createIcon(
                bundleId: item.bundleId,
                xPosition: item.xPosition,
                section: item.section
            )
        }
    }

    // MARK: - SettingsLayoutItem Creation

    /// Creates a `SettingsLayoutItem` that matches a given `CapturedIcon`.
    ///
    /// - Parameters:
    ///   - icon: The captured icon to create a layout item for
    ///   - sectionOverride: Optional section override (uses icon's section if nil)
    ///   - orderOverride: Optional order override (uses 0 if nil)
    /// - Returns: A `SettingsLayoutItem` matching the icon, or nil if icon has no itemInfo
    func createLayoutItem(
        from icon: CapturedIcon,
        sectionOverride: MenuBarSectionType? = nil,
        orderOverride: Int? = nil
    ) -> SettingsLayoutItem? {
        guard let itemInfo = icon.itemInfo else {
            return nil
        }

        // In tests, we can't use NSRunningApplication to get bundle ID from PID
        // So we need to extract from ownerName (which we set to app name in mock)
        // For tests, we store the bundle ID directly in ownerName
        let bundleId = itemInfo.ownerName ?? "unknown"

        return SettingsLayoutItem(
            bundleIdentifier: bundleId,
            title: itemInfo.title,
            section: sectionOverride ?? icon.sectionType,
            order: orderOverride ?? 0
        )
    }

    /// Creates multiple `SettingsLayoutItem`s with explicit ordering.
    ///
    /// - Parameters:
    ///   - icons: Array of captured icons
    ///   - section: The section to assign (default: .hidden)
    /// - Returns: Array of layout items with order set by array position
    func createLayoutItems(
        from icons: [CapturedIcon],
        section: MenuBarSectionType = .hidden
    ) -> [SettingsLayoutItem] {
        return icons.enumerated().compactMap { index, icon in
            createLayoutItem(from: icon, sectionOverride: section, orderOverride: index)
        }
    }

    // MARK: - Private Helpers

    /// Generates a unique window ID for each mock icon.
    private func generateWindowID() -> CGWindowID {
        let id = nextWindowID
        nextWindowID += 1
        return id
    }

    /// Generates a unique PID for each mock icon.
    private func generatePID() -> pid_t {
        let pid = nextPID
        nextPID += 1
        return pid
    }

    /// Extracts a simple app name from a bundle ID.
    ///
    /// For example: "com.apple.Safari" -> "Safari"
    private func bundleIdToAppName(_ bundleId: String) -> String {
        return bundleId.components(separatedBy: ".").last ?? bundleId
    }

    /// Creates a mock CGImage for test icons.
    ///
    /// - Parameters:
    ///   - width: Image width (default: 22)
    ///   - height: Image height (default: 24)
    /// - Returns: A valid CGImage, or nil if creation fails
    private func createMockImage(width: Int = 22, height: Int = 24) -> CGImage? {
        guard width > 0, height > 0 else { return nil }

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        // Fill with a gray color to simulate an icon
        context.setFillColor(CGColor(gray: 0.5, alpha: 1.0))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        return context.makeImage()
    }

    // MARK: - Reset

    /// Resets the factory's ID counters.
    /// Call between tests to ensure consistent IDs.
    func reset() {
        nextWindowID = 1000
        nextPID = 10000
    }
}

// MARK: - MenuBarItemInfo Test Extension

extension MenuBarItemInfo {
    /// Creates a `MenuBarItemInfo` directly for testing purposes.
    ///
    /// This initializer bypasses the normal `WindowInfo` requirement,
    /// allowing tests to create mock item info without real window data.
    ///
    /// - Parameters:
    ///   - windowID: The window ID
    ///   - ownerPID: The owner process ID
    ///   - ownerName: The owner application name
    ///   - title: The window title
    init(
        testWindowID windowID: CGWindowID,
        ownerPID: pid_t,
        ownerName: String?,
        title: String?
    ) {
        // Create a dictionary that can be parsed by WindowInfo
        let bounds: [String: CGFloat] = [
            "X": 0, "Y": 0, "Width": 22, "Height": 24
        ]

        var dict: [CFString: Any] = [
            kCGWindowNumber: windowID,
            kCGWindowBounds: bounds,
            kCGWindowLayer: kCGStatusWindowLevel,
            kCGWindowAlpha: 1.0,
            kCGWindowOwnerPID: ownerPID,
            kCGWindowIsOnscreen: true
        ]

        if let ownerName = ownerName {
            dict[kCGWindowOwnerName] = ownerName
        }

        if let title = title {
            dict[kCGWindowName] = title
        }

        // Create WindowInfo from dictionary
        guard let windowInfo = WindowInfo(dictionary: dict as CFDictionary) else {
            // Fallback: manually set properties (this path shouldn't be hit in tests)
            self.windowID = windowID
            self.ownerPID = ownerPID
            self.ownerName = ownerName
            self.title = title
            return
        }

        self.init(from: windowInfo)
    }
}
