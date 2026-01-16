//
//  WindowInfoTests.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import CoreGraphics
import XCTest

@testable import Drawer

final class WindowInfoTests: XCTestCase {
    
    private let statusWindowLevel = 25
    private let normalWindowLevel = 0
    private let floatingWindowLevel = 3
    private let desktopWindowLevel = -2147483623
    
    // MARK: - WIN-001: isMenuBarItem with status window level
    
    func testWIN001_IsMenuBarItemWithStatusWindowLevel() {
        let dictionary = createWindowDictionary(layer: statusWindowLevel)
        
        // Act
        let windowInfo = WindowInfo(dictionary: dictionary as CFDictionary)
        
        // Assert
        XCTAssertNotNil(windowInfo, "WIN-001: WindowInfo should initialize from valid dictionary")
        XCTAssertTrue(
            windowInfo!.isMenuBarItem,
            "WIN-001: isMenuBarItem should return true when layer equals kCGStatusWindowLevel"
        )
        XCTAssertEqual(
            windowInfo!.layer,
            statusWindowLevel,
            "WIN-001: layer should be kCGStatusWindowLevel"
        )
    }
    
    // MARK: - WIN-002: isMenuBarItem with other level
    
    func testWIN002_IsMenuBarItemWithOtherLevel() {
        let dictionary = createWindowDictionary(layer: normalWindowLevel)
        
        // Act
        let windowInfo = WindowInfo(dictionary: dictionary as CFDictionary)
        
        // Assert
        XCTAssertNotNil(windowInfo, "WIN-002: WindowInfo should initialize from valid dictionary")
        XCTAssertFalse(
            windowInfo!.isMenuBarItem,
            "WIN-002: isMenuBarItem should return false when layer is not kCGStatusWindowLevel"
        )
        XCTAssertEqual(
            windowInfo!.layer,
            normalWindowLevel,
            "WIN-002: layer should be kCGNormalWindowLevel"
        )
    }
    
    func testWIN002_IsMenuBarItemWithFloatingWindowLevel() {
        let dictionary = createWindowDictionary(layer: floatingWindowLevel)
        
        // Act
        let windowInfo = WindowInfo(dictionary: dictionary as CFDictionary)
        
        // Assert
        XCTAssertNotNil(windowInfo, "WIN-002: WindowInfo should initialize from valid dictionary")
        XCTAssertFalse(
            windowInfo!.isMenuBarItem,
            "WIN-002: isMenuBarItem should return false for floating window level"
        )
    }
    
    func testWIN002_IsMenuBarItemWithDesktopWindowLevel() {
        let dictionary = createWindowDictionary(layer: desktopWindowLevel)
        
        // Act
        let windowInfo = WindowInfo(dictionary: dictionary as CFDictionary)
        
        // Assert
        XCTAssertNotNil(windowInfo, "WIN-002: WindowInfo should initialize from valid dictionary")
        XCTAssertFalse(
            windowInfo!.isMenuBarItem,
            "WIN-002: isMenuBarItem should return false for desktop window level"
        )
    }
    
    // MARK: - WIN-003: init from dictionary valid data
    
    func testWIN003_InitFromDictionaryValidData() {
        let expectedWindowID: CGWindowID = 12345
        let expectedFrame = CGRect(x: 100, y: 200, width: 300, height: 400)
        let expectedTitle = "Test Window"
        let expectedLayer = normalWindowLevel
        let expectedAlpha = 0.8
        let expectedOwnerPID: pid_t = 1234
        let expectedOwnerName = "TestApp"
        let expectedIsOnScreen = true
        
        let dictionary = createWindowDictionary(
            windowID: expectedWindowID,
            frame: expectedFrame,
            title: expectedTitle,
            layer: expectedLayer,
            alpha: expectedAlpha,
            ownerPID: expectedOwnerPID,
            ownerName: expectedOwnerName,
            isOnScreen: expectedIsOnScreen
        )
        
        // Act
        let windowInfo = WindowInfo(dictionary: dictionary as CFDictionary)
        
        // Assert
        XCTAssertNotNil(windowInfo, "WIN-003: WindowInfo should initialize from valid dictionary")
        
        XCTAssertEqual(
            windowInfo!.windowID,
            expectedWindowID,
            "WIN-003: windowID should match input"
        )
        XCTAssertEqual(
            windowInfo!.frame,
            expectedFrame,
            "WIN-003: frame should match input"
        )
        XCTAssertEqual(
            windowInfo!.title,
            expectedTitle,
            "WIN-003: title should match input"
        )
        XCTAssertEqual(
            windowInfo!.layer,
            expectedLayer,
            "WIN-003: layer should match input"
        )
        XCTAssertEqual(
            windowInfo!.alpha,
            expectedAlpha,
            accuracy: 0.001,
            "WIN-003: alpha should match input"
        )
        XCTAssertEqual(
            windowInfo!.ownerPID,
            expectedOwnerPID,
            "WIN-003: ownerPID should match input"
        )
        XCTAssertEqual(
            windowInfo!.ownerName,
            expectedOwnerName,
            "WIN-003: ownerName should match input"
        )
        XCTAssertEqual(
            windowInfo!.isOnScreen,
            expectedIsOnScreen,
            "WIN-003: isOnScreen should match input"
        )
        XCTAssertEqual(
            windowInfo!.id,
            expectedWindowID,
            "WIN-003: id should equal windowID"
        )
    }
    
    func testWIN003_InitFromDictionaryWithOptionalFieldsNil() {
        let dictionary = createWindowDictionary(
            windowID: 99999,
            frame: CGRect(x: 0, y: 0, width: 100, height: 100),
            title: nil,
            layer: 0,
            alpha: 1.0,
            ownerPID: 1,
            ownerName: nil,
            isOnScreen: nil
        )
        
        // Act
        let windowInfo = WindowInfo(dictionary: dictionary as CFDictionary)
        
        // Assert
        XCTAssertNotNil(windowInfo, "WIN-003: WindowInfo should initialize even without optional fields")
        XCTAssertNil(windowInfo!.title, "WIN-003: title should be nil when not provided")
        XCTAssertNil(windowInfo!.ownerName, "WIN-003: ownerName should be nil when not provided")
        XCTAssertFalse(windowInfo!.isOnScreen, "WIN-003: isOnScreen should default to false when not provided")
    }
    
    // MARK: - WIN-004: init from dictionary invalid data
    
    func testWIN004_InitFromDictionaryMissingWindowID() {
        var dict: [CFString: Any] = [:]
        dict[kCGWindowBounds] = CGRect(x: 0, y: 0, width: 100, height: 100).dictionaryRepresentation
        dict[kCGWindowLayer] = 0
        dict[kCGWindowAlpha] = 1.0
        dict[kCGWindowOwnerPID] = pid_t(1)
        
        // Act
        let windowInfo = WindowInfo(dictionary: dict as CFDictionary)
        
        // Assert
        XCTAssertNil(
            windowInfo,
            "WIN-004: WindowInfo should return nil when windowID is missing"
        )
    }
    
    func testWIN004_InitFromDictionaryMissingBounds() {
        var dict: [CFString: Any] = [:]
        dict[kCGWindowNumber] = CGWindowID(12345)
        dict[kCGWindowLayer] = 0
        dict[kCGWindowAlpha] = 1.0
        dict[kCGWindowOwnerPID] = pid_t(1)
        
        // Act
        let windowInfo = WindowInfo(dictionary: dict as CFDictionary)
        
        // Assert
        XCTAssertNil(
            windowInfo,
            "WIN-004: WindowInfo should return nil when bounds is missing"
        )
    }
    
    func testWIN004_InitFromDictionaryMissingLayer() {
        var dict: [CFString: Any] = [:]
        dict[kCGWindowNumber] = CGWindowID(12345)
        dict[kCGWindowBounds] = CGRect(x: 0, y: 0, width: 100, height: 100).dictionaryRepresentation
        dict[kCGWindowAlpha] = 1.0
        dict[kCGWindowOwnerPID] = pid_t(1)
        
        // Act
        let windowInfo = WindowInfo(dictionary: dict as CFDictionary)
        
        // Assert
        XCTAssertNil(
            windowInfo,
            "WIN-004: WindowInfo should return nil when layer is missing"
        )
    }
    
    func testWIN004_InitFromDictionaryMissingAlpha() {
        var dict: [CFString: Any] = [:]
        dict[kCGWindowNumber] = CGWindowID(12345)
        dict[kCGWindowBounds] = CGRect(x: 0, y: 0, width: 100, height: 100).dictionaryRepresentation
        dict[kCGWindowLayer] = 0
        dict[kCGWindowOwnerPID] = pid_t(1)
        
        // Act
        let windowInfo = WindowInfo(dictionary: dict as CFDictionary)
        
        // Assert
        XCTAssertNil(
            windowInfo,
            "WIN-004: WindowInfo should return nil when alpha is missing"
        )
    }
    
    func testWIN004_InitFromDictionaryMissingOwnerPID() {
        var dict: [CFString: Any] = [:]
        dict[kCGWindowNumber] = CGWindowID(12345)
        dict[kCGWindowBounds] = CGRect(x: 0, y: 0, width: 100, height: 100).dictionaryRepresentation
        dict[kCGWindowLayer] = 0
        dict[kCGWindowAlpha] = 1.0
        
        // Act
        let windowInfo = WindowInfo(dictionary: dict as CFDictionary)
        
        // Assert
        XCTAssertNil(
            windowInfo,
            "WIN-004: WindowInfo should return nil when ownerPID is missing"
        )
    }
    
    func testWIN004_InitFromDictionaryEmptyDictionary() {
        let dict: [CFString: Any] = [:]
        
        // Act
        let windowInfo = WindowInfo(dictionary: dict as CFDictionary)
        
        // Assert
        XCTAssertNil(
            windowInfo,
            "WIN-004: WindowInfo should return nil for empty dictionary"
        )
    }
    
    func testWIN004_InitFromDictionaryWrongTypes() {
        var dict: [CFString: Any] = [:]
        dict[kCGWindowNumber] = "not a number"
        dict[kCGWindowBounds] = CGRect(x: 0, y: 0, width: 100, height: 100).dictionaryRepresentation
        dict[kCGWindowLayer] = 0
        dict[kCGWindowAlpha] = 1.0
        dict[kCGWindowOwnerPID] = pid_t(1)
        
        // Act
        let windowInfo = WindowInfo(dictionary: dict as CFDictionary)
        
        // Assert
        XCTAssertNil(
            windowInfo,
            "WIN-004: WindowInfo should return nil when types are incorrect"
        )
    }
    
    // MARK: - Helper Methods
    
    private func createWindowDictionary(
        windowID: CGWindowID = 12345,
        frame: CGRect = CGRect(x: 0, y: 0, width: 100, height: 100),
        title: String? = nil,
        layer: Int = 0,
        alpha: Double = 1.0,
        ownerPID: pid_t = 1,
        ownerName: String? = nil,
        isOnScreen: Bool? = nil
    ) -> [CFString: Any] {
        var dict: [CFString: Any] = [:]
        
        dict[kCGWindowNumber] = windowID
        dict[kCGWindowBounds] = frame.dictionaryRepresentation
        dict[kCGWindowLayer] = layer
        dict[kCGWindowAlpha] = alpha
        dict[kCGWindowOwnerPID] = ownerPID
        
        if let title = title {
            dict[kCGWindowName] = title
        }
        if let ownerName = ownerName {
            dict[kCGWindowOwnerName] = ownerName
        }
        if let isOnScreen = isOnScreen {
            dict[kCGWindowIsOnscreen] = isOnScreen
        }
        
        return dict
    }
}
