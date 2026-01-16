//
//  AppStateTests.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import Combine
import XCTest

@testable import Drawer

@MainActor
final class AppStateTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: AppState!
    private var mockSettings: MockSettingsManager!
    private var mockPermissions: MockPermissionManager!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        mockSettings = MockSettingsManager()
        mockPermissions = MockPermissionManager()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() async throws {
        sut = nil
        mockSettings = nil
        mockPermissions = nil
        cancellables = nil
        try await super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func createSUT() -> AppState {
        return AppState(
            settings: SettingsManager.shared,
            permissions: PermissionManager.shared,
            drawerManager: DrawerManager.shared,
            iconCapturer: IconCapturer.shared,
            eventSimulator: EventSimulator.shared,
            hoverManager: HoverManager.shared
        )
    }
    
    // MARK: - APP-001: Initial isCollapsed is true
    
    func testAPP001_InitialIsCollapsedIsTrue() async throws {
        // Arrange & Act
        sut = createSUT()
        
        // Assert
        XCTAssertTrue(sut.isCollapsed, "APP-001: Initial state isCollapsed should be true")
    }
}
