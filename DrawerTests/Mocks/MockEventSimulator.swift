//
//  MockEventSimulator.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import Foundation

@testable import Drawer

/// Mock implementation of EventSimulator for testing.
/// Simulates click behavior without requiring actual CGEvent posting.
final class MockEventSimulator {

    // MARK: - Test Tracking

    var simulateClickCalled = false
    var simulateClickCallCount = 0
    var lastClickPoint: CGPoint?

    // MARK: - Configurable Behavior

    /// Set to throw this error on next simulateClick attempt
    var shouldThrowError: EventSimulatorError?

    /// Simulated accessibility permission state
    var hasAccessibilityPermission: Bool = true

    // MARK: - Initialization

    init() {}

    // MARK: - Methods (mirrors EventSimulator)

    func simulateClick(at point: CGPoint) async throws {
        simulateClickCalled = true
        simulateClickCallCount += 1
        lastClickPoint = point

        if let error = shouldThrowError {
            throw error
        }

        if !hasAccessibilityPermission {
            throw EventSimulatorError.accessibilityNotGranted
        }
    }

    // MARK: - Test Helpers

    /// Resets all tracking flags and counters
    func resetTracking() {
        simulateClickCalled = false
        simulateClickCallCount = 0
        lastClickPoint = nil
    }

    /// Resets state to initial values
    func resetState() {
        shouldThrowError = nil
        hasAccessibilityPermission = true
    }

    /// Resets both tracking and state
    func reset() {
        resetTracking()
        resetState()
    }
}
