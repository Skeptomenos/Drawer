//
//  IconCapturerTests.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import Combine
import XCTest

@testable import Drawer

@MainActor
final class IconCapturerTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: IconCapturer!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        sut = IconCapturer()
        cancellables = []
    }
    
    override func tearDown() async throws {
        sut.clearLastCapture()
        cancellables = nil
        sut = nil
        try await super.tearDown()
    }
    
    // MARK: - ICN-001: Initial isCapturing is false
    
    func testICN001_InitialIsCapturingIsFalse() async throws {
        // Arrange
        let capturer = IconCapturer()
        
        // Act
        let isCapturing = capturer.isCapturing
        
        // Assert
        XCTAssertFalse(
            isCapturing,
            "ICN-001: isCapturing should be false on init"
        )
    }
    
    // MARK: - ICN-002: Initial lastCaptureResult is nil
    
    func testICN002_InitialLastCaptureResultIsNil() async throws {
        // Arrange
        let capturer = IconCapturer()
        
        // Act
        let lastCaptureResult = capturer.lastCaptureResult
        
        // Assert
        XCTAssertNil(
            lastCaptureResult,
            "ICN-002: lastCaptureResult should be nil on init"
        )
    }
    
    // MARK: - ICN-003: Initial lastError is nil
    
    func testICN003_InitialLastErrorIsNil() async throws {
        // Arrange
        let capturer = IconCapturer()
        
        // Act
        let lastError = capturer.lastError
        
        // Assert
        XCTAssertNil(
            lastError,
            "ICN-003: lastError should be nil on init"
        )
    }
    
    // MARK: - ICN-004: Capture without permission throws permissionDenied
    
    func testICN004_CaptureWithoutPermissionThrowsPermissionDenied() async throws {
        // Arrange
        let mockPermissionManager = MockPermissionManager()
        mockPermissionManager.mockHasScreenRecording = false
        
        let capturer = IconCapturer(permissionManager: mockPermissionManager)
        let menuBarManager = MenuBarManager()
        
        // Act & Assert
        do {
            _ = try await capturer.captureHiddenIcons(menuBarManager: menuBarManager)
            XCTFail("ICN-004: Expected permissionDenied error to be thrown")
        } catch let error as CaptureError {
            switch error {
            case .permissionDenied:
                XCTAssertNotNil(
                    capturer.lastError,
                    "ICN-004: lastError should be set after permission denied"
                )
                if case .permissionDenied = capturer.lastError {
                } else {
                    XCTFail("ICN-004: lastError should be .permissionDenied")
                }
            default:
                XCTFail("ICN-004: Expected .permissionDenied but got \(error)")
            }
        } catch {
            XCTFail("ICN-004: Expected CaptureError.permissionDenied but got \(error)")
        }
    }
    
    // MARK: - ICN-005: clearLastCapture resets state
    
    func testICN005_ClearLastCaptureResetsState() async throws {
        // Arrange
        // First, trigger an error to set lastError
        let mockPermissionManager = MockPermissionManager()
        mockPermissionManager.mockHasScreenRecording = false
        
        let capturer = IconCapturer(permissionManager: mockPermissionManager)
        let menuBarManager = MenuBarManager()
        
        // Trigger capture to set lastError
        do {
            _ = try await capturer.captureHiddenIcons(menuBarManager: menuBarManager)
        } catch {
            // Expected to throw permissionDenied
        }
        
        // Verify lastError is set before clearing
        XCTAssertNotNil(
            capturer.lastError,
            "ICN-005: lastError should be set before clearing"
        )
        
        // Act
        capturer.clearLastCapture()
        
        // Assert
        XCTAssertNil(
            capturer.lastCaptureResult,
            "ICN-005: lastCaptureResult should be nil after clearLastCapture"
        )
        XCTAssertNil(
            capturer.lastError,
            "ICN-005: lastError should be nil after clearLastCapture"
        )
    }
    
    // MARK: - ICN-006: sliceIconsUsingFixedWidth creates icons
    
    func testICN006_SliceIconsUsingFixedWidthCreatesIcons() async throws {
        let capturer = IconCapturer()
        
        let scale: CGFloat = 2.0
        let iconWidthPixels = 22 * scale
        let spacingPixels = 4 * scale
        let stepSize = iconWidthPixels + spacingPixels
        let expectedIconCount = 5
        let imageWidth = Int(stepSize * CGFloat(expectedIconCount))
        let imageHeight = Int(24 * scale)
        
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                  data: nil,
                  width: imageWidth,
                  height: imageHeight,
                  bitsPerComponent: 8,
                  bytesPerRow: 0,
                  space: colorSpace,
                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            XCTFail("ICN-006: Failed to create test image context")
            return
        }
        
        context.setFillColor(CGColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0))
        context.fill(CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight))
        
        guard let testImage = context.makeImage() else {
            XCTFail("ICN-006: Failed to create test image")
            return
        }
        
        let icons = capturer.sliceIconsUsingFixedWidth(from: testImage)
        
        XCTAssertFalse(
            icons.isEmpty,
            "ICN-006: sliceIconsUsingFixedWidth should create icons from valid image"
        )
        XCTAssertEqual(
            icons.count,
            expectedIconCount,
            "ICN-006: Should create \(expectedIconCount) icons from \(imageWidth)px wide image"
        )
        
        for (index, icon) in icons.enumerated() {
            XCTAssertEqual(
                icon.originalFrame.width,
                22,
                "ICN-006: Icon \(index) should have width of 22 (standardIconWidth)"
            )
            XCTAssertNotNil(
                icon.id,
                "ICN-006: Icon \(index) should have a valid ID"
            )
        }
    }
}
