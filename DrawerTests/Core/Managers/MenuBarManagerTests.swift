//
//  MenuBarManagerTests.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import XCTest
@testable import Drawer

@MainActor
final class MenuBarManagerTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: MenuBarManager!
    private var mockSettings: MockSettingsManager!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        mockSettings = MockSettingsManager()
    }
    
    override func tearDown() async throws {
        sut = nil
        mockSettings = nil
        try await super.tearDown()
    }
    
    // MARK: - MBM-001: Initial State Tests
    
    func testMBM001_InitialStateIsCollapsedIsTrue() async throws {
        sut = MenuBarManager(settings: SettingsManager.shared)
        
        XCTAssertTrue(sut.isCollapsed, "MBM-001: Initial state isCollapsed should be true")
    }
    
    // MARK: - MBM-002: Initial State isToggling
    
    func testMBM002_InitialStateIsTogglingIsFalse() async throws {
        // Arrange & Act
        sut = MenuBarManager(settings: SettingsManager.shared)
        
        // Assert
        XCTAssertFalse(sut.isToggling, "MBM-002: Initial state isToggling should be false")
    }
    
    // MARK: - MBM-003: Toggle from collapsed expands
    
    func testMBM003_ToggleFromCollapsedExpands() async throws {
        // Arrange
        sut = MenuBarManager(settings: SettingsManager.shared)
        XCTAssertTrue(sut.isCollapsed, "Precondition: should start collapsed")
        
        // Act
        sut.toggle()
        
        // Assert
        XCTAssertFalse(sut.isCollapsed, "MBM-003: toggle() when collapsed should set isCollapsed=false")
    }
    
    // MARK: - MBM-004: Toggle from expanded collapses
    
    func testMBM004_ToggleFromExpandedCollapses() async throws {
        // Arrange
        sut = MenuBarManager(settings: SettingsManager.shared)
        
        // First expand the menu bar
        sut.toggle()
        XCTAssertFalse(sut.isCollapsed, "Precondition: should be expanded after first toggle")
        
        // Wait for debounce to complete (isToggling resets after 0.3s)
        try await Task.sleep(for: .milliseconds(350))
        XCTAssertFalse(sut.isToggling, "Precondition: isToggling should be false after debounce")
        
        // Act
        sut.toggle()
        
        // Assert
        XCTAssertTrue(sut.isCollapsed, "MBM-004: toggle() when expanded should set isCollapsed=true")
    }
    
    // MARK: - MBM-005: Expand when already expanded is no-op
    
    func testMBM005_ExpandWhenAlreadyExpandedIsNoOp() async throws {
        // Arrange
        sut = MenuBarManager(settings: SettingsManager.shared)
        
        // First expand the menu bar
        sut.toggle()
        XCTAssertFalse(sut.isCollapsed, "Precondition: should be expanded after first toggle")
        
        // Wait for debounce to complete
        try await Task.sleep(for: .milliseconds(350))
        XCTAssertFalse(sut.isToggling, "Precondition: isToggling should be false after debounce")
        
        // Act - call expand() when already expanded
        sut.expand()
        
        // Assert - state should remain unchanged (still expanded)
        XCTAssertFalse(sut.isCollapsed, "MBM-005: expand() when !isCollapsed should do nothing (remain expanded)")
    }
    
    // MARK: - MBM-006: Collapse when already collapsed is no-op
    
    func testMBM006_CollapseWhenAlreadyCollapsedIsNoOp() async throws {
        // Arrange
        sut = MenuBarManager(settings: SettingsManager.shared)
        XCTAssertTrue(sut.isCollapsed, "Precondition: should start collapsed")
        
        // Act - call collapse() when already collapsed
        sut.collapse()
        
        // Assert - state should remain unchanged (still collapsed)
        XCTAssertTrue(sut.isCollapsed, "MBM-006: collapse() when isCollapsed should do nothing (remain collapsed)")
    }
    
    // MARK: - MBM-007: isToggling prevents double toggle
    
    func testMBM007_IsTogglingPreventsDoubleToggle() async throws {
        // Arrange
        sut = MenuBarManager(settings: SettingsManager.shared)
        XCTAssertTrue(sut.isCollapsed, "Precondition: should start collapsed")
        XCTAssertFalse(sut.isToggling, "Precondition: isToggling should be false")
        
        // Act - call toggle() twice rapidly (before debounce completes)
        sut.toggle()
        
        // Verify first toggle took effect
        XCTAssertFalse(sut.isCollapsed, "First toggle should expand (isCollapsed=false)")
        XCTAssertTrue(sut.isToggling, "isToggling should be true during debounce period")
        
        // Immediately call toggle() again while isToggling is true
        sut.toggle()
        
        // Assert - second toggle should be ignored (state unchanged)
        XCTAssertFalse(sut.isCollapsed, "MBM-007: Rapid toggle() calls should be debounced - state should remain expanded")
        XCTAssertTrue(sut.isToggling, "isToggling should still be true")
        
        // Wait for debounce to complete
        try await Task.sleep(for: .milliseconds(350))
        
        // Verify debounce completed
        XCTAssertFalse(sut.isToggling, "isToggling should be false after debounce period")
        
        // Now toggle should work again
        sut.toggle()
        XCTAssertTrue(sut.isCollapsed, "Toggle after debounce should collapse (isCollapsed=true)")
    }
}
