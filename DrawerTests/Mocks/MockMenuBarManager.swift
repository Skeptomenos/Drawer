//
//  MockMenuBarManager.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import Combine
import Foundation

@testable import Drawer

/// SETUP-006: Mock implementation of MenuBarManager for testing.
/// Simulates the menu bar toggle behavior without requiring actual NSStatusItems.
@MainActor
final class MockMenuBarManager: ObservableObject {

    // MARK: - Published State (mirrors MenuBarManager)

    @Published private(set) var isCollapsed: Bool = true
    @Published private(set) var isToggling: Bool = false

    // MARK: - Test Tracking

    var toggleCalled = false
    var toggleCallCount = 0

    var expandCalled = false
    var expandCallCount = 0

    var collapseCalled = false
    var collapseCallCount = 0

    // MARK: - Configurable Behavior

    /// Set to true to simulate the debounce blocking behavior
    var simulateDebounce: Bool = false

    /// Callback for when drawer should be shown (mirrors onShowDrawer)
    var onShowDrawer: (() -> Void)?

    // MARK: - Initialization

    init() {}

    // MARK: - Methods (mirrors MenuBarManager)

    func toggle() {
        toggleCalled = true
        toggleCallCount += 1

        guard !isToggling else { return }

        if simulateDebounce {
            isToggling = true
        }

        if isCollapsed {
            expand()
        } else {
            collapse()
        }

        if simulateDebounce {
            // In real implementation, this is async after debounceDelay
            // For testing, we reset immediately unless test wants to verify debounce
            DispatchQueue.main.async { [weak self] in
                self?.isToggling = false
            }
        }
    }

    func expand() {
        expandCalled = true
        expandCallCount += 1

        guard isCollapsed else { return }
        isCollapsed = false
    }

    func collapse() {
        collapseCalled = true
        collapseCallCount += 1

        guard !isCollapsed else { return }
        isCollapsed = true
    }

    // MARK: - Test Helpers

    /// Resets all tracking flags and counters
    func resetTracking() {
        toggleCalled = false
        toggleCallCount = 0
        expandCalled = false
        expandCallCount = 0
        collapseCalled = false
        collapseCallCount = 0
    }

    /// Resets state to initial values
    func resetState() {
        isCollapsed = true
        isToggling = false
    }

    /// Resets both tracking and state
    func reset() {
        resetTracking()
        resetState()
    }

    /// Force set isCollapsed for testing edge cases
    func setCollapsed(_ value: Bool) {
        isCollapsed = value
    }

    /// Force set isToggling for testing debounce behavior
    func setToggling(_ value: Bool) {
        isToggling = value
    }
}
