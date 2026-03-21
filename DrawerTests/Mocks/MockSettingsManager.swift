//
//  MockSettingsManager.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import Combine
import Foundation

@testable import Drawer

/// SETUP-004: Mock implementation of SettingsManager for testing.
/// Uses in-memory storage instead of @AppStorage/UserDefaults.
@MainActor
final class MockSettingsManager: ObservableObject {

    // MARK: - Published State (mirrors SettingsManager)

    @Published var autoCollapseEnabled: Bool = true
    @Published var autoCollapseDelay: Double = 10.0
    @Published var launchAtLogin: Bool = false
    @Published var hideSeparators: Bool = false
    @Published var alwaysHiddenSectionEnabled: Bool = false
    @Published var useFullStatusBarOnExpand: Bool = false
    @Published var showOnHover: Bool = false
    @Published var hasCompletedOnboarding: Bool = false
    @Published var globalHotkey: GlobalHotkeyConfig?
    @Published var overlayModeEnabled: Bool = false

    // MARK: - Combine Publishers (mirrors SettingsManager)

    let autoCollapseEnabledSubject = PassthroughSubject<Bool, Never>()
    let autoCollapseDelaySubject = PassthroughSubject<Double, Never>()
    let showOnHoverSubject = PassthroughSubject<Bool, Never>()

    var autoCollapseSettingsChanged: AnyPublisher<Void, Never> {
        Publishers.Merge(
            autoCollapseEnabledSubject.map { _ in () },
            autoCollapseDelaySubject.map { _ in () }
        )
        .eraseToAnyPublisher()
    }

    // MARK: - Test Tracking

    var resetToDefaultsCalled = false
    var resetToDefaultsCallCount = 0

    // MARK: - Initialization

    init() {}

    // MARK: - Methods

    func resetToDefaults() {
        resetToDefaultsCalled = true
        resetToDefaultsCallCount += 1

        autoCollapseEnabled = true
        autoCollapseDelay = 10.0
        launchAtLogin = false
        hideSeparators = false
        alwaysHiddenSectionEnabled = false
        useFullStatusBarOnExpand = false
        showOnHover = false
        hasCompletedOnboarding = false
        globalHotkey = nil
        overlayModeEnabled = false
    }

    // MARK: - Test Helpers

    func setAutoCollapseEnabled(_ value: Bool) {
        autoCollapseEnabled = value
        autoCollapseEnabledSubject.send(value)
    }

    func setAutoCollapseDelay(_ value: Double) {
        autoCollapseDelay = value
        autoCollapseDelaySubject.send(value)
    }

    func setShowOnHover(_ value: Bool) {
        showOnHover = value
        showOnHoverSubject.send(value)
    }
}
