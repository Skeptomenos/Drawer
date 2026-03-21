//
//  MockScreenCaptureProvider.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import CoreGraphics
import ScreenCaptureKit

@testable import Drawer

/// TEST-003: Mock implementation of ScreenCaptureProviding for testing.
/// Allows tests to control screen capture behavior without requiring actual system permissions.
@MainActor
final class MockScreenCaptureProvider: ScreenCaptureProviding {

    // MARK: - Configurable Return Values

    /// The result to return from getShareableContent. If nil, throws mockError (or .screenNotFound if mockError is nil).
    var mockShareableContentResult: ShareableContentResult?

    /// The image to return from captureImage. If nil, throws mockError (or .captureFailedNoImage if mockError is nil).
    var mockCapturedImage: CGImage?

    /// Error to throw from methods. If set, methods will throw this error.
    var mockError: CaptureError?

    /// If true, getShareableContent will throw mockError (or .screenNotFound)
    var shouldThrowOnGetShareableContent = false

    /// If true, captureImage will throw mockError (or .captureFailedNoImage)
    var shouldThrowOnCaptureImage = false

    // MARK: - Call Tracking

    /// Whether getShareableContent was called
    var getShareableContentCalled = false

    /// Number of times getShareableContent was called
    var getShareableContentCallCount = 0

    /// Last parameters passed to getShareableContent
    var lastGetShareableContentExcludeDesktopWindows: Bool?
    var lastGetShareableContentOnScreenWindowsOnly: Bool?

    /// Whether captureImage was called
    var captureImageCalled = false

    /// Number of times captureImage was called
    var captureImageCallCount = 0

    /// Last configuration passed to captureImage
    var lastCaptureImageConfiguration: SCStreamConfiguration?

    // MARK: - Initialization

    init() {}

    /// Convenience initializer for common test scenarios
    init(mockImage: CGImage?, mockDisplays: [SCDisplay] = []) {
        self.mockCapturedImage = mockImage
        if !mockDisplays.isEmpty {
            self.mockShareableContentResult = ShareableContentResult(displays: mockDisplays, windows: [])
        }
    }

    // MARK: - ScreenCaptureProviding Implementation

    func getShareableContent(
        excludeDesktopWindows: Bool,
        onScreenWindowsOnly: Bool
    ) async throws -> ShareableContentResult {
        getShareableContentCalled = true
        getShareableContentCallCount += 1
        lastGetShareableContentExcludeDesktopWindows = excludeDesktopWindows
        lastGetShareableContentOnScreenWindowsOnly = onScreenWindowsOnly

        if shouldThrowOnGetShareableContent {
            throw mockError ?? CaptureError.screenNotFound
        }

        guard let result = mockShareableContentResult else {
            throw mockError ?? CaptureError.screenNotFound
        }

        return result
    }

    func captureImage(
        contentFilter: SCContentFilter,
        configuration: SCStreamConfiguration
    ) async throws -> CGImage {
        captureImageCalled = true
        captureImageCallCount += 1
        lastCaptureImageConfiguration = configuration

        if shouldThrowOnCaptureImage {
            throw mockError ?? CaptureError.captureFailedNoImage
        }

        guard let image = mockCapturedImage else {
            throw mockError ?? CaptureError.captureFailedNoImage
        }

        return image
    }

    // MARK: - Test Helpers

    /// Resets all tracking flags and counters
    func resetTracking() {
        getShareableContentCalled = false
        getShareableContentCallCount = 0
        lastGetShareableContentExcludeDesktopWindows = nil
        lastGetShareableContentOnScreenWindowsOnly = nil
        captureImageCalled = false
        captureImageCallCount = 0
        lastCaptureImageConfiguration = nil
    }

    /// Configures the mock to return a successful capture with the given image
    func configureSuccessfulCapture(image: CGImage, displays: [SCDisplay] = []) {
        mockCapturedImage = image
        mockShareableContentResult = ShareableContentResult(displays: displays, windows: [])
        shouldThrowOnGetShareableContent = false
        shouldThrowOnCaptureImage = false
        mockError = nil
    }

    /// Configures the mock to fail with the given error
    func configureFailure(error: CaptureError) {
        mockError = error
        shouldThrowOnGetShareableContent = true
        shouldThrowOnCaptureImage = true
    }

    /// Creates a simple test image for use in tests
    static func createTestImage(width: Int = 100, height: Int = 24, color: CGColor? = nil) -> CGImage? {
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                  data: nil,
                  width: width,
                  height: height,
                  bitsPerComponent: 8,
                  bytesPerRow: 0,
                  space: colorSpace,
                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            return nil
        }

        let fillColor = color ?? CGColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        context.setFillColor(fillColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        return context.makeImage()
    }
}
