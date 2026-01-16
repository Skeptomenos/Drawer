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
    
    // MARK: - GHK-011: fromLegacy valid data
    
    func testGHK011_FromLegacyValidData() throws {
        // Arrange - Create valid legacy format JSON data
        let legacyJSON: [String: Any] = [
            "keyCode": 0,
            "carbonFlags": 256,
            "characters": "H",
            "function": false,
            "control": true,
            "command": true,
            "shift": false,
            "option": false,
            "capsLock": false
        ]
        let legacyData = try JSONSerialization.data(withJSONObject: legacyJSON)
        
        // Act
        let config = GlobalHotkeyConfig.fromLegacy(data: legacyData)
        
        // Assert
        XCTAssertNotNil(config, "GHK-011: fromLegacy should return a config for valid data")
        XCTAssertEqual(config?.keyCode, 0, "GHK-011: keyCode should be preserved")
        XCTAssertEqual(config?.carbonFlags, 256, "GHK-011: carbonFlags should be preserved")
        XCTAssertEqual(config?.characters, "H", "GHK-011: characters should be preserved")
        XCTAssertEqual(config?.function, false, "GHK-011: function should be preserved")
        XCTAssertEqual(config?.control, true, "GHK-011: control should be preserved")
        XCTAssertEqual(config?.command, true, "GHK-011: command should be preserved")
        XCTAssertEqual(config?.shift, false, "GHK-011: shift should be preserved")
        XCTAssertEqual(config?.option, false, "GHK-011: option should be preserved")
        XCTAssertEqual(config?.capsLock, false, "GHK-011: capsLock should be preserved")
        
        // Test with nil characters
        let legacyJSONNilChars: [String: Any] = [
            "keyCode": 36,
            "carbonFlags": 0,
            "function": false,
            "control": false,
            "command": true,
            "shift": false,
            "option": false,
            "capsLock": false
        ]
        let legacyDataNilChars = try JSONSerialization.data(withJSONObject: legacyJSONNilChars)
        let configNilChars = GlobalHotkeyConfig.fromLegacy(data: legacyDataNilChars)
        
        XCTAssertNotNil(configNilChars, "GHK-011: fromLegacy should handle nil characters")
        XCTAssertNil(configNilChars?.characters, "GHK-011: characters should be nil when not in legacy data")
        XCTAssertEqual(configNilChars?.keyCode, 36, "GHK-011: keyCode should be 36 (return key)")
    }
    
    // MARK: - GHK-012: fromLegacy invalid data
    
    func testGHK012_FromLegacyInvalidData() {
        // Arrange - Various forms of invalid data
        
        // Test 1: Completely invalid JSON (not even valid JSON)
        let invalidJSONData = "not valid json at all".data(using: .utf8)!
        let config1 = GlobalHotkeyConfig.fromLegacy(data: invalidJSONData)
        XCTAssertNil(config1, "GHK-012: Invalid JSON should return nil")
        
        // Test 2: Valid JSON but missing required fields
        let missingFieldsJSON: [String: Any] = [
            "keyCode": 0
            // Missing all other required fields
        ]
        let missingFieldsData = try! JSONSerialization.data(withJSONObject: missingFieldsJSON)
        let config2 = GlobalHotkeyConfig.fromLegacy(data: missingFieldsData)
        XCTAssertNil(config2, "GHK-012: JSON missing required fields should return nil")
        
        // Test 3: Valid JSON but wrong types
        let wrongTypesJSON: [String: Any] = [
            "keyCode": "not a number",  // Should be UInt32
            "carbonFlags": 0,
            "characters": "A",
            "function": false,
            "control": false,
            "command": true,
            "shift": false,
            "option": false,
            "capsLock": false
        ]
        let wrongTypesData = try! JSONSerialization.data(withJSONObject: wrongTypesJSON)
        let config3 = GlobalHotkeyConfig.fromLegacy(data: wrongTypesData)
        XCTAssertNil(config3, "GHK-012: JSON with wrong types should return nil")
        
        // Test 4: Empty data
        let emptyData = Data()
        let config4 = GlobalHotkeyConfig.fromLegacy(data: emptyData)
        XCTAssertNil(config4, "GHK-012: Empty data should return nil")
        
        // Test 5: Empty JSON object
        let emptyObjectData = "{}".data(using: .utf8)!
        let config5 = GlobalHotkeyConfig.fromLegacy(data: emptyObjectData)
        XCTAssertNil(config5, "GHK-012: Empty JSON object should return nil")
        
        // Test 6: JSON array instead of object
        let arrayData = "[]".data(using: .utf8)!
        let config6 = GlobalHotkeyConfig.fromLegacy(data: arrayData)
        XCTAssertNil(config6, "GHK-012: JSON array should return nil")
    }
    
    // MARK: - GHK-013: Equatable
    
    func testGHK013_Equatable() {
        // Arrange - Create two identical configs
        let config1 = createConfig(
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
        
        let config2 = createConfig(
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
        
        // Act & Assert - Two identical configs should be equal
        XCTAssertEqual(config1, config2, "GHK-013: Two identical configs should be equal")
        
        // Test with different keyCode - should NOT be equal
        let differentKeyCode = createConfig(
            keyCode: 99,
            carbonFlags: 256,
            characters: "H",
            function: true,
            control: true,
            command: true,
            shift: true,
            option: true,
            capsLock: true
        )
        XCTAssertNotEqual(config1, differentKeyCode, "GHK-013: Configs with different keyCode should not be equal")
        
        // Test with different carbonFlags - should NOT be equal
        let differentCarbonFlags = createConfig(
            keyCode: 42,
            carbonFlags: 512,
            characters: "H",
            function: true,
            control: true,
            command: true,
            shift: true,
            option: true,
            capsLock: true
        )
        XCTAssertNotEqual(config1, differentCarbonFlags, "GHK-013: Configs with different carbonFlags should not be equal")
        
        // Test with different characters - should NOT be equal
        let differentCharacters = createConfig(
            keyCode: 42,
            carbonFlags: 256,
            characters: "X",
            function: true,
            control: true,
            command: true,
            shift: true,
            option: true,
            capsLock: true
        )
        XCTAssertNotEqual(config1, differentCharacters, "GHK-013: Configs with different characters should not be equal")
        
        // Test with different modifier (command) - should NOT be equal
        let differentModifier = createConfig(
            keyCode: 42,
            carbonFlags: 256,
            characters: "H",
            function: true,
            control: true,
            command: false,
            shift: true,
            option: true,
            capsLock: true
        )
        XCTAssertNotEqual(config1, differentModifier, "GHK-013: Configs with different modifiers should not be equal")
        
        // Test with nil vs non-nil characters - should NOT be equal
        let nilCharacters = createConfig(
            keyCode: 42,
            carbonFlags: 256,
            characters: nil,
            function: true,
            control: true,
            command: true,
            shift: true,
            option: true,
            capsLock: true
        )
        XCTAssertNotEqual(config1, nilCharacters, "GHK-013: Config with nil characters should not equal config with non-nil characters")
        
        // Test two configs with nil characters - should be equal
        let nilCharacters2 = createConfig(
            keyCode: 42,
            carbonFlags: 256,
            characters: nil,
            function: true,
            control: true,
            command: true,
            shift: true,
            option: true,
            capsLock: true
        )
        XCTAssertEqual(nilCharacters, nilCharacters2, "GHK-013: Two configs with nil characters should be equal")
    }
}
