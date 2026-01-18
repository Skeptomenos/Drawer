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
        // TODO: Task 5.3.5 - Implement retry and wake-up logic
        
        logger.info("Move requested: \(item.displayName) to \(String(describing: destination))")
        
        // Validate that the item can be moved
        guard item.isMovable else {
            logger.warning("Item '\(item.displayName)' is not movable (system item)")
            throw RepositionError.notMovable(item)
        }
        
        // Check if already in correct position
        if try itemHasCorrectPosition(item: item, for: destination) {
            logger.debug("\(item.displayName) is already in correct position")
            return
        }
        
        // Save cursor location to restore later
        guard let cursorLocation = MouseCursor.location else {
            throw RepositionError.invalidCursorLocation
        }
        
        // Get initial frame to verify movement
        guard let initialFrame = Bridging.getWindowFrame(for: item.windowID) else {
            throw RepositionError.invalidItem(item)
        }
        
        // Hide cursor during operation
        MouseCursor.hide()
        defer {
            MouseCursor.warp(to: cursorLocation)
            MouseCursor.show()
        }
        
        // Single attempt for now (retry logic in Task 5.3.5)
        try await performMove(item: item, to: destination)
        
        // Verify the move succeeded by checking final position
        guard let newFrame = Bridging.getWindowFrame(for: item.windowID) else {
            throw RepositionError.invalidItem(item)
        }
        
        if newFrame != initialFrame {
            logger.info("Successfully moved \(item.displayName)")
            return
        } else {
            throw RepositionError.couldNotComplete(item)
        }
    }
    
    // MARK: - Private Implementation (Task 5.3.3)
    
    /// Performs a single move attempt using CGEvent simulation.
    ///
    /// This method simulates a Command+Drag operation:
    /// 1. Creates a mouse down event at an off-screen point with Command modifier
    /// 2. Posts mouse down and waits for frame change (drag started)
    /// 3. Creates a mouse up event at the destination point
    /// 4. Posts mouse up and waits for frame change (drop completed)
    ///
    /// - Parameters:
    ///   - item: The item to move.
    ///   - destination: Where to move the item.
    /// - Throws: `RepositionError` if event creation, posting, or frame detection fails.
    private func performMove(item: IconItem, to destination: MoveDestination) async throws {
        guard let source = CGEventSource(stateID: .hidSystemState) else {
            throw RepositionError.invalidEventSource
        }
        
        // Calculate points
        // Start at an off-screen point to avoid visual artifacts
        let startPoint = CGPoint(x: 20_000, y: 20_000)
        let endPoint = try getEndPoint(for: destination)
        
        logger.debug("Moving from off-screen to (\(endPoint.x), \(endPoint.y))")
        
        // Create mouse down event with Command modifier
        guard let mouseDownEvent = createMoveEvent(
            type: .leftMouseDown,
            location: startPoint,
            item: item,
            source: source,
            isDown: true
        ) else {
            throw RepositionError.eventCreationFailed
        }
        
        // Create mouse up event at destination (targets the destination item)
        guard let mouseUpEvent = createMoveEvent(
            type: .leftMouseUp,
            location: endPoint,
            item: destination.targetItem,
            source: source,
            isDown: false
        ) else {
            throw RepositionError.eventCreationFailed
        }
        
        // Get initial frame for change detection
        guard let initialFrame = Bridging.getWindowFrame(for: item.windowID) else {
            throw RepositionError.invalidItem(item)
        }
        
        // Permit all events during suppression
        permitAllEvents(for: source)
        
        // Post mouse down to initiate drag and wait for frame change
        postEvent(mouseDownEvent, to: item.ownerPID)
        try await waitForFrameChange(of: item, initialFrame: initialFrame)
        
        // Get mid-move frame for second wait
        guard let midFrame = Bridging.getWindowFrame(for: item.windowID) else {
            throw RepositionError.invalidItem(item)
        }
        
        // Post mouse up to complete the move and wait for frame change
        postEvent(mouseUpEvent, to: item.ownerPID)
        try await waitForFrameChange(of: item, initialFrame: midFrame)
    }
    
    /// Creates a CGEvent for menu bar item movement.
    ///
    /// The event is configured with:
    /// - Command modifier (on mouse down only) to trigger macOS menu bar rearrange mode
    /// - Window targeting fields to direct the event to the correct menu bar item
    /// - The undocumented field 0x33 for stable window ID targeting
    ///
    /// - Parameters:
    ///   - type: The mouse event type (.leftMouseDown or .leftMouseUp).
    ///   - location: The screen location for the event.
    ///   - item: The menu bar item to target.
    ///   - source: The CGEventSource for event creation.
    ///   - isDown: True for mouse down (adds Command modifier), false for mouse up.
    /// - Returns: A configured CGEvent, or nil if creation fails.
    private func createMoveEvent(
        type: CGEventType,
        location: CGPoint,
        item: IconItem,
        source: CGEventSource,
        isDown: Bool
    ) -> CGEvent? {
        guard let event = CGEvent(
            mouseEventSource: source,
            mouseType: type,
            mouseCursorPosition: location,
            mouseButton: .left
        ) else {
            logger.error("Failed to create CGEvent of type \(String(describing: type))")
            return nil
        }
        
        // Add Command modifier for drag (only on mouse down)
        // This triggers macOS's built-in menu bar rearrange functionality
        if isDown {
            event.flags = .maskCommand
        }
        
        // Set window targeting fields
        let windowID = Int64(item.windowID)
        let targetPID = Int64(item.ownerPID)
        
        event.setIntegerValueField(.eventTargetUnixProcessID, value: targetPID)
        event.setIntegerValueField(.mouseEventWindowUnderMousePointer, value: windowID)
        event.setIntegerValueField(.mouseEventWindowUnderMousePointerThatCanHandleThisEvent, value: windowID)
        
        // Set undocumented but stable field 0x33 for window ID
        // This is used by macOS to identify the target window
        event.setIntegerValueField(.windowID, value: windowID)
        
        // Set unique user data for event matching/debugging
        let userData = Int64(truncatingIfNeeded: Int(bitPattern: ObjectIdentifier(event)))
        event.setIntegerValueField(.eventSourceUserData, value: userData)
        
        return event
    }
    
    /// Posts an event to the specified process and session.
    ///
    /// Events are posted both to:
    /// 1. The specific process PID (for app-specific handling)
    /// 2. The session event tap (for system-wide effect)
    ///
    /// - Parameters:
    ///   - event: The CGEvent to post.
    ///   - pid: The process ID to post to.
    private func postEvent(_ event: CGEvent, to pid: pid_t) {
        // Post to the app's PID
        event.postToPid(pid)
        
        // Also post to session for system-wide effect
        event.post(tap: .cgSessionEventTap)
    }
    
    /// Permits all local events during suppression states.
    ///
    /// This ensures that mouse and keyboard events are not blocked during
    /// the repositioning operation, which can cause issues with event delivery.
    ///
    /// - Parameter source: The CGEventSource to configure.
    private func permitAllEvents(for source: CGEventSource) {
        let filter: CGEventFilterMask = [
            .permitLocalMouseEvents,
            .permitLocalKeyboardEvents,
            .permitSystemDefinedEvents
        ]
        
        source.setLocalEventsFilterDuringSuppressionState(
            filter,
            state: .eventSuppressionStateRemoteMouseDrag
        )
        source.setLocalEventsFilterDuringSuppressionState(
            filter,
            state: .eventSuppressionStateSuppressionInterval
        )
        source.localEventsSuppressionInterval = 0
    }
    
    /// Returns the end point for a move destination.
    ///
    /// For `.leftOfItem`, returns the left edge midpoint of the target.
    /// For `.rightOfItem`, returns the right edge midpoint of the target.
    ///
    /// - Parameter destination: The move destination.
    /// - Returns: The screen point where the mouse up event should be posted.
    /// - Throws: `RepositionError.invalidItem` if the target's frame cannot be retrieved.
    private func getEndPoint(for destination: MoveDestination) throws -> CGPoint {
        let targetItem = destination.targetItem
        guard let frame = Bridging.getWindowFrame(for: targetItem.windowID) else {
            throw RepositionError.invalidItem(targetItem)
        }
        
        switch destination {
        case .leftOfItem:
            return CGPoint(x: frame.minX, y: frame.midY)
        case .rightOfItem:
            return CGPoint(x: frame.maxX, y: frame.midY)
        }
    }
    
    /// Waits for an item's frame to change from the initial frame.
    ///
    /// This method polls the window frame at regular intervals until either:
    /// - The frame differs from the initial frame (success)
    /// - The timeout is exceeded (throws `.timeout`)
    /// - The frame cannot be retrieved (throws `.invalidItem`)
    ///
    /// - Parameters:
    ///   - item: The IconItem to monitor.
    ///   - initialFrame: The frame before the move operation.
    /// - Throws:
    ///   - `RepositionError.timeout` if `frameChangeTimeout` (50ms) is exceeded.
    ///   - `RepositionError.invalidItem` if the frame cannot be retrieved.
    private func waitForFrameChange(
        of item: IconItem,
        initialFrame: CGRect
    ) async throws {
        let deadline = ContinuousClock.now + frameChangeTimeout
        
        while ContinuousClock.now < deadline {
            guard let currentFrame = Bridging.getWindowFrame(for: item.windowID) else {
                throw RepositionError.invalidItem(item)
            }
            
            if currentFrame != initialFrame {
                logger.debug("Frame changed for \(item.displayName)")
                return
            }
            
            try await Task.sleep(for: frameChangePollInterval)
        }
        
        throw RepositionError.timeout(item)
    }
    
    /// Checks if an item is already in the correct position relative to the destination.
    ///
    /// - Parameters:
    ///   - item: The item to check.
    ///   - destination: The desired destination.
    /// - Returns: True if the item is already correctly positioned.
    /// - Throws: `RepositionError.invalidItem` if frames cannot be retrieved.
    private func itemHasCorrectPosition(item: IconItem, for destination: MoveDestination) throws -> Bool {
        guard let itemFrame = Bridging.getWindowFrame(for: item.windowID) else {
            throw RepositionError.invalidItem(item)
        }
        
        guard let targetFrame = Bridging.getWindowFrame(for: destination.targetItem.windowID) else {
            throw RepositionError.invalidItem(destination.targetItem)
        }
        
        switch destination {
        case .leftOfItem:
            // Item is to the left if its right edge equals target's left edge
            return itemFrame.maxX == targetFrame.minX
        case .rightOfItem:
            // Item is to the right if its left edge equals target's right edge
            return itemFrame.minX == targetFrame.maxX
        }
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
