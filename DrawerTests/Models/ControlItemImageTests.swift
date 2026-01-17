//
//  ControlItemImageTests.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import XCTest
@testable import Drawer

final class ControlItemImageTests: XCTestCase {

    // MARK: - CII-001: SF Symbol Rendering

    func testCII001_SFSymbolRendering() {
        // Arrange
        let image = ControlItemImage.sfSymbol("chevron.left")

        // Act
        let rendered = image.render()

        // Assert
        XCTAssertNotNil(rendered, "CII-001: SF Symbol should render successfully")
        XCTAssertTrue(rendered?.isTemplate ?? false, "CII-001: Rendered image should be a template")
    }

    // MARK: - CII-002: SF Symbol with Weight

    func testCII002_SFSymbolWithWeight() {
        // Arrange
        let lightImage = ControlItemImage.sfSymbol("chevron.left", weight: .light)
        let boldImage = ControlItemImage.sfSymbol("chevron.left", weight: .bold)

        // Act
        let lightRendered = lightImage.render()
        let boldRendered = boldImage.render()

        // Assert
        XCTAssertNotNil(lightRendered, "CII-002: Light weight SF Symbol should render")
        XCTAssertNotNil(boldRendered, "CII-002: Bold weight SF Symbol should render")
    }

    // MARK: - CII-003: Invalid SF Symbol Returns Nil

    func testCII003_InvalidSFSymbolReturnsNil() {
        // Arrange
        let image = ControlItemImage.sfSymbol("this.symbol.does.not.exist.xyz123")

        // Act
        let rendered = image.render()

        // Assert
        XCTAssertNil(rendered, "CII-003: Invalid SF Symbol name should return nil")
    }

    // MARK: - CII-004: Bezier Path Rendering

    func testCII004_BezierPathRendering() {
        // Arrange
        let image = ControlItemImage.bezierPath {
            let path = NSBezierPath(ovalIn: NSRect(x: 4, y: 4, width: 10, height: 10))
            return path
        }

        // Act
        let rendered = image.render()

        // Assert
        XCTAssertNotNil(rendered, "CII-004: Bezier path should render successfully")
        XCTAssertTrue(rendered?.isTemplate ?? false, "CII-004: Rendered bezier path should be a template")
    }

    // MARK: - CII-005: Bezier Path Custom Size

    func testCII005_BezierPathCustomSize() {
        // Arrange
        let customSize = NSSize(width: 32, height: 32)
        let image = ControlItemImage.bezierPath {
            NSBezierPath(rect: NSRect(origin: .zero, size: customSize))
        }

        // Act
        let rendered = image.render(size: customSize)

        // Assert
        XCTAssertNotNil(rendered, "CII-005: Bezier path should render at custom size")
        XCTAssertEqual(rendered?.size.width, customSize.width, "CII-005: Width should match custom size")
        XCTAssertEqual(rendered?.size.height, customSize.height, "CII-005: Height should match custom size")
    }

    // MARK: - CII-006: Asset Rendering (Invalid Name)

    func testCII006_AssetRenderingInvalidName() {
        // Arrange - using a name that doesn't exist in asset catalog
        let image = ControlItemImage.asset("NonExistentAssetXYZ123")

        // Act
        let rendered = image.render()

        // Assert
        XCTAssertNil(rendered, "CII-006: Invalid asset name should return nil")
    }

    // MARK: - CII-007: None Case Returns Nil

    func testCII007_NoneCaseReturnsNil() {
        // Arrange
        let image = ControlItemImage.none

        // Act
        let rendered = image.render()

        // Assert
        XCTAssertNil(rendered, "CII-007: None case should return nil")
    }

    // MARK: - CII-008: Default Size

    func testCII008_DefaultSize() {
        // Arrange
        let image = ControlItemImage.sfSymbol("circle.fill")

        // Act
        let rendered = image.render()

        // Assert - SF Symbols may have different actual sizes, but should render
        XCTAssertNotNil(rendered, "CII-008: Should render with default size")
    }

    // MARK: - CII-009: Static Chevron Left

    func testCII009_StaticChevronLeft() {
        // Arrange & Act
        let rendered = ControlItemImage.chevronLeft.render()

        // Assert
        XCTAssertNotNil(rendered, "CII-009: Static chevronLeft should render")
        XCTAssertTrue(rendered?.isTemplate ?? false, "CII-009: chevronLeft should be a template image")
    }

    // MARK: - CII-010: Static Chevron Right

    func testCII010_StaticChevronRight() {
        // Arrange & Act
        let rendered = ControlItemImage.chevronRight.render()

        // Assert
        XCTAssertNotNil(rendered, "CII-010: Static chevronRight should render")
        XCTAssertTrue(rendered?.isTemplate ?? false, "CII-010: chevronRight should be a template image")
    }

    // MARK: - CII-011: Static Separator Dot

    func testCII011_StaticSeparatorDot() {
        // Arrange & Act
        let rendered = ControlItemImage.separatorDot.render()

        // Assert
        XCTAssertNotNil(rendered, "CII-011: Static separatorDot should render")
        XCTAssertTrue(rendered?.isTemplate ?? false, "CII-011: separatorDot should be a template image")
    }
}
