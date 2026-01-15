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
    
    // MARK: - GHK-005: Description with multiple modifiers
    
    func testGHK005_DescriptionWithMultipleModifiers() {
        // Arrange - Create config with all modifiers enabled
        let config = createConfig(
            keyCode: 0,
            characters: "a",
            function: true,
            control: true,
            command: true,
            shift: true,
            option: true,
            capsLock: true
        )
        
        // Act
        let description = config.description
        
        // Assert - Correct order: Fn⌃⌥⌘⇧⇪
        XCTAssertEqual(description, "Fn⌃⌥⌘⇧⇪A", "GHK-005: Description should show modifiers in correct order: Fn⌃⌥⌘⇧⇪")
        
        // Also verify partial combinations maintain order
        let partialConfig = createConfig(
            keyCode: 0,
            characters: "b",
            control: true,
            command: true,
            shift: true
        )
        let partialDescription = partialConfig.description
        XCTAssertEqual(partialDescription, "⌃⌘⇧B", "GHK-005: Partial modifiers should maintain order: ⌃⌘⇧")
    }
    
    // MARK: - GHK-006: Description with return key
    
    func testGHK006_DescriptionWithReturnKey() {
        // Arrange - keyCode 36 is the Return key
        let config = createConfig(
            keyCode: 36,
            characters: nil,
            command: true
        )
        
        // Act
        let description = config.description
        
        // Assert
        XCTAssertTrue(description.contains("⏎"), "GHK-006: Description should show ⏎ for return key (keyCode 36)")
        XCTAssertEqual(description, "⌘⏎", "GHK-006: Description should be ⌘⏎ for command+return")
        
        // Also test return key without modifiers
        let returnOnlyConfig = createConfig(
            keyCode: 36,
            characters: nil
        )
        XCTAssertEqual(returnOnlyConfig.description, "⏎", "GHK-006: Return key alone should show ⏎")
    }
    
    // MARK: - GHK-007: Description with delete key
    
    func testGHK007_DescriptionWithDeleteKey() {
        // Arrange - keyCode 51 is the Delete key
        let config = createConfig(
            keyCode: 51,
            characters: nil,
            command: true
        )
        
        // Act
        let description = config.description
        
        // Assert
        XCTAssertTrue(description.contains("⌫"), "GHK-007: Description should show ⌫ for delete key (keyCode 51)")
        XCTAssertEqual(description, "⌘⌫", "GHK-007: Description should be ⌘⌫ for command+delete")
        
        // Also test delete key without modifiers
        let deleteOnlyConfig = createConfig(
            keyCode: 51,
            characters: nil
        )
        XCTAssertEqual(deleteOnlyConfig.description, "⌫", "GHK-007: Delete key alone should show ⌫")
    }
    
    // MARK: - GHK-008: Description with space key
    
    func testGHK008_DescriptionWithSpaceKey() {
        // Arrange - keyCode 49 is the Space key
        let config = createConfig(
            keyCode: 49,
            characters: nil,
            command: true
        )
        
        // Act
        let description = config.description
        
        // Assert
        XCTAssertTrue(description.contains("⎵"), "GHK-008: Description should show ⎵ for space key (keyCode 49)")
        XCTAssertEqual(description, "⌘⎵", "GHK-008: Description should be ⌘⎵ for command+space")
        
        // Also test space key without modifiers
        let spaceOnlyConfig = createConfig(
            keyCode: 49,
            characters: nil
        )
        XCTAssertEqual(spaceOnlyConfig.description, "⎵", "GHK-008: Space key alone should show ⎵")
    }
}
