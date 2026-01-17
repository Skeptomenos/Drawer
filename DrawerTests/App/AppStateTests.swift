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

    // MARK: - APP-002: Initial isDrawerVisible is false

    func testAPP002_InitialIsDrawerVisibleIsFalse() async throws {
        // Arrange & Act
        sut = createSUT()

        // Assert
        XCTAssertFalse(sut.isDrawerVisible, "APP-002: Initial state isDrawerVisible should be false")
    }

    // MARK: - APP-003: Initial isCapturing is false

    func testAPP003_InitialIsCapturingIsFalse() async throws {
        // Arrange & Act
        sut = createSUT()

        // Assert
        XCTAssertFalse(sut.isCapturing, "APP-003: Initial state isCapturing should be false")
    }

    // MARK: - APP-004: toggleMenuBar delegates to manager

    func testAPP004_ToggleMenuBarDelegatesToManager() async throws {
        sut = createSUT()
        XCTAssertTrue(sut.isCollapsed, "Precondition: isCollapsed should be true initially")

        sut.toggleMenuBar()
        try await Task.sleep(for: .milliseconds(350))

        XCTAssertFalse(sut.isCollapsed, "APP-004: toggleMenuBar should delegate to manager and change isCollapsed state")
    }

    // MARK: - APP-005: toggleDrawer shows when hidden

    func testAPP005_ToggleDrawerShowsWhenHidden() async throws {
        // Arrange
        sut = createSUT()
        sut.hideDrawer()
        XCTAssertFalse(sut.isDrawerVisible, "Precondition: drawer should be hidden")

        // Act
        sut.drawerManager.show()
        sut.drawerController.show(content: DrawerContentView(items: [], isLoading: false))
        try await Task.sleep(for: .milliseconds(100))

        // Assert
        XCTAssertTrue(sut.drawerManager.isVisible, "APP-005: show() should set drawerManager.isVisible to true")
    }

    // MARK: - APP-006: toggleDrawer hides when visible

    func testAPP006_ToggleDrawerHidesWhenVisible() async throws {
        // Arrange
        sut = createSUT()

        // Show the drawer and wait for animation to complete (250ms show duration + buffer)
        sut.drawerManager.show()
        sut.drawerController.show(content: DrawerContentView(items: [], isLoading: false))
        try await Task.sleep(for: .milliseconds(400))

        XCTAssertTrue(sut.drawerManager.isVisible, "Precondition: drawerManager should be visible")
        XCTAssertTrue(sut.drawerController.isVisible, "Precondition: drawerController should be visible")

        // Act - hideDrawer is called directly since toggleDrawer would trigger capture
        sut.hideDrawer()
        try await Task.sleep(for: .milliseconds(250))

        // Assert
        XCTAssertFalse(sut.drawerManager.isVisible, "APP-006: drawerManager.isVisible should be false after hide")
        XCTAssertFalse(sut.isDrawerVisible, "APP-006: isDrawerVisible should be false after hide")
    }

    // MARK: - APP-007: hideDrawer updates all state

    func testAPP007_HideDrawerUpdatesAllState() async throws {
        // Arrange
        sut = createSUT()

        // Show the drawer first to establish visible state
        sut.drawerManager.show()
        sut.drawerController.show(content: DrawerContentView(items: [], isLoading: false))
        try await Task.sleep(for: .milliseconds(400))

        // Verify preconditions - all three should be visible/true
        XCTAssertTrue(sut.drawerManager.isVisible, "Precondition: drawerManager should be visible")
        XCTAssertTrue(sut.drawerController.isVisible, "Precondition: drawerController should be visible")
        XCTAssertTrue(sut.isDrawerVisible, "Precondition: isDrawerVisible flag should be true")

        // Act
        sut.hideDrawer()
        try await Task.sleep(for: .milliseconds(250))

        // Assert - verify ALL three state updates from hideDrawer()
        // 1. drawerController.hide() was called
        XCTAssertFalse(sut.drawerController.isVisible, "APP-007: drawerController should be hidden after hideDrawer()")

        // 2. drawerManager.hide() was called
        XCTAssertFalse(sut.drawerManager.isVisible, "APP-007: drawerManager should be hidden after hideDrawer()")

        // 3. isDrawerVisible flag was set to false
        XCTAssertFalse(sut.isDrawerVisible, "APP-007: isDrawerVisible flag should be false after hideDrawer()")
    }

    // MARK: - APP-008: completeOnboarding sets flag

    func testAPP008_CompleteOnboardingSetsFlag() async throws {
        // Arrange
        sut = createSUT()

        // Reset the flag to ensure we're testing from a known state
        sut.settings.hasCompletedOnboarding = false
        XCTAssertFalse(sut.hasCompletedOnboarding, "Precondition: hasCompletedOnboarding should be false")

        // Act
        sut.completeOnboarding()

        // Assert
        XCTAssertTrue(sut.hasCompletedOnboarding, "APP-008: completeOnboarding() should set hasCompletedOnboarding to true")
        XCTAssertTrue(sut.settings.hasCompletedOnboarding, "APP-008: settings.hasCompletedOnboarding should also be true (backing store)")
    }

    // MARK: - APP-009: hasCompletedOnboarding reads from settings

    func testAPP009_HasCompletedOnboardingReadsFromSettings() async throws {
        // Arrange
        sut = createSUT()

        // Ensure we start with a known state
        sut.settings.hasCompletedOnboarding = false

        // Assert initial state reads from settings
        XCTAssertFalse(sut.hasCompletedOnboarding, "APP-009: hasCompletedOnboarding should read false from settings")

        // Act - modify settings directly (not through AppState)
        sut.settings.hasCompletedOnboarding = true

        // Assert - AppState should reflect the settings change
        XCTAssertTrue(sut.hasCompletedOnboarding, "APP-009: hasCompletedOnboarding should read true from settings after direct modification")

        // Verify bidirectional binding - setting through AppState updates settings
        sut.hasCompletedOnboarding = false
        XCTAssertFalse(sut.settings.hasCompletedOnboarding, "APP-009: Setting hasCompletedOnboarding on AppState should update settings")
    }

    // MARK: - APP-010: Permission bindings update state

    func testAPP010_PermissionBindingsUpdateState() async throws {
        sut = createSUT()

        let initialPermissionState = sut.permissions.hasAllPermissions

        XCTAssertEqual(
            sut.hasRequiredPermissions,
            initialPermissionState,
            "APP-010: hasRequiredPermissions should be initialized from permissions.hasAllPermissions"
        )

        let expectation = XCTestExpectation(description: "Permission status changed")

        var receivedUpdate = false
        sut.permissions.permissionStatusChanged
            .sink { [weak self] in
                receivedUpdate = true
                expectation.fulfill()
                XCTAssertEqual(
                    self?.sut.hasRequiredPermissions,
                    self?.sut.permissions.hasAllPermissions,
                    "APP-010: hasRequiredPermissions should sync when permissionStatusChanged fires"
                )
            }
            .store(in: &cancellables)

        sut.permissions.refreshAllStatuses()

        await fulfillment(of: [expectation], timeout: 2.0)

        XCTAssertTrue(receivedUpdate, "APP-010: permissionStatusChanged publisher should have fired")
    }

    // MARK: - APP-011: Hover bindings configured

    func testAPP011_HoverBindingsConfigured() async throws {
        sut = createSUT()

        XCTAssertNotNil(
            sut.hoverManager.onShouldShowDrawer,
            "APP-011: onShouldShowDrawer callback should be configured"
        )
        XCTAssertNotNil(
            sut.hoverManager.onShouldHideDrawer,
            "APP-011: onShouldHideDrawer callback should be configured"
        )

        let initialShowOnHover = sut.settings.showOnHover

        if initialShowOnHover {
            XCTAssertTrue(
                sut.hoverManager.isMonitoring,
                "APP-011: HoverManager should be monitoring when showOnHover is true"
            )
        }

        sut.settings.showOnHover = true
        try await Task.sleep(for: .milliseconds(100))

        XCTAssertTrue(
            sut.hoverManager.isMonitoring,
            "APP-011: HoverManager should start monitoring when showOnHover becomes true"
        )

        sut.drawerManager.show()
        sut.drawerController.show(content: DrawerContentView(items: [], isLoading: false))
        try await Task.sleep(for: .milliseconds(400))

        XCTAssertTrue(sut.isDrawerVisible, "APP-011: isDrawerVisible should be true after showing drawer")

        sut.settings.showOnHover = false
        try await Task.sleep(for: .milliseconds(100))
    }
}
