//
//  MockIconCapturerTests.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import XCTest

@testable import Drawer

@MainActor
final class MockIconCapturerTests: XCTestCase {

    func testSETUP007_MockIconCapturerCanBeInstantiated() {
        let mock = MockIconCapturer()

        XCTAssertNotNil(mock)
        XCTAssertFalse(mock.isCapturing)
        XCTAssertNil(mock.lastCaptureResult)
        XCTAssertNil(mock.lastError)
    }

    func testMockIconCapturerCaptureWithMockResult() async throws {
        let mock = MockIconCapturer()
        let menuBarManager = MockMenuBarManager()

        guard let mockResult = MockIconCapturer.createMockCaptureResult(iconCount: 3) else {
            XCTFail("Failed to create mock capture result")
            return
        }
        mock.mockResult = mockResult

        let result = try await mock.captureHiddenIcons(menuBarManager: menuBarManager)

        XCTAssertTrue(mock.captureHiddenIconsCalled)
        XCTAssertEqual(mock.captureHiddenIconsCallCount, 1)
        XCTAssertEqual(result.icons.count, 3)
        XCTAssertNotNil(mock.lastCaptureResult)
    }

    func testMockIconCapturerCaptureThrowsConfiguredError() async {
        let mock = MockIconCapturer()
        let menuBarManager = MockMenuBarManager()
        mock.shouldThrowError = .permissionDenied

        do {
            _ = try await mock.captureHiddenIcons(menuBarManager: menuBarManager)
            XCTFail("Expected error to be thrown")
        } catch let error as CaptureError {
            XCTAssertEqual(error.errorDescription, CaptureError.permissionDenied.errorDescription)
            XCTAssertNotNil(mock.lastError)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testMockIconCapturerCaptureInProgressBlocks() async {
        let mock = MockIconCapturer()
        let menuBarManager = MockMenuBarManager()
        mock.simulateCaptureInProgress = true

        do {
            _ = try await mock.captureHiddenIcons(menuBarManager: menuBarManager)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(mock.captureHiddenIconsCalled)
        }
    }

    func testMockIconCapturerClearLastCapture() {
        let mock = MockIconCapturer()
        mock.setLastError(.menuBarNotFound)
        mock.setLastCaptureResult(MockIconCapturer.createMockCaptureResult())

        XCTAssertNotNil(mock.lastError)
        XCTAssertNotNil(mock.lastCaptureResult)

        mock.clearLastCapture()

        XCTAssertTrue(mock.clearLastCaptureCalled)
        XCTAssertNil(mock.lastError)
        XCTAssertNil(mock.lastCaptureResult)
    }

    func testMockIconCapturerResetTracking() async throws {
        let mock = MockIconCapturer()
        let menuBarManager = MockMenuBarManager()
        mock.mockResult = MockIconCapturer.createMockCaptureResult()

        _ = try await mock.captureHiddenIcons(menuBarManager: menuBarManager)
        mock.clearLastCapture()

        XCTAssertTrue(mock.captureHiddenIconsCalled)
        XCTAssertTrue(mock.clearLastCaptureCalled)

        mock.resetTracking()

        XCTAssertFalse(mock.captureHiddenIconsCalled)
        XCTAssertFalse(mock.clearLastCaptureCalled)
        XCTAssertEqual(mock.captureHiddenIconsCallCount, 0)
        XCTAssertEqual(mock.clearLastCaptureCallCount, 0)
    }

    func testMockIconCapturerReset() {
        let mock = MockIconCapturer()
        mock.setCapturing(true)
        mock.setLastError(.screenNotFound)
        mock.shouldThrowError = .permissionDenied
        mock.captureHiddenIconsCalled = true

        mock.reset()

        XCTAssertFalse(mock.isCapturing)
        XCTAssertNil(mock.lastError)
        XCTAssertNil(mock.shouldThrowError)
        XCTAssertFalse(mock.captureHiddenIconsCalled)
    }

    func testMockIconCapturerCreateMockImage() {
        let image = MockIconCapturer.createMockImage(width: 22, height: 24)

        XCTAssertNotNil(image)
        XCTAssertEqual(image?.width, 22)
        XCTAssertEqual(image?.height, 24)
    }

    func testMockIconCapturerCreateMockImageInvalidDimensions() {
        let image = MockIconCapturer.createMockImage(width: 0, height: 0)

        XCTAssertNil(image)
    }

    func testMockIconCapturerCreateMockCaptureResult() {
        let result = MockIconCapturer.createMockCaptureResult(iconCount: 5)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.icons.count, 5)
        XCTAssertNotNil(result?.fullImage)
    }
}
