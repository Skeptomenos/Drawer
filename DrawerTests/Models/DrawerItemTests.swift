//
//  DrawerItemTests.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import XCTest
@testable import Drawer

final class DrawerItemTests: XCTestCase {
    
    // MARK: - Test Helpers
    
    /// Creates a mock CGImage for testing
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
        
        context.setFillColor(CGColor(gray: 0.5, alpha: 1.0))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        
        return context.makeImage()
    }
    
    /// Creates a CapturedIcon for testing
    private func createCapturedIcon(
        frame: CGRect = CGRect(x: 100, y: 0, width: 22, height: 24)
    ) -> CapturedIcon? {
        guard let image = createMockImage() else { return nil }
        return CapturedIcon(image: image, originalFrame: frame)
    }
    
    // MARK: - DRI-001: Init from CapturedIcon
    
    func testDRI001_InitFromCapturedIcon() throws {
        // Arrange
        guard let capturedIcon = createCapturedIcon(
            frame: CGRect(x: 100, y: 0, width: 22, height: 24)
        ) else {
            throw XCTSkip("DRI-001: Could not create mock CapturedIcon")
        }
        let testIndex = 5
        
        // Act
        let drawerItem = DrawerItem(from: capturedIcon, index: testIndex)
        
        // Assert
        XCTAssertEqual(drawerItem.id, capturedIcon.id, "DRI-001: id should be copied from CapturedIcon")
        XCTAssertEqual(drawerItem.originalFrame, capturedIcon.originalFrame, "DRI-001: originalFrame should be copied from CapturedIcon")
        XCTAssertEqual(drawerItem.capturedAt, capturedIcon.capturedAt, "DRI-001: capturedAt should be copied from CapturedIcon")
        XCTAssertEqual(drawerItem.index, testIndex, "DRI-001: index should be set to provided value")
        XCTAssertNotNil(drawerItem.image, "DRI-001: image should be copied from CapturedIcon")
    }
    
    // MARK: - DRI-002: Init direct with image, frame, index
    
    func testDRI002_InitDirectWithImageFrameIndex() throws {
        // Arrange
        guard let mockImage = createMockImage(width: 22, height: 24) else {
            throw XCTSkip("DRI-002: Could not create mock CGImage")
        }
        let testFrame = CGRect(x: 150, y: 5, width: 22, height: 24)
        let testIndex = 3
        
        // Act
        let drawerItem = DrawerItem(image: mockImage, originalFrame: testFrame, index: testIndex)
        
        // Assert
        XCTAssertNotNil(drawerItem.id, "DRI-002: id should be auto-generated UUID")
        XCTAssertEqual(drawerItem.originalFrame, testFrame, "DRI-002: originalFrame should match provided frame")
        XCTAssertEqual(drawerItem.index, testIndex, "DRI-002: index should match provided value")
        XCTAssertNotNil(drawerItem.capturedAt, "DRI-002: capturedAt should be auto-set to current date")
        XCTAssertNotNil(drawerItem.image, "DRI-002: image should be set from provided CGImage")
        
        let timeDifference = Date().timeIntervalSince(drawerItem.capturedAt)
        XCTAssertLessThan(timeDifference, 1.0, "DRI-002: capturedAt should be set to approximately current time")
    }
    
    // MARK: - DRI-003: clickTarget returns frame center
    
    func testDRI003_ClickTargetReturnsFrameCenter() throws {
        // Arrange
        guard let mockImage = createMockImage(width: 22, height: 24) else {
            throw XCTSkip("DRI-003: Could not create mock CGImage")
        }
        let testFrame = CGRect(x: 100, y: 10, width: 22, height: 24)
        let drawerItem = DrawerItem(image: mockImage, originalFrame: testFrame, index: 0)
        
        let expectedCenterX = testFrame.midX
        let expectedCenterY = testFrame.midY
        
        // Act
        let clickTarget = drawerItem.clickTarget
        
        // Assert
        XCTAssertEqual(clickTarget.x, expectedCenterX, "DRI-003: clickTarget.x should be frame center X")
        XCTAssertEqual(clickTarget.y, expectedCenterY, "DRI-003: clickTarget.y should be frame center Y")
        XCTAssertEqual(clickTarget, CGPoint(x: 111, y: 22), "DRI-003: clickTarget should be CGPoint at frame center")
    }
    
    // MARK: - DRI-004: originalCenterX calculation
    
    func testDRI004_OriginalCenterXCalculation() throws {
        // Arrange
        guard let mockImage = createMockImage(width: 22, height: 24) else {
            throw XCTSkip("DRI-004: Could not create mock CGImage")
        }
        let testFrame = CGRect(x: 100, y: 10, width: 40, height: 24)
        let drawerItem = DrawerItem(image: mockImage, originalFrame: testFrame, index: 0)
        
        let expectedCenterX = testFrame.midX  // 100 + 40/2 = 120
        
        // Act
        let originalCenterX = drawerItem.originalCenterX
        
        // Assert
        XCTAssertEqual(originalCenterX, expectedCenterX, "DRI-004: originalCenterX should return frame.midX")
        XCTAssertEqual(originalCenterX, 120, "DRI-004: originalCenterX should be 120 for frame at x=100 with width=40")
    }
}
