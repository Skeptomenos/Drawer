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
}
