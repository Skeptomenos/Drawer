//
//  MenuBarSection.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import os.log

// MARK: - MenuBarSectionType

enum MenuBarSectionType: String, Codable, CaseIterable, Identifiable {
    case visible
    case hidden
    case alwaysHidden

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .visible: return "Visible"
        case .hidden: return "Hidden"
        case .alwaysHidden: return "Always Hidden"
        }
    }
}

// MARK: - MenuBarSection

@MainActor
@Observable
final class MenuBarSection: Identifiable {

    // MARK: - Properties

    let id: UUID = UUID()
    let type: MenuBarSectionType
    let controlItem: ControlItem

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.drawer",
        category: "MenuBarSection"
    )

    // MARK: - Observable State

    var isExpanded: Bool = false {
        didSet {
            guard oldValue != isExpanded else { return }
            controlItem.state = isExpanded ? .expanded : .collapsed
            logger.debug("Section '\(self.type.rawValue)' isExpanded=\(self.isExpanded)")
        }
    }

    var isEnabled: Bool = true {
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

    func collapse() {
        guard isExpanded else { return }
        isExpanded = false
    }
}
