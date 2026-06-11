//
//  ScreenCapture.swift
//  Drawer
//
//  Utilities for capturing screen content and menu bar items.
//  Based on Ice (https://github.com/jordanbaird/Ice) implementation.
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import CoreGraphics
import Foundation
import ScreenCaptureKit

enum ScreenCapture {

    private static var cachedPermissionResult: Bool?

    static func checkPermissions() -> Bool {
        for item in MenuBarItem.getMenuBarItems(onScreenOnly: false, activeSpaceOnly: true) {
            if item.window.owningApplication == .current { continue }
            return item.title != nil
        }
        return CGPreflightScreenCaptureAccess()
    }

    static func cachedCheckPermissions() -> Bool {
        if let cached = cachedPermissionResult {
            return cached
        }
        let result = checkPermissions()
        cachedPermissionResult = result
        return result
    }

    static func invalidatePermissionCache() {
        cachedPermissionResult = nil
    }

    static func requestPermissions() {
        if #available(macOS 15.0, *) {
            SCShareableContent.getWithCompletionHandler { _, _ in }
        } else {
            CGRequestScreenCaptureAccess()
        }
    }

    /// - Warning: Backed by the deprecated `CGWindowListCreateImage` machinery
    ///   (see `LegacyWindowImageProvider` below). Migration to ScreenCaptureKit
    ///   per-window capture is planned (hardening roadmap Phase 5).
    ///   Do not add new call sites.
    static func captureWindows(
        _ windowIDs: [CGWindowID],
        screenBounds: CGRect? = nil,
        option: CGWindowImageOption = []
    ) -> CGImage? {
        guard !windowIDs.isEmpty else { return nil }

        let pointer = UnsafeMutablePointer<UnsafeRawPointer?>.allocate(capacity: windowIDs.count)
        defer { pointer.deallocate() }

        for (index, windowID) in windowIDs.enumerated() {
            pointer[index] = UnsafeRawPointer(bitPattern: UInt(windowID))
        }

        guard let windowArray = CFArrayCreate(kCFAllocatorDefault, pointer, windowIDs.count, nil) else {
            return nil
        }

        let provider: any WindowImageProviding = LegacyWindowImageProvider()
        return provider.makeImage(
            windowArray: windowArray,
            screenBounds: screenBounds ?? .null,
            option: option
        )
    }

    static func captureMenuBarItems(
        _ items: [MenuBarItem],
        on screen: NSScreen
    ) -> [MenuBarItemInfo: CGImage] {
        var images = [MenuBarItemInfo: CGImage]()
        let backingScaleFactor = screen.backingScaleFactor
        let displayBounds = CGDisplayBounds(screen.displayID)

        var itemInfos = [CGWindowID: MenuBarItemInfo]()
        var itemFrames = [CGWindowID: CGRect]()
        var windowIDs = [CGWindowID]()
        var unionFrame = CGRect.null

        for item in items {
            let windowID = item.windowID
            guard
                let itemFrame = Bridging.getWindowFrame(for: windowID),
                itemFrame.minY == displayBounds.minY
            else { continue }

            itemInfos[windowID] = item.info
            itemFrames[windowID] = itemFrame
            windowIDs.append(windowID)
            unionFrame = unionFrame.union(itemFrame)
        }

        guard !windowIDs.isEmpty else { return [:] }

        guard let compositeImage = captureWindows(
            windowIDs,
            option: [.boundsIgnoreFraming, .bestResolution]
        ) else {
            return [:]
        }

        // Use integer comparison to avoid floating-point precision issues.
        // CGImage.width is Int, so round the expected width for comparison.
        let expectedWidth = Int((unionFrame.width * backingScaleFactor).rounded())
        guard compositeImage.width == expectedWidth else {
            return [:]
        }

        for windowID in windowIDs {
            guard
                let itemInfo = itemInfos[windowID],
                let itemFrame = itemFrames[windowID]
            else { continue }

            let cropRect = CGRect(
                x: (itemFrame.origin.x - unionFrame.origin.x) * backingScaleFactor,
                y: (itemFrame.origin.y - unionFrame.origin.y) * backingScaleFactor,
                width: itemFrame.width * backingScaleFactor,
                height: itemFrame.height * backingScaleFactor
            )

            if let itemImage = compositeImage.cropping(to: cropRect) {
                images[itemInfo] = itemImage
            }
        }

        return images
    }
}

// MARK: - Deprecation Firewall

/// Isolates the deprecated `CGImage(windowListFromArrayScreenBounds:)` call so the
/// deprecation warning is silenced at exactly one audited location.
///
/// Calling a deprecated API through a protocol witness whose conformance is itself
/// marked deprecated suppresses the diagnostic without `-Wno-deprecated` and without
/// hiding future deprecations elsewhere in the file.
///
/// Remove this entire section when `ScreenCapture.captureWindows` migrates to
/// ScreenCaptureKit (hardening roadmap Phase 5).
private protocol WindowImageProviding {
    func makeImage(
        windowArray: CFArray,
        screenBounds: CGRect,
        option: CGWindowImageOption
    ) -> CGImage?
}

private struct LegacyWindowImageProvider: WindowImageProviding {
    @available(macOS, deprecated: 14.0, message: "Firewall for CGWindowListCreateImage; migrate to ScreenCaptureKit (Phase 5).")
    func makeImage(
        windowArray: CFArray,
        screenBounds: CGRect,
        option: CGWindowImageOption
    ) -> CGImage? {
        CGImage(
            windowListFromArrayScreenBounds: screenBounds,
            windowArray: windowArray,
            imageOption: option
        )
    }
}

// MARK: - NSScreen Extension

extension NSScreen {
    var displayID: CGDirectDisplayID {
        guard let screenNumber = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
            return CGMainDisplayID()
        }
        return CGDirectDisplayID(screenNumber.uint32Value)
    }
}
