//
//  MockIconCapturer.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import Combine
import Foundation

@testable import Drawer

/// SETUP-007: Mock implementation of IconCapturer for testing.
/// Simulates icon capture behavior without requiring actual ScreenCaptureKit access.
@MainActor
final class MockIconCapturer: ObservableObject {
    
    // MARK: - Published State (mirrors IconCapturer)
    
    @Published private(set) var isCapturing: Bool = false
    @Published private(set) var lastCaptureResult: MenuBarCaptureResult?
    @Published private(set) var lastError: CaptureError?
    
    // MARK: - Test Tracking
    
    var captureHiddenIconsCalled = false
    var captureHiddenIconsCallCount = 0
    
    var captureMenuBarRegionCalled = false
    var captureMenuBarRegionCallCount = 0
    
    var clearLastCaptureCalled = false
    var clearLastCaptureCallCount = 0
    
    // MARK: - Configurable Behavior
    
    /// Set to throw this error on next capture attempt
    var shouldThrowError: CaptureError?
    
    /// Set to return this result on next capture attempt
    var mockResult: MenuBarCaptureResult?
    
    /// Set to return this image on captureMenuBarRegion
    var mockMenuBarImage: CGImage?
    
    /// Simulate capture already in progress
    var simulateCaptureInProgress: Bool = false
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Methods (mirrors IconCapturer)
    
    func captureHiddenIcons(menuBarManager: MockMenuBarManager) async throws -> MenuBarCaptureResult {
        captureHiddenIconsCalled = true
        captureHiddenIconsCallCount += 1
        
        guard !isCapturing && !simulateCaptureInProgress else {
            throw CaptureError.systemError(NSError(
                domain: "MockIconCapturer",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Capture already in progress"]
            ))
        }
        
        isCapturing = true
        lastError = nil
        
        defer {
            isCapturing = false
        }
        
        if let error = shouldThrowError {
            lastError = error
            throw error
        }
        
        guard let result = mockResult else {
            let error = CaptureError.captureFailedNoImage
            lastError = error
            throw error
        }
        
        lastCaptureResult = result
        return result
    }
    
    func captureMenuBarRegion() async throws -> CGImage {
        captureMenuBarRegionCalled = true
        captureMenuBarRegionCallCount += 1
        
        if let error = shouldThrowError {
            throw error
        }
        
        guard let image = mockMenuBarImage else {
            throw CaptureError.captureFailedNoImage
        }
        
        return image
    }
    
    func clearLastCapture() {
        clearLastCaptureCalled = true
        clearLastCaptureCallCount += 1
        
        lastCaptureResult = nil
        lastError = nil
    }
    
    // MARK: - Test Helpers
    
    /// Resets all tracking flags and counters
    func resetTracking() {
        captureHiddenIconsCalled = false
        captureHiddenIconsCallCount = 0
        captureMenuBarRegionCalled = false
        captureMenuBarRegionCallCount = 0
        clearLastCaptureCalled = false
        clearLastCaptureCallCount = 0
    }
    
    /// Resets state to initial values
    func resetState() {
        isCapturing = false
        lastCaptureResult = nil
        lastError = nil
        shouldThrowError = nil
        mockResult = nil
        mockMenuBarImage = nil
        simulateCaptureInProgress = false
    }
    
    /// Resets both tracking and state
    func reset() {
        resetTracking()
        resetState()
    }
    
    /// Force set isCapturing for testing edge cases
    func setCapturing(_ value: Bool) {
        isCapturing = value
    }
    
    /// Force set lastError for testing error states
    func setLastError(_ error: CaptureError?) {
        lastError = error
    }
    
    /// Force set lastCaptureResult for testing
    func setLastCaptureResult(_ result: MenuBarCaptureResult?) {
        lastCaptureResult = result
    }
    
    // MARK: - Factory Methods for Test Data
    
    /// Creates a minimal valid MenuBarCaptureResult for testing
    static func createMockCaptureResult(
        iconCount: Int = 3,
        capturedRegion: CGRect = CGRect(x: 0, y: 0, width: 300, height: 24)
    ) -> MenuBarCaptureResult? {
        guard let fullImage = createMockImage(width: Int(capturedRegion.width), height: Int(capturedRegion.height)) else {
            return nil
        }
        
        var icons: [CapturedIcon] = []
        let iconWidth: CGFloat = 22
        let spacing: CGFloat = 4
        
        for i in 0..<iconCount {
            let x = CGFloat(i) * (iconWidth + spacing)
            let frame = CGRect(x: x, y: 0, width: iconWidth, height: capturedRegion.height)
            
            if let iconImage = createMockImage(width: Int(iconWidth), height: Int(capturedRegion.height)) {
                let icon = CapturedIcon(image: iconImage, originalFrame: frame)
                icons.append(icon)
            }
        }
        
        return MenuBarCaptureResult(
            fullImage: fullImage,
            icons: icons,
            capturedRegion: capturedRegion,
            capturedAt: Date(),
            menuBarItems: []
        )
    }
    
    /// Creates a mock CGImage for testing
    static func createMockImage(width: Int = 22, height: Int = 24) -> CGImage? {
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
        
        context.setFillColor(CGColor(gray: 0.5, alpha: 1.0))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        
        return context.makeImage()
    }
}
