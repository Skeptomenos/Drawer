//
//  ControlItemImage.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit

/// Represents different ways to render a control item's icon.
/// Supports SF Symbols, programmatic drawing, and asset catalog images.
enum ControlItemImage {
    /// An SF Symbol with optional weight configuration
    case sfSymbol(String, weight: NSFont.Weight = .medium)

    /// A programmatically drawn icon using NSBezierPath
    case bezierPath(() -> NSBezierPath)

    /// An image from the asset catalog
    case asset(String)

    /// No image
    case none

    // MARK: - Rendering

    /// Renders the image at the specified size.
    /// - Parameter size: The desired image size (default: 18x18)
    /// - Returns: An NSImage configured as a template image, or nil
    func render(size: NSSize = NSSize(width: 18, height: 18)) -> NSImage? {
        switch self {
        case .sfSymbol(let name, let weight):
            return renderSFSymbol(name: name, weight: weight)
        case .bezierPath(let pathBuilder):
            return renderBezierPath(pathBuilder(), size: size)
        case .asset(let name):
            return renderAsset(name: name)
        case .none:
            return nil
        }
    }

    // MARK: - Private Rendering Methods

    private func renderSFSymbol(name: String, weight: NSFont.Weight) -> NSImage? {
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: weight)
        guard let image = NSImage(systemSymbolName: name, accessibilityDescription: name) else {
            return nil
        }
        let configuredImage = image.withSymbolConfiguration(config)
        configuredImage?.isTemplate = true
        return configuredImage
    }

    private func renderBezierPath(_ path: NSBezierPath, size: NSSize) -> NSImage {
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.labelColor.setFill()
        path.fill()
        image.unlockFocus()
        image.isTemplate = true
        return image
    }

    private func renderAsset(name: String) -> NSImage? {
        guard let image = NSImage(named: name) else {
            return nil
        }
        image.isTemplate = true
        return image
    }
}

// MARK: - Common Images

extension ControlItemImage {
    /// Chevron pointing left (for LTR expand action)
    static let chevronLeft = ControlItemImage.sfSymbol("chevron.left")

    /// Chevron pointing right (for LTR collapse action)
    static let chevronRight = ControlItemImage.sfSymbol("chevron.right")

    /// Small circle used for separator
    static let separatorDot = ControlItemImage.sfSymbol("circle.fill", weight: .regular)
}
