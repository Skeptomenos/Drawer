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
    
    // MARK: - GHK-009: Description with character
    
    func testGHK009_DescriptionWithCharacter() {
        // Arrange - lowercase character should be uppercased in description
        let lowercaseConfig = createConfig(
            keyCode: 0,
            characters: "a",
            command: true
        )
        
        // Act
        let lowercaseDescription = lowercaseConfig.description
        
        // Assert - lowercase 'a' should become uppercase 'A'
        XCTAssertEqual(lowercaseDescription, "⌘A", "GHK-009: Lowercase character 'a' should be uppercased to 'A'")
        XCTAssertFalse(lowercaseDescription.contains("a"), "GHK-009: Description should not contain lowercase 'a'")
        
        // Test with already uppercase character
        let uppercaseConfig = createConfig(
            keyCode: 0,
            characters: "B",
            command: true
        )
        XCTAssertEqual(uppercaseConfig.description, "⌘B", "GHK-009: Uppercase character 'B' should remain 'B'")
        
        // Test with multiple characters (edge case)
        let multiCharConfig = createConfig(
            keyCode: 0,
            characters: "abc",
            option: true
        )
        XCTAssertEqual(multiCharConfig.description, "⌥ABC", "GHK-009: Multiple characters should all be uppercased")
        
        // Test character without modifiers
        let noModifierConfig = createConfig(
            keyCode: 0,
            characters: "x"
        )
        XCTAssertEqual(noModifierConfig.description, "X", "GHK-009: Character alone should be uppercased")
    }
    
    // MARK: - GHK-010: Encoding/decoding roundtrip
    
    func testGHK010_EncodingDecodingRoundtrip() throws {
        // Arrange - Create a config with all properties set
        let originalConfig = createConfig(
            keyCode: 42,
            carbonFlags: 256,
            characters: "H",
            function: true,
            control: true,
            command: true,
            shift: true,
            option: true,
            capsLock: true
        )
        
        // Act - Encode to JSON and decode back
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let encodedData = try encoder.encode(originalConfig)
        let decodedConfig = try decoder.decode(GlobalHotkeyConfig.self, from: encodedData)
        
        // Assert - All properties should be preserved
        XCTAssertEqual(decodedConfig.keyCode, originalConfig.keyCode, "GHK-010: keyCode should be preserved")
        XCTAssertEqual(decodedConfig.carbonFlags, originalConfig.carbonFlags, "GHK-010: carbonFlags should be preserved")
        XCTAssertEqual(decodedConfig.characters, originalConfig.characters, "GHK-010: characters should be preserved")
        XCTAssertEqual(decodedConfig.function, originalConfig.function, "GHK-010: function should be preserved")
        XCTAssertEqual(decodedConfig.control, originalConfig.control, "GHK-010: control should be preserved")
        XCTAssertEqual(decodedConfig.command, originalConfig.command, "GHK-010: command should be preserved")
        XCTAssertEqual(decodedConfig.shift, originalConfig.shift, "GHK-010: shift should be preserved")
        XCTAssertEqual(decodedConfig.option, originalConfig.option, "GHK-010: option should be preserved")
        XCTAssertEqual(decodedConfig.capsLock, originalConfig.capsLock, "GHK-010: capsLock should be preserved")
        
        // Also verify using Equatable
        XCTAssertEqual(decodedConfig, originalConfig, "GHK-010: Decoded config should equal original")
        
        // Test with nil characters
        let nilCharConfig = createConfig(
            keyCode: 36,
            carbonFlags: 0,
            characters: nil,
            command: true
        )
        let nilCharData = try encoder.encode(nilCharConfig)
        let nilCharDecoded = try decoder.decode(GlobalHotkeyConfig.self, from: nilCharData)
        XCTAssertNil(nilCharDecoded.characters, "GHK-010: nil characters should be preserved")
        XCTAssertEqual(nilCharDecoded, nilCharConfig, "GHK-010: Config with nil characters should roundtrip correctly")
        
        // Test with minimal config (all booleans false)
        let minimalConfig = createConfig(
            keyCode: 0,
            carbonFlags: 0,
            characters: "A",
            function: false,
            control: false,
            command: false,
            shift: false,
            option: false,
            capsLock: false
        )
        let minimalData = try encoder.encode(minimalConfig)
        let minimalDecoded = try decoder.decode(GlobalHotkeyConfig.self, from: minimalData)
        XCTAssertEqual(minimalDecoded, minimalConfig, "GHK-010: Minimal config should roundtrip correctly")
    }
}
