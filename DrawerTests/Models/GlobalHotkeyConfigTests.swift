//
//  GlobalHotkeyConfigTests.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import XCTest
@testable import Drawer

final class GlobalHotkeyConfigTests: XCTestCase {
    
    // MARK: - Test Helpers
    
    private func createConfig(
        keyCode: UInt32 = 0,
        carbonFlags: UInt32 = 0,
        characters: String? = "A",
        function: Bool = false,
        control: Bool = false,
        command: Bool = false,
        shift: Bool = false,
        option: Bool = false,
        capsLock: Bool = false
    ) -> GlobalHotkeyConfig {
        return GlobalHotkeyConfig(
            keyCode: keyCode,
            carbonFlags: carbonFlags,
            characters: characters,
            function: function,
            control: control,
            command: command,
            shift: shift,
            option: option,
            capsLock: capsLock
        )
    }
    
    // MARK: - GHK-001: Description with command modifier
    
    func testGHK001_DescriptionWithCommandModifier() {
        // Arrange
        let config = createConfig(
            keyCode: 0,
            characters: "a",
            command: true
        )
        
        // Act
        let description = config.description
        
        // Assert
        XCTAssertTrue(description.contains("⌘"), "GHK-001: Description should show ⌘ for command modifier")
        XCTAssertEqual(description, "⌘A", "GHK-001: Description should be ⌘A for command+A")
    }
    
    // MARK: - GHK-002: Description with shift modifier
    
    func testGHK002_DescriptionWithShiftModifier() {
        // Arrange
        let config = createConfig(
            keyCode: 0,
            characters: "a",
            shift: true
        )
        
        // Act
        let description = config.description
        
        // Assert
        XCTAssertTrue(description.contains("⇧"), "GHK-002: Description should show ⇧ for shift modifier")
        XCTAssertEqual(description, "⇧A", "GHK-002: Description should be ⇧A for shift+A")
    }
    
    // MARK: - GHK-003: Description with option modifier
    
    func testGHK003_DescriptionWithOptionModifier() {
        // Arrange
        let config = createConfig(
            keyCode: 0,
            characters: "a",
            option: true
        )
        
        // Act
        let description = config.description
        
        // Assert
        XCTAssertTrue(description.contains("⌥"), "GHK-003: Description should show ⌥ for option modifier")
        XCTAssertEqual(description, "⌥A", "GHK-003: Description should be ⌥A for option+A")
    }
    
    // MARK: - GHK-004: Description with control modifier
    
    func testGHK004_DescriptionWithControlModifier() {
        // Arrange
        let config = createConfig(
            keyCode: 0,
            characters: "a",
            control: true
        )
        
        // Act
        let description = config.description
        
        // Assert
        XCTAssertTrue(description.contains("⌃"), "GHK-004: Description should show ⌃ for control modifier")
        XCTAssertEqual(description, "⌃A", "GHK-004: Description should be ⌃A for control+A")
    }
}
