//
//  IconRepositioner.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import CoreGraphics
import Foundation
import os.log

// MARK: - RepositionError

/// Errors that can occur during icon repositioning operations.
/// Each error case provides a localized description for user feedback.
enum RepositionError: Error, LocalizedError {
    /// The item cannot be moved (e.g., Control Center, Clock).
    case notMovable(IconItem)
    
    /// The item is invalid or no longer exists.
    case invalidItem(IconItem)
    
    /// The operation timed out waiting for frame change.
    case timeout(IconItem)
    
    /// Failed to create a CGEvent for the move operation.
    case eventCreationFailed
    
    /// Failed to get the current cursor location.
    case invalidCursorLocation
    
    /// Failed to create a CGEventSource.
    case invalidEventSource
    
    /// The move operation could not be completed after all retries.
    case couldNotComplete(IconItem)
    
    var errorDescription: String? {
        switch self {
        case .notMovable(let item):
            return "The item '\(item.displayName)' cannot be moved by macOS"
        case .invalidItem(let item):
            return "The item '\(item.displayName)' is invalid or no longer exists"
        case .timeout(let item):
            return "Timed out waiting for '\(item.displayName)' to move"
        case .eventCreationFailed:
            return "Failed to create mouse event for repositioning"
        case .invalidCursorLocation:
            return "Failed to get current cursor location"
        case .invalidEventSource:
            return "Failed to create event source for repositioning"
        case .couldNotComplete(let item):
            return "Could not move '\(item.displayName)' after multiple attempts"
        }
    }
}

// MARK: - MoveDestination

/// The target destination for a repositioning operation.
/// Icons can be moved to the left or right of another icon.
enum MoveDestination {
    /// Move the icon to the left of the specified item.
    case leftOfItem(IconItem)
    
    /// Move the icon to the right of the specified item.
    case rightOfItem(IconItem)
    
    /// The target item that defines the destination.
    var targetItem: IconItem {
        switch self {
        case .leftOfItem(let item):
            return item
        case .rightOfItem(let item):
            return item
        }
    }
}

// MARK: - CGEventField Extension

private extension CGEventField {
    /// Undocumented but stable field for setting the window ID on a CGEvent.
    /// This allows targeting events to specific windows.
    static let windowID = CGEventField(rawValue: 0x33)!
}

// MARK: - IconRepositioner

/// Engine for programmatically repositioning menu bar icons using CGEvent simulation.
///
/// This class uses Command+Drag simulation (the same mechanism users use manually)
/// to reposition icons. It handles:
/// - Cursor hiding during moves (to prevent visual glitches)
/// - Retries with wake-up clicks for unresponsive apps
/// - Frame change verification to confirm move success
///
/// Based on Ice's proven approach for reliable menu bar icon manipulation.
///
/// - Important: Icons in `IconIdentifier.immovableItems` (Control Center, Clock, etc.)
///   cannot be moved and will throw `RepositionError.notMovable`.
@MainActor
final class IconRepositioner {
    
    // MARK: - Singleton
    
    /// Shared instance for icon repositioning operations.
    static let shared = IconRepositioner()
    
    // MARK: - Configuration
    
    /// Maximum number of retry attempts for failed moves.
    private let maxRetries: Int = 5
    
    /// Maximum time to wait for a frame change after a move event.
    private let frameChangeTimeout: Duration = .milliseconds(50)
    
    /// Polling interval when waiting for frame change.
    private let frameChangePollInterval: Duration = .milliseconds(10)
    
    // MARK: - Private Properties
    
    /// Logger for repositioning operations.
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.drawer",
        category: "IconRepositioner"
    )
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public API
    
    /// Moves a menu bar icon to a new position.
    ///
    /// This method simulates a Command+Drag operation to reposition the icon.
    /// The mouse cursor is hidden during the operation and restored afterward.
    ///
    /// - Parameters:
    ///   - item: The icon to move.
    ///   - destination: The target position (left or right of another icon).
    ///
    /// - Throws: `RepositionError` if the move fails.
    ///   - `.notMovable`: If the item is a system icon that cannot be moved.
    ///   - `.invalidItem`: If the item is no longer valid.
    ///   - `.timeout`: If the frame doesn't change within the timeout.
    ///   - `.couldNotComplete`: If all retry attempts fail.
    ///
    /// - Note: This method will retry up to `maxRetries` times, using wake-up
    ///   clicks between attempts to handle unresponsive apps.
    func move(item: IconItem, to destination: MoveDestination) async throws {
        // TODO: Task 5.3.3 - Implement CGEvent move logic
        // TODO: Task 5.3.4 - Implement frame change detection
        // TODO: Task 5.3.5 - Implement retry and wake-up logic
        
        // Placeholder implementation - will be completed in subsequent tasks
        logger.info("Move requested: \(item.displayName) to \(String(describing: destination))")
        
        // Validate that the item can be moved
        guard item.isMovable else {
            logger.warning("Item '\(item.displayName)' is not movable (system item)")
            throw RepositionError.notMovable(item)
        }
        
        // Full implementation coming in tasks 5.3.3-5.3.5
        throw RepositionError.couldNotComplete(item)
    }
}

// MARK: - Testing Support

#if DEBUG
extension IconRepositioner {
    /// Creates a new instance for testing purposes.
    /// Use this instead of `shared` in unit tests to avoid shared state.
    static func createForTesting() -> IconRepositioner {
        IconRepositioner()
    }
}
#endif
