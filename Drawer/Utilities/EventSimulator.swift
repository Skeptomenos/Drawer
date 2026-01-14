//
//  EventSimulator.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import CoreGraphics
import os.log

// MARK: - EventSimulatorError

/// Errors that can occur during event simulation
enum EventSimulatorError: Error, LocalizedError {
    case accessibilityNotGranted
    case eventCreationFailed
    case eventPostingFailed
    case invalidCoordinates
    
    var errorDescription: String? {
        switch self {
        case .accessibilityNotGranted:
            return "Accessibility permission is required to simulate clicks"
        case .eventCreationFailed:
            return "Failed to create CGEvent"
        case .eventPostingFailed:
            return "Failed to post CGEvent"
        case .invalidCoordinates:
            return "Invalid screen coordinates"
        }
    }
}

// MARK: - EventSimulator

/// Simulates mouse events using CGEvent for click-through functionality.
///
/// This utility enables the Drawer to forward clicks on "ghost" icons to the
/// real menu bar items. It requires Accessibility permission to post events.
///
/// ## Usage
/// ```swift
/// let simulator = EventSimulator.shared
/// try await simulator.simulateClick(at: item.clickTarget)
/// ```
///
/// ## Security Note
/// CGEvent posting requires Accessibility permission. The simulator checks
/// this before attempting to post events and throws an appropriate error
/// if permission is not granted.
final class EventSimulator {
    
    // MARK: - Singleton
    
    static let shared = EventSimulator()
    
    // MARK: - Logger
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.drawer", category: "EventSimulator")
    
    // MARK: - Configuration
    
    private let moveToClickDelayNanoseconds: UInt64 = 10_000_000
    private let clickDurationNanoseconds: UInt64 = 50_000_000
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Permission Check
    
    var hasAccessibilityPermission: Bool {
        AXIsProcessTrusted()
    }
    
    func requestAccessibilityIfNeeded() {
        guard !hasAccessibilityPermission else { return }
        
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
    
    // MARK: - Click Simulation
    
    /// Simulates a mouse click at the specified screen coordinates.
    /// Requires Accessibility permission. Sequence: move cursor → mouse down → mouse up.
    func simulateClick(at point: CGPoint) async throws {
        logger.info("Simulating click at (\(point.x), \(point.y))")
        
        guard hasAccessibilityPermission else {
            logger.error("Accessibility permission not granted")
            throw EventSimulatorError.accessibilityNotGranted
        }
        
        guard isValidScreenPoint(point) else {
            logger.error("Invalid coordinates: (\(point.x), \(point.y))")
            throw EventSimulatorError.invalidCoordinates
        }
        
        try postMouseMove(to: point)
        try await Task.sleep(nanoseconds: moveToClickDelayNanoseconds)
        try postMouseDown(at: point)
        try await Task.sleep(nanoseconds: clickDurationNanoseconds)
        try postMouseUp(at: point)
        
        logger.info("Click simulation completed successfully")
    }
    
    // MARK: - Event Posting
    
    private func postMouseMove(to point: CGPoint) throws {
        guard let event = CGEvent(
            mouseEventSource: nil,
            mouseType: .mouseMoved,
            mouseCursorPosition: point,
            mouseButton: .left
        ) else {
            logger.error("Failed to create mouse move event")
            throw EventSimulatorError.eventCreationFailed
        }
        
        event.post(tap: .cghidEventTap)
        logger.debug("Posted mouse move to (\(point.x), \(point.y))")
    }
    
    private func postMouseDown(at point: CGPoint) throws {
        guard let event = CGEvent(
            mouseEventSource: nil,
            mouseType: .leftMouseDown,
            mouseCursorPosition: point,
            mouseButton: .left
        ) else {
            logger.error("Failed to create mouse down event")
            throw EventSimulatorError.eventCreationFailed
        }
        
        event.post(tap: .cghidEventTap)
        logger.debug("Posted mouse down at (\(point.x), \(point.y))")
    }
    
    private func postMouseUp(at point: CGPoint) throws {
        guard let event = CGEvent(
            mouseEventSource: nil,
            mouseType: .leftMouseUp,
            mouseCursorPosition: point,
            mouseButton: .left
        ) else {
            logger.error("Failed to create mouse up event")
            throw EventSimulatorError.eventCreationFailed
        }
        
        event.post(tap: .cghidEventTap)
        logger.debug("Posted mouse up at (\(point.x), \(point.y))")
    }
    
    // MARK: - Validation
    
    private func isValidScreenPoint(_ point: CGPoint) -> Bool {
        for screen in NSScreen.screens {
            if screen.frame.contains(point) {
                return true
            }
        }
        
        if let mainScreen = NSScreen.main {
            let menuBarHeight: CGFloat = 24
            let menuBarRect = CGRect(
                x: mainScreen.frame.minX,
                y: mainScreen.frame.maxY - menuBarHeight,
                width: mainScreen.frame.width,
                height: menuBarHeight
            )
            if menuBarRect.contains(point) {
                return true
            }
        }
        
        return false
    }
    
    // MARK: - Cursor Management
    
    func saveCursorPosition() -> CGPoint {
        NSEvent.mouseLocation
    }
    
    func restoreCursorPosition(_ point: CGPoint) throws {
        try postMouseMove(to: convertToScreenCoordinates(point))
    }
    
    private func convertToScreenCoordinates(_ point: CGPoint) -> CGPoint {
        guard let mainScreen = NSScreen.main else { return point }
        return CGPoint(x: point.x, y: mainScreen.frame.height - point.y)
    }
}
