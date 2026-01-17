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

    // MARK: - DRI-005: originalCenterY calculation

    func testDRI005_OriginalCenterYCalculation() throws {
        // Arrange
        guard let mockImage = createMockImage(width: 22, height: 24) else {
            throw XCTSkip("DRI-005: Could not create mock CGImage")
        }
        let testFrame = CGRect(x: 100, y: 10, width: 22, height: 40)
        let drawerItem = DrawerItem(image: mockImage, originalFrame: testFrame, index: 0)

        let expectedCenterY = testFrame.midY  // 10 + 40/2 = 30

        // Act
        let originalCenterY = drawerItem.originalCenterY

        // Assert
        XCTAssertEqual(originalCenterY, expectedCenterY, "DRI-005: originalCenterY should return frame.midY")
        XCTAssertEqual(originalCenterY, 30, "DRI-005: originalCenterY should be 30 for frame at y=10 with height=40")
    }

    // MARK: - DRI-006: Equatable compares by ID

    func testDRI006_EquatableComparesByID() throws {
        // Arrange
        guard let capturedIcon = createCapturedIcon(
            frame: CGRect(x: 100, y: 0, width: 22, height: 24)
        ) else {
            throw XCTSkip("DRI-006: Could not create mock CapturedIcon")
        }

        // Create two DrawerItems from the same CapturedIcon (same ID)
        let item1 = DrawerItem(from: capturedIcon, index: 0)
        let item2 = DrawerItem(from: capturedIcon, index: 5)  // Different index, same ID

        // Act & Assert
        XCTAssertEqual(item1, item2, "DRI-006: Two items with same ID should be equal")
        XCTAssertEqual(item1.id, item2.id, "DRI-006: IDs should match")
        XCTAssertNotEqual(item1.index, item2.index, "DRI-006: Indexes are different but items are still equal")
    }

    // MARK: - DRI-007: Equatable different IDs not equal

    func testDRI007_EquatableDifferentIDsNotEqual() throws {
        // Arrange
        guard let mockImage = createMockImage(width: 22, height: 24) else {
            throw XCTSkip("DRI-007: Could not create mock CGImage")
        }
        let testFrame = CGRect(x: 100, y: 0, width: 22, height: 24)

        // Create two DrawerItems with direct init (each gets a unique UUID)
        let item1 = DrawerItem(image: mockImage, originalFrame: testFrame, index: 0)
        let item2 = DrawerItem(image: mockImage, originalFrame: testFrame, index: 0)

        // Act & Assert
        XCTAssertNotEqual(item1, item2, "DRI-007: Two items with different IDs should not be equal")
        XCTAssertNotEqual(item1.id, item2.id, "DRI-007: IDs should be different")
        XCTAssertEqual(item1.originalFrame, item2.originalFrame, "DRI-007: Frames are same but items are not equal")
        XCTAssertEqual(item1.index, item2.index, "DRI-007: Indexes are same but items are not equal")
    }

    // MARK: - DRI-008: toDrawerItems extension converts correctly

    func testDRI008_ToDrawerItemsExtensionConvertsCorrectly() throws {
        // Arrange
        guard let icon1 = createCapturedIcon(frame: CGRect(x: 100, y: 0, width: 22, height: 24)),
              let icon2 = createCapturedIcon(frame: CGRect(x: 126, y: 0, width: 22, height: 24)),
              let icon3 = createCapturedIcon(frame: CGRect(x: 152, y: 0, width: 22, height: 24)) else {
            throw XCTSkip("DRI-008: Could not create mock CapturedIcons")
        }
        let capturedIcons: [CapturedIcon] = [icon1, icon2, icon3]

        // Act
        let drawerItems = capturedIcons.toDrawerItems()

        // Assert
        XCTAssertEqual(drawerItems.count, 3, "DRI-008: Should convert all 3 icons to drawer items")

        for (index, item) in drawerItems.enumerated() {
            let originalIcon = capturedIcons[index]
            XCTAssertEqual(item.id, originalIcon.id, "DRI-008: Item \(index) id should match original icon id")
            XCTAssertEqual(item.originalFrame, originalIcon.originalFrame, "DRI-008: Item \(index) frame should match original")
            XCTAssertEqual(item.capturedAt, originalIcon.capturedAt, "DRI-008: Item \(index) capturedAt should match original")
            XCTAssertEqual(item.index, index, "DRI-008: Item \(index) index should be \(index)")
        }
    }

    // MARK: - DRI-009: toDrawerItems preserves order

    func testDRI009_ToDrawerItemsPreservesOrder() throws {
        // Arrange
        // Create icons with distinct frames to verify order preservation
        guard let icon1 = createCapturedIcon(frame: CGRect(x: 100, y: 0, width: 22, height: 24)),
              let icon2 = createCapturedIcon(frame: CGRect(x: 126, y: 0, width: 22, height: 24)),
              let icon3 = createCapturedIcon(frame: CGRect(x: 152, y: 0, width: 22, height: 24)),
              let icon4 = createCapturedIcon(frame: CGRect(x: 178, y: 0, width: 22, height: 24)),
              let icon5 = createCapturedIcon(frame: CGRect(x: 204, y: 0, width: 22, height: 24)) else {
            throw XCTSkip("DRI-009: Could not create mock CapturedIcons")
        }
        let capturedIcons: [CapturedIcon] = [icon1, icon2, icon3, icon4, icon5]

        // Act
        let drawerItems = capturedIcons.toDrawerItems()

        // Assert
        XCTAssertEqual(drawerItems.count, capturedIcons.count, "DRI-009: Should have same count as input")

        // Verify order is preserved by checking that each item's index matches its position
        // and that the original icon data is preserved in the correct order
        for (arrayIndex, item) in drawerItems.enumerated() {
            XCTAssertEqual(item.index, arrayIndex, "DRI-009: Item at position \(arrayIndex) should have index \(arrayIndex)")
            XCTAssertEqual(item.id, capturedIcons[arrayIndex].id, "DRI-009: Item at position \(arrayIndex) should have ID from original icon at same position")
            XCTAssertEqual(item.originalFrame, capturedIcons[arrayIndex].originalFrame, "DRI-009: Item at position \(arrayIndex) should have frame from original icon at same position")
        }

        // Additional verification: indices should be sequential starting from 0
        let indices = drawerItems.map { $0.index }
        XCTAssertEqual(indices, [0, 1, 2, 3, 4], "DRI-009: Indices should be sequential starting from 0")
    }

    // MARK: - DRI-010: toDrawerItems empty array

    func testDRI010_ToDrawerItemsEmptyArray() {
        // Arrange
        let emptyCapturedIcons: [CapturedIcon] = []

        // Act
        let drawerItems = emptyCapturedIcons.toDrawerItems()

        // Assert
        XCTAssertTrue(drawerItems.isEmpty, "DRI-010: Empty array should return empty result")
        XCTAssertEqual(drawerItems.count, 0, "DRI-010: Count should be 0 for empty input")
    }
}
