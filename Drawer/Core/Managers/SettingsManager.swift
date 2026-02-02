//
//  SettingsManager.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import Foundation
import Combine
import SwiftUI

// MARK: - SettingsManager

/// Centralized settings management using @AppStorage for persistence.
/// Uses ObservableObject (not @Observable) because @AppStorage property wrappers
/// are incompatible with @Observable's generated accessors.
@MainActor
final class SettingsManager: ObservableObject {

    // MARK: - Constants

    /// Minimum value for auto-collapse delay slider (seconds)
    static let autoCollapseDelayMin: Double = 1

    /// Maximum value for auto-collapse delay slider (seconds)
    static let autoCollapseDelayMax: Double = 60

    /// Step increment for auto-collapse delay slider (seconds)
    static let autoCollapseDelayStep: Double = 1

    /// Range for auto-collapse delay slider
    static var autoCollapseDelayRange: ClosedRange<Double> {
        autoCollapseDelayMin...autoCollapseDelayMax
    }

    // MARK: - Singleton

    static let shared = SettingsManager()

    // MARK: - Published Settings (backed by @AppStorage)

    /// Whether auto-collapse is enabled (hides icons after delay)
    @AppStorage("autoCollapseEnabled") var autoCollapseEnabled: Bool = true {
        didSet { autoCollapseEnabledSubject.send(autoCollapseEnabled) }
    }

    /// Delay in seconds before auto-collapse triggers
    @AppStorage("autoCollapseDelay") var autoCollapseDelay: Double = 10.0 {
        didSet { autoCollapseDelaySubject.send(autoCollapseDelay) }
    }

    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false {
        didSet { LaunchAtLoginManager.shared.setEnabled(launchAtLogin) }
    }

    /// Whether to hide the separator icons in the menu bar
    @AppStorage("hideSeparators") var hideSeparators: Bool = false

    /// Whether the "always hidden" section is enabled
    @AppStorage("alwaysHiddenSectionEnabled") var alwaysHiddenSectionEnabled: Bool = false {
        didSet { alwaysHiddenSectionEnabledSubject.send(alwaysHiddenSectionEnabled) }
    }

    /// Whether to use full status bar width when expanded
    @AppStorage("useFullStatusBarOnExpand") var useFullStatusBarOnExpand: Bool = false

    @AppStorage("showOnHover") var showOnHover: Bool = false {
        didSet { showOnHoverSubject.send(showOnHover) }
    }

    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false

    // MARK: - Gesture Trigger Settings

    /// Whether scrolling down in the menu bar area shows the drawer
    @AppStorage("showOnScrollDown") var showOnScrollDown: Bool = true {
        didSet { showOnScrollDownSubject.send(showOnScrollDown) }
    }

    /// Whether scrolling up while drawer is visible hides it
    @AppStorage("hideOnScrollUp") var hideOnScrollUp: Bool = true {
        didSet { hideOnScrollUpSubject.send(hideOnScrollUp) }
    }

    /// Whether clicking outside the drawer or switching apps hides it
    @AppStorage("hideOnClickOutside") var hideOnClickOutside: Bool = true {
        didSet { hideOnClickOutsideSubject.send(hideOnClickOutside) }
    }

    /// Whether moving the mouse away from the drawer hides it
    @AppStorage("hideOnMouseAway") var hideOnMouseAway: Bool = true {
        didSet { hideOnMouseAwaySubject.send(hideOnMouseAway) }
    }

    // MARK: - Display Mode Settings

    /// Whether overlay mode is enabled (floating panel instead of expand mode).
    /// When true, hidden icons appear in a floating panel at menu bar level
    /// instead of expanding the menu bar. This solves the MacBook Notch problem.
    @AppStorage("overlayModeEnabled") var overlayModeEnabled: Bool = false {
        didSet { overlayModeEnabledSubject.send(overlayModeEnabled) }
    }

    // MARK: - Combine Subjects

    let autoCollapseEnabledSubject = PassthroughSubject<Bool, Never>()
    let autoCollapseDelaySubject = PassthroughSubject<Double, Never>()
    let showOnHoverSubject = PassthroughSubject<Bool, Never>()

    // Gesture trigger subjects
    let showOnScrollDownSubject = PassthroughSubject<Bool, Never>()
    let hideOnScrollUpSubject = PassthroughSubject<Bool, Never>()
    let hideOnClickOutsideSubject = PassthroughSubject<Bool, Never>()
    let hideOnMouseAwaySubject = PassthroughSubject<Bool, Never>()

    // Always Hidden section subject
    let alwaysHiddenSectionEnabledSubject = PassthroughSubject<Bool, Never>()

    // Overlay mode subject
    let overlayModeEnabledSubject = PassthroughSubject<Bool, Never>()

    /// Combined publisher for any auto-collapse setting change
    var autoCollapseSettingsChanged: AnyPublisher<Void, Never> {
        Publishers.Merge(
            autoCollapseEnabledSubject.map { _ in () },
            autoCollapseDelaySubject.map { _ in () }
        )
        .eraseToAnyPublisher()
    }

    /// Publisher for always-hidden section setting changes
    var alwaysHiddenSettingsChanged: AnyPublisher<Void, Never> {
        alwaysHiddenSectionEnabledSubject
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    // MARK: - Global Hotkey (Codable, stored as Data)

    /// Global hotkey configuration for toggle action
    var globalHotkey: GlobalHotkeyConfig? {
        get {
            guard let data = UserDefaults.standard.data(forKey: "globalHotkey") else { return nil }
            return try? JSONDecoder().decode(GlobalHotkeyConfig.self, from: data)
        }
        set {
            if let newValue = newValue,
               let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: "globalHotkey")
            } else {
                UserDefaults.standard.removeObject(forKey: "globalHotkey")
            }
            objectWillChange.send()
        }
    }

    // MARK: - Menu Bar Layout (Codable, stored as Data)

    /// Storage key for persisted layout
    private static let layoutStorageKey = "menuBarLayout"

    /// Storage key for persisted icon positions
    private static let iconPositionsStorageKey = "menuBarIconPositions"

    /// Combine subject for layout changes
    let menuBarLayoutChangedSubject = PassthroughSubject<[SettingsLayoutItem], Never>()

    /// The persisted menu bar layout configuration.
    /// Stores the user's preferred section assignments and ordering for menu bar icons.
    var menuBarLayout: [SettingsLayoutItem] {
        get {
            guard let data = UserDefaults.standard.data(forKey: Self.layoutStorageKey) else {
                return []
            }
            return (try? JSONDecoder().decode([SettingsLayoutItem].self, from: data)) ?? []
        }
        set {
            if newValue.isEmpty {
                UserDefaults.standard.removeObject(forKey: Self.layoutStorageKey)
            } else if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: Self.layoutStorageKey)
            }
            objectWillChange.send()
            menuBarLayoutChangedSubject.send(newValue)
        }
    }

    /// Saves the menu bar layout to UserDefaults.
    /// - Parameter items: The layout items to persist
    func saveMenuBarLayout(_ items: [SettingsLayoutItem]) {
        menuBarLayout = items
    }

    /// Clears the persisted menu bar layout.
    func clearMenuBarLayout() {
        menuBarLayout = []
    }

    // MARK: - Icon Position Persistence

    /// Combine subject for icon position changes
    let iconPositionsChangedSubject = PassthroughSubject<[String: [IconIdentifier]], Never>()

    /// The persisted icon positions by section.
    /// Key: Section name ("visible", "hidden", "alwaysHidden")
    /// Value: Array of IconIdentifier in order from left to right
    var savedIconPositions: [String: [IconIdentifier]] {
        get {
            guard let data = UserDefaults.standard.data(forKey: Self.iconPositionsStorageKey) else {
                return [:]
            }
            return (try? JSONDecoder().decode([String: [IconIdentifier]].self, from: data)) ?? [:]
        }
        set {
            if newValue.isEmpty {
                UserDefaults.standard.removeObject(forKey: Self.iconPositionsStorageKey)
            } else if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: Self.iconPositionsStorageKey)
            }
            objectWillChange.send()
            iconPositionsChangedSubject.send(newValue)
        }
    }

    /// Loads saved icon positions from UserDefaults.
    /// Call this during app initialization to populate the savedIconPositions property.
    /// - Returns: The loaded icon positions dictionary
    @discardableResult
    func loadIconPositions() -> [String: [IconIdentifier]] {
        let positions = savedIconPositions
        if positions.isEmpty {
            // No saved positions - this is expected on first launch
        }
        return positions
    }

    /// Updates saved positions for a specific section.
    /// - Parameters:
    ///   - section: The menu bar section to update
    ///   - icons: The ordered array of icon identifiers for this section
    func updateSavedPositions(for section: MenuBarSectionType, icons: [IconIdentifier]) {
        var positions = savedIconPositions
        positions[section.rawValue] = icons
        savedIconPositions = positions
    }

    /// Clears all saved icon positions.
    func clearSavedPositions() {
        savedIconPositions = [:]
    }

    // MARK: - Initialization

    private init() {
        registerDefaults()
        syncLaunchAtLoginWithSystem()
    }

    private func syncLaunchAtLoginWithSystem() {
        let systemState = LaunchAtLoginManager.shared.isEnabled
        if launchAtLogin != systemState {
            launchAtLogin = systemState
        }
    }

    // MARK: - Default Registration

    /// Registers default values for first-launch experience
    private func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            "autoCollapseEnabled": true,
            "autoCollapseDelay": 10.0,
            "launchAtLogin": false,
            "hideSeparators": false,
            "alwaysHiddenSectionEnabled": false,
            "useFullStatusBarOnExpand": false,
            "showOnHover": false,
            // Gesture trigger defaults
            "showOnScrollDown": true,
            "hideOnScrollUp": true,
            "hideOnClickOutside": true,
            "hideOnMouseAway": true,
            // Overlay mode default
            "overlayModeEnabled": false
        ])
    }

    // MARK: - Reset

    /// Resets all settings to defaults
    func resetToDefaults() {
        autoCollapseEnabled = true
        autoCollapseDelay = 10.0
        launchAtLogin = false
        hideSeparators = false
        alwaysHiddenSectionEnabled = false
        useFullStatusBarOnExpand = false
        showOnHover = false
        globalHotkey = nil
        // Gesture triggers
        showOnScrollDown = true
        hideOnScrollUp = true
        hideOnClickOutside = true
        hideOnMouseAway = true
        // Overlay mode
        overlayModeEnabled = false
    }
}

// MARK: - GlobalHotkeyConfig

/// Configuration for global hotkey binding
struct GlobalHotkeyConfig: Codable, Equatable, CustomStringConvertible {
    let keyCode: UInt32
    let carbonFlags: UInt32
    let characters: String?

    // Modifier flags
    let function: Bool
    let control: Bool
    let command: Bool
    let shift: Bool
    let option: Bool
    let capsLock: Bool

    var description: String {
        var result = ""
        if function { result += "Fn" }
        if control { result += "⌃" }
        if option { result += "⌥" }
        if command { result += "⌘" }
        if shift { result += "⇧" }
        if capsLock { result += "⇪" }

        // Special keys
        switch keyCode {
        case 36: result += "⏎"  // Return
        case 51: result += "⌫"  // Delete
        case 49: result += "⎵"  // Space
        default:
            if let characters = characters {
                result += characters.uppercased()
            }
        }

        return result
    }

    static func fromLegacy(data: Data) -> GlobalHotkeyConfig? {
        struct LegacyFormat: Codable {
            let function: Bool
            let control: Bool
            let command: Bool
            let shift: Bool
            let option: Bool
            let capsLock: Bool
            let carbonFlags: UInt32
            let characters: String?
            let keyCode: UInt32
        }

        guard let legacy = try? JSONDecoder().decode(LegacyFormat.self, from: data) else {
            return nil
        }

        return GlobalHotkeyConfig(
            keyCode: legacy.keyCode,
            carbonFlags: legacy.carbonFlags,
            characters: legacy.characters,
            function: legacy.function,
            control: legacy.control,
            command: legacy.command,
            shift: legacy.shift,
            option: legacy.option,
            capsLock: legacy.capsLock
        )
    }
}
