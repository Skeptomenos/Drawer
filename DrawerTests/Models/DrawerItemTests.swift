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
}
