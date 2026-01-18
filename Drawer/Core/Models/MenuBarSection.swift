//
//  MenuBarSection.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import Combine
import os.log

// MARK: - MenuBarSectionType

/// Represents the type of menu bar section
enum MenuBarSectionType: String, Codable, CaseIterable, Identifiable {
    /// The always-visible toggle button area
    case visible

    /// The hideable section (between separator and toggle)
    case hidden

    /// The always-hidden section (only visible in Drawer panel)
    case alwaysHidden

    var id: String { rawValue }

    /// Display name for UI
    var displayName: String {
        switch self {
        case .visible: return "Visible"
        case .hidden: return "Hidden"
        case .alwaysHidden: return "Always Hidden"
        }
    }
}

// MARK: - MenuBarSection

/// Represents a logical section of the menu bar.
/// Each section contains a control item that manages its separator/toggle.
@MainActor
final class MenuBarSection: ObservableObject, Identifiable {

    // MARK: - Properties

    let id: UUID = UUID()
    let type: MenuBarSectionType
    let controlItem: ControlItem

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.drawer",
        category: "MenuBarSection"
    )
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Published State

    /// Whether this section is currently expanded (showing its icons)
    @Published var isExpanded: Bool = false {
        didSet {
            guard oldValue != isExpanded else { return }
            controlItem.state = isExpanded ? .expanded : .collapsed
            logger.debug("Section '\(self.type.rawValue)' isExpanded=\(self.isExpanded)")
        }
    }

    /// Whether this section is enabled (visible in menu bar)
    @Published var isEnabled: Bool = true {
        didSet {
            guard oldValue != isEnabled else { return }
            if !isEnabled {
                controlItem.state = .hidden
            } else {
                controlItem.state = isExpanded ? .expanded : .collapsed
            }
            logger.debug("Section '\(self.type.rawValue)' isEnabled=\(self.isEnabled)")
        }
    }

    // MARK: - Initialization

    /// Creates a new MenuBarSection
    /// - Parameters:
    ///   - type: The type of section
    ///   - controlItem: The control item managing this section's status bar presence
    ///   - isExpanded: Initial expanded state (default: false)
    ///   - isEnabled: Initial enabled state (default: true)
    init(
        type: MenuBarSectionType,
        controlItem: ControlItem,
        isExpanded: Bool = false,
        isEnabled: Bool = true
    ) {
        self.type = type
        self.controlItem = controlItem
        self.isExpanded = isExpanded
        self.isEnabled = isEnabled

        // Apply initial state
        if !isEnabled {
            controlItem.state = .hidden
        } else {
            controlItem.state = isExpanded ? .expanded : .collapsed
        }
    }

    // MARK: - Actions

    /// Toggles the expanded state of this section
    func toggle() {
        isExpanded.toggle()
    }

    /// Expands this section (shows hidden icons)
    func expand() {
        guard !isExpanded else { return }
        isExpanded = true
    }

    /// Collapses this section (hides icons)
    func collapse() {
        guard isExpanded else { return }
        isExpanded = false
    }

    deinit {
        cancellables.removeAll()
    }
}
