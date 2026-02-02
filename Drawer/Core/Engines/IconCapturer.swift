//
//  IconCapturer.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import Combine
import Foundation
import os.log
import ScreenCaptureKit

// MARK: - CaptureError

enum CaptureError: Error, LocalizedError {
    case permissionDenied
    case menuBarNotFound
    case captureFailedNoImage
    case screenNotFound
    case invalidRegion
    case noMenuBarItems
    case systemError(Error)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Screen Recording permission is required to capture menu bar icons"
        case .menuBarNotFound:
            return "Could not locate the menu bar window"
        case .captureFailedNoImage:
            return "Screen capture returned no image"
        case .screenNotFound:
            return "Could not find the main screen"
        case .invalidRegion:
            return "The capture region is invalid"
        case .noMenuBarItems:
            return "No menu bar items found to capture"
        case .systemError(let error):
            return "System error: \(error.localizedDescription)"
        }
    }
}

// MARK: - CapturedIcon

struct CapturedIcon: Identifiable {
    let id: UUID
    let image: CGImage
    let originalFrame: CGRect
    let capturedAt: Date
    let itemInfo: MenuBarItemInfo?
    /// The menu bar section this icon belongs to (hidden, alwaysHidden, or visible)
    let sectionType: MenuBarSectionType

    init(
        image: CGImage,
        originalFrame: CGRect,
        itemInfo: MenuBarItemInfo? = nil,
        sectionType: MenuBarSectionType = .hidden
    ) {
        self.id = UUID()
        self.image = image
        self.originalFrame = originalFrame
        self.capturedAt = Date()
        self.itemInfo = itemInfo
        self.sectionType = sectionType
    }
}

// MARK: - MenuBarCaptureResult

struct MenuBarCaptureResult {
    let fullImage: CGImage
    let icons: [CapturedIcon]
    let capturedRegion: CGRect
    let capturedAt: Date
    let menuBarItems: [MenuBarItem]
}

// MARK: - IconCapturer

@MainActor
final class IconCapturer: ObservableObject {

    static let shared = IconCapturer()

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.drawer", category: "IconCapturer")

    private let permissionManager: any PermissionProviding

    @Published private(set) var isCapturing: Bool = false
    @Published private(set) var lastCaptureResult: MenuBarCaptureResult?
    @Published private(set) var lastError: CaptureError?

    private var menuBarHeight: CGFloat { MenuBarMetrics.height }
    private let renderWaitTime: UInt64 = 50_000_000

    init(permissionManager: any PermissionProviding = PermissionManager.shared) {
        self.permissionManager = permissionManager
    }

    #if DEBUG
    func setIsCapturingForTesting(_ value: Bool) {
        isCapturing = value
    }
    #endif

    // MARK: - Public API

    func captureHiddenIcons(menuBarManager: MenuBarManager) async throws -> MenuBarCaptureResult {
        guard !isCapturing else {
            logger.warning("Capture already in progress, skipping")
            throw CaptureError.systemError(NSError(domain: "IconCapturer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Capture already in progress"]))
        }

        isCapturing = true
        lastError = nil

        defer {
            isCapturing = false
        }

        guard permissionManager.hasScreenRecording else {
            logger.error("Screen Recording permission denied")
            let error = CaptureError.permissionDenied
            lastError = error
            throw error
        }

        logger.debug("Expanding menu bar for capture")
        let wasCollapsed = menuBarManager.isCollapsed
        if wasCollapsed {
            menuBarManager.expand()
        }

        logger.debug("Waiting for menu bar to render")
        try await Task.sleep(nanoseconds: renderWaitTime)

        // Get separator positions for section type detection
        let hiddenSeparatorX = menuBarManager.hiddenSection.controlItem.button?.window?.frame.origin.x ?? 0
        let alwaysHiddenSeparatorX: CGFloat? = menuBarManager.alwaysHiddenSection?.controlItem.button?.window?.frame.origin.x

        let captureResult: MenuBarCaptureResult
        do {
            captureResult = try await performWindowBasedCapture(
                hiddenSeparatorX: hiddenSeparatorX,
                alwaysHiddenSeparatorX: alwaysHiddenSeparatorX
            )
            logger.info("Capture successful: \(captureResult.icons.count) icons captured using window-based detection")

            #if DEBUG
            logger.debug("=== CAPTURE RESULT DEBUG (B1.1) ===")
            logger.debug("Total icons: \(captureResult.icons.count)")
            let region = captureResult.capturedRegion
            // swiftlint:disable:next line_length
            logger.debug("Captured region: x=\(region.origin.x), y=\(region.origin.y), w=\(region.width), h=\(region.height)")
            logger.debug("Menu bar items found: \(captureResult.menuBarItems.count)")

            for (index, icon) in captureResult.icons.enumerated() {
                let frame = icon.originalFrame
                let ownerName = icon.itemInfo?.ownerName ?? "unknown"
                // swiftlint:disable:next line_length
                logger.debug("Icon \(index): frame=(\(frame.origin.x),\(frame.origin.y),\(frame.width),\(frame.height)), image=\(icon.image.width)x\(icon.image.height), owner=\(ownerName)")
            }
            logger.debug("=== END CAPTURE DEBUG ===")
            #endif
        } catch {
            if wasCollapsed {
                menuBarManager.collapse()
            }
            throw error
        }

        if wasCollapsed {
            logger.debug("Collapsing menu bar after capture")
            menuBarManager.collapse()
        }

        lastCaptureResult = captureResult
        return captureResult
    }

    func captureMenuBarRegion() async throws -> CGImage {
        guard permissionManager.hasScreenRecording else {
            throw CaptureError.permissionDenied
        }

        return try await captureUsingScreenCaptureKit()
    }

    // MARK: - Window-Based Capture (New Implementation)

    private func performWindowBasedCapture(
        hiddenSeparatorX: CGFloat,
        alwaysHiddenSeparatorX: CGFloat?
    ) async throws -> MenuBarCaptureResult {
        guard let screen = NSScreen.main else {
            throw CaptureError.screenNotFound
        }

        #if DEBUG
        logger.debug("=== WINDOW-BASED CAPTURE DEBUG (B1.1) ===")
        logger.debug("Screen: \(screen.localizedName), displayID: \(screen.displayID)")
        #endif

        let menuBarItems = MenuBarItem.getMenuBarItemsForDisplay(screen.displayID)

        #if DEBUG
        logger.debug("MenuBarItem.getMenuBarItemsForDisplay returned \(menuBarItems.count) items")
        for (index, item) in menuBarItems.enumerated() {
            let frame = item.frame
            let ownerName = item.ownerName ?? "nil"
            // swiftlint:disable:next line_length
            logger.debug("  [\(index)] windowID=\(item.windowID), owner=\(ownerName), frame=(\(frame.origin.x),\(frame.origin.y),\(frame.width),\(frame.height))")
        }
        #endif

        guard !menuBarItems.isEmpty else {
            logger.warning("No menu bar items found, falling back to ScreenCaptureKit")
            return try await performLegacyCapture()
        }

        logger.debug("Found \(menuBarItems.count) menu bar item windows")

        let imagesByInfo = ScreenCapture.captureMenuBarItems(menuBarItems, on: screen)

        #if DEBUG
        logger.debug("ScreenCapture.captureMenuBarItems returned \(imagesByInfo.count) images")
        for (info, image) in imagesByInfo {
            logger.debug("  Captured: owner=\(info.ownerName ?? "nil"), windowID=\(info.windowID), size=\(image.width)x\(image.height)")
        }
        #endif

        guard !imagesByInfo.isEmpty else {
            logger.warning("Window-based capture returned no images, falling back to ScreenCaptureKit")
            return try await performLegacyCapture()
        }

        var icons: [CapturedIcon] = []
        var unionFrame = CGRect.null

        for item in menuBarItems {
            if let image = imagesByInfo[item.info] {
                let sectionType = determineSectionType(
                    for: item.frame,
                    hiddenSeparatorX: hiddenSeparatorX,
                    alwaysHiddenSeparatorX: alwaysHiddenSeparatorX
                )
                let icon = CapturedIcon(
                    image: image,
                    originalFrame: item.frame,
                    itemInfo: item.info,
                    sectionType: sectionType
                )
                icons.append(icon)
                unionFrame = unionFrame.union(item.frame)
            }
        }

        let fullImage: CGImage
        if let compositeImage = createCompositeImage(from: icons, unionFrame: unionFrame, screen: screen) {
            fullImage = compositeImage
        } else {
            fullImage = try await captureUsingScreenCaptureKit()
        }

        return MenuBarCaptureResult(
            fullImage: fullImage,
            icons: icons,
            capturedRegion: unionFrame,
            capturedAt: Date(),
            menuBarItems: menuBarItems
        )
    }

    func createCompositeImage(from icons: [CapturedIcon], unionFrame: CGRect, screen: NSScreen) -> CGImage? {
        guard !icons.isEmpty else { return nil }

        let scale = screen.backingScaleFactor
        let width = Int(unionFrame.width * scale)
        let height = Int(unionFrame.height * scale)

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

        for icon in icons {
            let drawRect = CGRect(
                x: (icon.originalFrame.origin.x - unionFrame.origin.x) * scale,
                y: (icon.originalFrame.origin.y - unionFrame.origin.y) * scale,
                width: icon.originalFrame.width * scale,
                height: icon.originalFrame.height * scale
            )
            context.draw(icon.image, in: drawRect)
        }

        return context.makeImage()
    }

    // MARK: - Legacy Capture (Fallback)

    private func performLegacyCapture() async throws -> MenuBarCaptureResult {
        let image = try await captureUsingScreenCaptureKit()

        guard let screen = NSScreen.main else {
            throw CaptureError.screenNotFound
        }

        let capturedRegion = CGRect(
            x: 0,
            y: screen.frame.height - menuBarHeight,
            width: screen.frame.width,
            height: menuBarHeight
        )

        let icons = sliceIconsUsingFixedWidth(from: image)

        return MenuBarCaptureResult(
            fullImage: image,
            icons: icons,
            capturedRegion: capturedRegion,
            capturedAt: Date(),
            menuBarItems: []
        )
    }

    private func captureUsingScreenCaptureKit() async throws -> CGImage {
        logger.debug("Capturing using ScreenCaptureKit")

        let content: SCShareableContent
        do {
            content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        } catch {
            logger.error("Failed to get shareable content: \(error.localizedDescription)")
            throw CaptureError.systemError(error)
        }

        guard let display = content.displays.first(where: { $0.displayID == CGMainDisplayID() }) else {
            logger.error("Could not find main display")
            throw CaptureError.screenNotFound
        }

        let scale = NSScreen.main?.backingScaleFactor ?? 2.0
        let menuBarRect = CGRect(
            x: 0,
            y: 0,
            width: CGFloat(display.width),
            height: menuBarHeight * scale
        )

        let filter = SCContentFilter(display: display, excludingWindows: [])

        let config = SCStreamConfiguration()
        config.width = Int(menuBarRect.width)
        config.height = Int(menuBarRect.height)
        config.sourceRect = menuBarRect
        config.scalesToFit = false
        config.showsCursor = false
        config.captureResolution = .best

        do {
            let image = try await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: config
            )
            logger.debug("ScreenCaptureKit capture successful")
            return image
        } catch {
            logger.error("ScreenCaptureKit capture failed: \(error.localizedDescription)")
            throw CaptureError.systemError(error)
        }
    }

    // MARK: - Fixed-Width Slicing (Legacy Fallback)

    private let standardIconWidth: CGFloat = 22
    private let iconSpacing: CGFloat = 4

    func sliceIconsUsingFixedWidth(from image: CGImage) -> [CapturedIcon] {
        var icons: [CapturedIcon] = []

        let imageWidth = CGFloat(image.width)
        let imageHeight = CGFloat(image.height)
        let scale = NSScreen.main?.backingScaleFactor ?? 2.0

        let iconWidthPixels = standardIconWidth * scale
        let spacingPixels = iconSpacing * scale
        let stepSize = iconWidthPixels + spacingPixels

        var currentX: CGFloat = 0
        while currentX + iconWidthPixels <= imageWidth {
            guard !Task.isCancelled else { break }
            
            let cropRect = CGRect(
                x: currentX,
                y: 0,
                width: iconWidthPixels,
                height: imageHeight
            )

            if let croppedImage = image.cropping(to: cropRect) {
                let originalFrame = CGRect(
                    x: currentX / scale,
                    y: 0,
                    width: standardIconWidth,
                    height: imageHeight / scale
                )

                let icon = CapturedIcon(image: croppedImage, originalFrame: originalFrame)
                icons.append(icon)
            }

            currentX += stepSize

            if icons.count >= 50 {
                logger.warning("Hit icon limit (50), stopping slice")
                break
            }
        }

        logger.debug("Sliced \(icons.count) icons using fixed-width fallback")
        return icons
    }

    func clearLastCapture() {
        lastCaptureResult = nil
        lastError = nil
    }

    // MARK: - Section Type Detection

    /// Determines which menu bar section an icon belongs to based on its X position
    /// relative to the separator positions.
    /// - Parameters:
    ///   - frame: The icon's frame in screen coordinates
    ///   - hiddenSeparatorX: X position of the hidden section separator
    ///   - alwaysHiddenSeparatorX: X position of the always-hidden separator (nil if disabled)
    /// - Returns: The section type this icon belongs to
    func determineSectionType(
        for frame: CGRect,
        hiddenSeparatorX: CGFloat,
        alwaysHiddenSeparatorX: CGFloat?
    ) -> MenuBarSectionType {
        let iconCenterX = frame.midX

        // If always-hidden section exists and icon is to its left
        if let alwaysHiddenX = alwaysHiddenSeparatorX, iconCenterX < alwaysHiddenX {
            return .alwaysHidden
        }

        // If icon is to the left of the hidden separator
        if iconCenterX < hiddenSeparatorX {
            return .hidden
        }

        return .visible
    }
}
