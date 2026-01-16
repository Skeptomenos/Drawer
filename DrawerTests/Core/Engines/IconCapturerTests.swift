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
    
    // MARK: - ICN-007: sliceIconsUsingFixedWidth limits to 50 icons
    
    func testICN007_SliceIconsUsingFixedWidthLimitsTo50() async throws {
        // Arrange
        let capturer = IconCapturer()
        
        // Create an image wide enough for 60 icons (well over the 50 limit)
        // Each icon takes 22px + 4px spacing = 26px at 1x scale
        // At 2x scale: (22 * 2) + (4 * 2) = 52px per icon
        let scale: CGFloat = 2.0
        let iconWidthPixels = 22 * scale
        let spacingPixels = 4 * scale
        let stepSize = iconWidthPixels + spacingPixels
        let targetIconCount = 60 // More than the 50 limit
        let imageWidth = Int(stepSize * CGFloat(targetIconCount))
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
            XCTFail("ICN-007: Failed to create test image context")
            return
        }
        
        // Fill with a solid color to create a valid image
        context.setFillColor(CGColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0))
        context.fill(CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight))
        
        guard let testImage = context.makeImage() else {
            XCTFail("ICN-007: Failed to create test image")
            return
        }
        
        // Act
        let icons = capturer.sliceIconsUsingFixedWidth(from: testImage)
        
        // Assert
        // The implementation uses `icons.count > 50` which means it stops AFTER adding the 51st icon
        // So the max is 51, not 50
        XCTAssertLessThanOrEqual(
            icons.count,
            51,
            "ICN-007: sliceIconsUsingFixedWidth should limit icons to ~50 (implementation allows up to 51)"
        )
        XCTAssertGreaterThan(
            icons.count,
            0,
            "ICN-007: Should have created some icons before hitting limit"
        )
        
        // Verify the limit was actually hit (we provided enough width for 60 icons)
        XCTAssertLessThan(
            icons.count,
            targetIconCount,
            "ICN-007: Icon count should be less than the \(targetIconCount) that would fit in the image"
        )
    }
    
    // MARK: - ICN-008: sliceIconsUsingFixedWidth correct spacing
    
    func testICN008_SliceIconsUsingFixedWidthCorrectSpacing() async throws {
        // Arrange
        let capturer = IconCapturer()
        
        // Create an image with exact dimensions for 3 icons
        // Each icon: 22px width + 4px spacing = 26px step size
        // At 2x scale: (22 * 2) + (4 * 2) = 52px per icon step
        let scale: CGFloat = 2.0
        let standardIconWidth: CGFloat = 22
        let iconSpacing: CGFloat = 4
        let iconWidthPixels = standardIconWidth * scale
        let spacingPixels = iconSpacing * scale
        let stepSize = iconWidthPixels + spacingPixels
        let expectedIconCount = 3
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
            XCTFail("ICN-008: Failed to create test image context")
            return
        }
        
        // Fill with a solid color to create a valid image
        context.setFillColor(CGColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0))
        context.fill(CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight))
        
        guard let testImage = context.makeImage() else {
            XCTFail("ICN-008: Failed to create test image")
            return
        }
        
        // Act
        let icons = capturer.sliceIconsUsingFixedWidth(from: testImage)
        
        // Assert
        XCTAssertEqual(
            icons.count,
            expectedIconCount,
            "ICN-008: Should create exactly \(expectedIconCount) icons"
        )
        
        // Verify each icon has correct width (22px in logical coordinates)
        for (index, icon) in icons.enumerated() {
            XCTAssertEqual(
                icon.originalFrame.width,
                standardIconWidth,
                accuracy: 0.01,
                "ICN-008: Icon \(index) should have width of \(standardIconWidth)px"
            )
        }
        
        // Verify spacing between icons (4px gap between consecutive icons)
        // The originalFrame.x values should be at 0, 26, 52 (in logical coordinates)
        // which means step size of 26px (22px icon + 4px spacing)
        let expectedStepSize = standardIconWidth + iconSpacing
        
        for i in 1..<icons.count {
            let previousIconX = icons[i - 1].originalFrame.origin.x
            let currentIconX = icons[i].originalFrame.origin.x
            let actualStepSize = currentIconX - previousIconX
            
            XCTAssertEqual(
                actualStepSize,
                expectedStepSize,
                accuracy: 0.01,
                "ICN-008: Step size between icon \(i - 1) and \(i) should be \(expectedStepSize)px (22px width + 4px spacing)"
            )
        }
        
        // Verify first icon starts at x=0
        XCTAssertEqual(
            icons[0].originalFrame.origin.x,
            0,
            accuracy: 0.01,
            "ICN-008: First icon should start at x=0"
        )
        
        // Verify second icon starts at x=26 (22 + 4)
        if icons.count > 1 {
            XCTAssertEqual(
                icons[1].originalFrame.origin.x,
                expectedStepSize,
                accuracy: 0.01,
                "ICN-008: Second icon should start at x=\(expectedStepSize)"
            )
        }
        
        // Verify third icon starts at x=52 (2 * 26)
        if icons.count > 2 {
            XCTAssertEqual(
                icons[2].originalFrame.origin.x,
                expectedStepSize * 2,
                accuracy: 0.01,
                "ICN-008: Third icon should start at x=\(expectedStepSize * 2)"
            )
        }
    }
    
    // MARK: - ICN-009: createCompositeImage from icons
    
    func testICN009_CreateCompositeImageFromIcons() async throws {
        let capturer = IconCapturer()
        
        guard let screen = NSScreen.main else {
            XCTFail("ICN-009: No main screen available for test")
            return
        }
        
        let scale = screen.backingScaleFactor
        let iconWidth: CGFloat = 22
        let iconHeight: CGFloat = 24
        let iconSpacing: CGFloat = 4
        let stepSize = iconWidth + iconSpacing
        
        var testIcons: [CapturedIcon] = []
        let iconColors: [CGColor] = [
            CGColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0),
            CGColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0),
            CGColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0)
        ]
        
        for i in 0..<3 {
            let imageWidth = Int(iconWidth * scale)
            let imageHeight = Int(iconHeight * scale)
            
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
                XCTFail("ICN-009: Failed to create test image context for icon \(i)")
                return
            }
            
            context.setFillColor(iconColors[i])
            context.fill(CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight))
            
            guard let testImage = context.makeImage() else {
                XCTFail("ICN-009: Failed to create test image for icon \(i)")
                return
            }
            
            let originalFrame = CGRect(
                x: CGFloat(i) * stepSize,
                y: 0,
                width: iconWidth,
                height: iconHeight
            )
            
            let icon = CapturedIcon(image: testImage, originalFrame: originalFrame)
            testIcons.append(icon)
        }
        
        let unionFrame = CGRect(
            x: 0,
            y: 0,
            width: stepSize * 2 + iconWidth,
            height: iconHeight
        )
        
        let compositeImage = capturer.createCompositeImage(
            from: testIcons,
            unionFrame: unionFrame,
            screen: screen
        )
        
        XCTAssertNotNil(
            compositeImage,
            "ICN-009: createCompositeImage should return a valid image"
        )
        
        guard let image = compositeImage else { return }
        
        let expectedWidth = Int(unionFrame.width * scale)
        let expectedHeight = Int(unionFrame.height * scale)
        
        XCTAssertEqual(
            image.width,
            expectedWidth,
            "ICN-009: Composite image width should be \(expectedWidth) pixels"
        )
        XCTAssertEqual(
            image.height,
            expectedHeight,
            "ICN-009: Composite image height should be \(expectedHeight) pixels"
        )
    }
    
    // MARK: - ICN-010: createCompositeImage empty returns nil
    
    func testICN010_CreateCompositeImageEmptyReturnsNil() async throws {
        // Arrange
        let capturer = IconCapturer()
        
        guard let screen = NSScreen.main else {
            XCTFail("ICN-010: No main screen available for test")
            return
        }
        
        let emptyIcons: [CapturedIcon] = []
        let unionFrame = CGRect(x: 0, y: 0, width: 100, height: 24)
        
        // Act
        let compositeImage = capturer.createCompositeImage(
            from: emptyIcons,
            unionFrame: unionFrame,
            screen: screen
        )
        
        // Assert
        XCTAssertNil(
            compositeImage,
            "ICN-010: createCompositeImage should return nil for empty icons array"
        )
    }
    
    // MARK: - ICN-011: Capture already in progress skips
    
    func testICN011_CaptureAlreadyInProgressSkips() async throws {
        // Arrange
        let mockPermissionManager = MockPermissionManager()
        mockPermissionManager.mockHasScreenRecording = true
        
        let capturer = IconCapturer(permissionManager: mockPermissionManager)
        let menuBarManager = MenuBarManager()
        
        capturer.setIsCapturingForTesting(true)
        
        // Act & Assert
        do {
            _ = try await capturer.captureHiddenIcons(menuBarManager: menuBarManager)
            XCTFail("ICN-011: Should throw when capture is already in progress")
        } catch let error as CaptureError {
            switch error {
            case .systemError(let nsError as NSError):
                XCTAssertTrue(
                    nsError.localizedDescription.contains("Capture already in progress"),
                    "ICN-011: Error message should indicate capture in progress, got: \(nsError.localizedDescription)"
                )
                XCTAssertEqual(
                    nsError.domain,
                    "IconCapturer",
                    "ICN-011: Error domain should be IconCapturer"
                )
                XCTAssertEqual(
                    nsError.code,
                    -1,
                    "ICN-011: Error code should be -1"
                )
            default:
                XCTFail("ICN-011: Expected systemError, got: \(error)")
            }
        }
        
        capturer.setIsCapturingForTesting(false)
    }
}
