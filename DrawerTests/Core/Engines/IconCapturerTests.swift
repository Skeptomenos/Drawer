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
}
