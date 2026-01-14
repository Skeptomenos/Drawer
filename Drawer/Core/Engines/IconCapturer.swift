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

/// Errors that can occur during icon capture
enum CaptureError: Error, LocalizedError {
    case permissionDenied
    case menuBarNotFound
    case captureFailedNoImage
    case screenNotFound
    case invalidRegion
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
        case .systemError(let error):
            return "System error: \(error.localizedDescription)"
        }
    }
}

// MARK: - CapturedIcon

/// Represents a single captured menu bar icon
struct CapturedIcon: Identifiable {
    let id: UUID
    let image: CGImage
    let originalFrame: CGRect
    let capturedAt: Date
    
    init(image: CGImage, originalFrame: CGRect) {
        self.id = UUID()
        self.image = image
        self.originalFrame = originalFrame
        self.capturedAt = Date()
    }
}

// MARK: - MenuBarCaptureResult

/// Result of a menu bar capture operation
struct MenuBarCaptureResult {
    /// The full captured image of the hidden menu bar section
    let fullImage: CGImage
    
    /// Individual sliced icons (if slicing was performed)
    let icons: [CapturedIcon]
    
    /// The region that was captured (in screen coordinates)
    let capturedRegion: CGRect
    
    /// Timestamp of capture
    let capturedAt: Date
}

// MARK: - IconCapturer

/// Captures visual state of hidden menu bar icons using ScreenCaptureKit.
///
/// This is the most technically challenging component of Drawer. It:
/// 1. Temporarily expands the menu bar (shows hidden icons)
/// 2. Waits for the render to complete
/// 3. Captures the menu bar region
/// 4. Collapses the menu bar (hides icons again)
/// 5. Slices the captured image into individual icons
///
/// - Important: Requires Screen Recording permission.
@MainActor
final class IconCapturer: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = IconCapturer()
    
    // MARK: - Logger
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.drawer", category: "IconCapturer")
    
    // MARK: - Dependencies
    
    private let permissionManager: PermissionManager
    
    // MARK: - Published State
    
    @Published private(set) var isCapturing: Bool = false
    @Published private(set) var lastCaptureResult: MenuBarCaptureResult?
    @Published private(set) var lastError: CaptureError?
    
    // MARK: - Constants
    
    /// Standard menu bar icon width (22pt is typical)
    private let standardIconWidth: CGFloat = 22
    
    /// Standard spacing between icons
    private let iconSpacing: CGFloat = 4
    
    /// Menu bar height (standard is 24pt, but can be 37pt with notch)
    private let menuBarHeight: CGFloat = 24
    
    /// Time to wait for menu bar to render after expanding (in nanoseconds)
    /// ~2 frames at 60fps = 33ms
    private let renderWaitTime: UInt64 = 50_000_000 // 50ms for safety
    
    // MARK: - Initialization
    
    init(permissionManager: PermissionManager = .shared) {
        self.permissionManager = permissionManager
    }
    
    // MARK: - Public API
    
    /// Captures the hidden menu bar icons.
    ///
    /// This method:
    /// 1. Checks for Screen Recording permission
    /// 2. Expands the menu bar (via MenuBarManager)
    /// 3. Waits for render
    /// 4. Captures the menu bar region
    /// 5. Collapses the menu bar
    /// 6. Returns the captured image
    ///
    /// - Parameter menuBarManager: The MenuBarManager to control expand/collapse
    /// - Returns: The capture result containing the full image and sliced icons
    /// - Throws: CaptureError if capture fails
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
        
        // Step 1: Check permission
        guard permissionManager.hasScreenRecording else {
            logger.error("Screen Recording permission denied")
            let error = CaptureError.permissionDenied
            lastError = error
            throw error
        }
        
        // Step 2: Get the separator position BEFORE expanding (this is where hidden icons start)
        let separatorX = getSeparatorPosition(menuBarManager: menuBarManager)
        
        // Step 3: Expand menu bar to reveal hidden icons
        logger.debug("Expanding menu bar for capture")
        let wasCollapsed = menuBarManager.isCollapsed
        if wasCollapsed {
            menuBarManager.expand()
        }
        
        // Step 4: Wait for render
        logger.debug("Waiting for menu bar to render")
        try await Task.sleep(nanoseconds: renderWaitTime)
        
        // Step 5: Capture the menu bar region
        let captureResult: MenuBarCaptureResult
        do {
            captureResult = try await performCapture(separatorX: separatorX)
            logger.info("Capture successful: \(captureResult.icons.count) icons captured")
        } catch {
            // Collapse before throwing
            if wasCollapsed {
                menuBarManager.collapse()
            }
            throw error
        }
        
        // Step 6: Collapse menu bar
        if wasCollapsed {
            logger.debug("Collapsing menu bar after capture")
            menuBarManager.collapse()
        }
        
        lastCaptureResult = captureResult
        return captureResult
    }
    
    /// Captures the menu bar region without expanding/collapsing.
    /// Useful for testing or when menu bar is already expanded.
    func captureMenuBarRegion() async throws -> CGImage {
        guard permissionManager.hasScreenRecording else {
            throw CaptureError.permissionDenied
        }
        
        return try await captureUsingScreenCaptureKit()
    }
    
    // MARK: - Private Capture Methods
    
    private func getSeparatorPosition(menuBarManager: MenuBarManager) -> CGFloat? {
        // The separator position helps us know where the "hidden" section starts
        // This is used to calculate the capture region
        // For now, we'll capture the entire left portion of the menu bar
        return nil // Will be implemented when we have access to separator item position
    }
    
    private func performCapture(separatorX: CGFloat?) async throws -> MenuBarCaptureResult {
        // Try ScreenCaptureKit first, fall back to CGWindowList if needed
        let image: CGImage
        do {
            image = try await captureUsingScreenCaptureKit()
        } catch {
            logger.warning("Display capture failed, trying window filter fallback: \(error.localizedDescription)")
            image = try await captureUsingWindowFilter()
        }
        
        // Calculate the captured region
        guard let screen = NSScreen.main else {
            throw CaptureError.screenNotFound
        }
        
        let capturedRegion = CGRect(
            x: 0,
            y: screen.frame.height - menuBarHeight,
            width: screen.frame.width,
            height: menuBarHeight
        )
        
        // Slice into individual icons
        let icons = sliceIcons(from: image, separatorX: separatorX)
        
        return MenuBarCaptureResult(
            fullImage: image,
            icons: icons,
            capturedRegion: capturedRegion,
            capturedAt: Date()
        )
    }
    
    /// Captures the menu bar using ScreenCaptureKit (modern API, macOS 12.3+)
    private func captureUsingScreenCaptureKit() async throws -> CGImage {
        logger.debug("Capturing using ScreenCaptureKit")
        
        // Get available content
        let content: SCShareableContent
        do {
            content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        } catch {
            logger.error("Failed to get shareable content: \(error.localizedDescription)")
            throw CaptureError.systemError(error)
        }
        
        // Find the main display
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
        
        // Create a content filter for the display
        let filter = SCContentFilter(display: display, excludingWindows: [])
        
        // Configure the capture
        let config = SCStreamConfiguration()
        config.width = Int(menuBarRect.width)
        config.height = Int(menuBarRect.height)
        config.sourceRect = menuBarRect
        config.scalesToFit = false
        config.showsCursor = false
        config.captureResolution = .best
        
        // Capture the image
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
    
    /// Fallback capture using window-based filter when display capture fails
    private func captureUsingWindowFilter() async throws -> CGImage {
        logger.debug("Attempting window-based capture fallback")
        
        let content: SCShareableContent
        do {
            content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        } catch {
            throw CaptureError.systemError(error)
        }
        
        guard let display = content.displays.first(where: { $0.displayID == CGMainDisplayID() }) else {
            throw CaptureError.screenNotFound
        }
        
        let menuBarWindows = content.windows.filter { window in
            let bundleID = window.owningApplication?.bundleIdentifier
            return bundleID == "com.apple.systemuiserver" || bundleID == "com.apple.controlcenter"
        }
        
        let filter = SCContentFilter(display: display, including: menuBarWindows)
        
        let config = SCStreamConfiguration()
        config.width = display.width
        config.height = Int(menuBarHeight * (NSScreen.main?.backingScaleFactor ?? 2.0))
        config.showsCursor = false
        config.captureResolution = .best
        
        do {
            let image = try await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: config
            )
            logger.debug("Window-based capture successful")
            return image
        } catch {
            logger.error("Window-based capture failed: \(error.localizedDescription)")
            throw CaptureError.systemError(error)
        }
    }
    
    // MARK: - Icon Slicing
    
    /// Slices a captured menu bar image into individual icon images.
    ///
    /// This uses heuristics to detect icon boundaries:
    /// - Standard icon width is ~22pt
    /// - Icons are separated by ~4pt gaps
    /// - We scan for vertical "gaps" (columns with low variance) to find boundaries
    ///
    /// - Parameters:
    ///   - image: The full menu bar capture
    ///   - separatorX: Optional X position of the separator (to know where hidden section starts)
    /// - Returns: Array of captured icons
    private func sliceIcons(from image: CGImage, separatorX: CGFloat?) -> [CapturedIcon] {
        var icons: [CapturedIcon] = []
        
        let imageWidth = CGFloat(image.width)
        let imageHeight = CGFloat(image.height)
        let scale = NSScreen.main?.backingScaleFactor ?? 2.0
        
        // For now, use a simple fixed-width slicing approach
        // TODO: Implement smarter edge detection for variable-width icons
        let iconWidthPixels = standardIconWidth * scale
        let spacingPixels = iconSpacing * scale
        let stepSize = iconWidthPixels + spacingPixels
        
        // Start from the left edge (or separator position if known)
        let startX: CGFloat = (separatorX ?? 0) * scale
        
        var currentX = startX
        while currentX + iconWidthPixels <= imageWidth {
            // Create a cropping rect for this icon
            let cropRect = CGRect(
                x: currentX,
                y: 0,
                width: iconWidthPixels,
                height: imageHeight
            )
            
            // Crop the icon
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
            
            // Safety limit to prevent infinite loops
            if icons.count > 50 {
                logger.warning("Hit icon limit (50), stopping slice")
                break
            }
        }
        
        logger.debug("Sliced \(icons.count) icons from capture")
        return icons
    }
    
    // MARK: - Utility Methods
    
    /// Clears the last capture result
    func clearLastCapture() {
        lastCaptureResult = nil
        lastError = nil
    }
}
