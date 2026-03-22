//
//  SettingsView.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import SwiftUI

// MARK: - SettingsTab

/// Represents a settings tab in the sidebar navigation.
/// Conforms to CaseIterable for iteration and Identifiable for SwiftUI.
enum SettingsTab: String, CaseIterable, Identifiable {
    case general
    case menuBarLayout
    case appearance
    case about

    var id: String { rawValue }

    /// Display title for the tab
    var title: String {
        switch self {
        case .general:
            return "General"
        case .menuBarLayout:
            return "Menu Bar Layout"
        case .appearance:
            return "Appearance"
        case .about:
            return "About"
        }
    }

    /// SF Symbol icon for the tab
    var icon: String {
        switch self {
        case .general:
            return "gearshape"
        case .menuBarLayout:
            return "menubar.rectangle"
        case .appearance:
            return "paintbrush"
        case .about:
            return "info.circle"
        }
    }
}

// MARK: - SettingsView

/// Main settings window with sidebar navigation.
/// Uses NavigationSplitView for a sidebar layout matching the reference design.
/// Matches: specs/reference_images/settings-layout.jpg
struct SettingsView: View {

    // MARK: - Environment

    @Environment(AppState.self) private var appState

    // MARK: - State

    /// Currently selected tab in the sidebar
    @State private var selectedTab: SettingsTab = .general

    // MARK: - Body

    var body: some View {
        NavigationSplitView {
            sidebarContent
        } detail: {
            detailContent
                .environment(appState)
        }
        .frame(width: 680, height: 540)
        .environment(appState)
    }

    // MARK: - Sidebar Content

    /// Sidebar with navigation items
    private var sidebarContent: some View {
        List(SettingsTab.allCases, selection: $selectedTab) { tab in
            NavigationLink(value: tab) {
                Label(tab.title, systemImage: tab.icon)
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 220)
    }

    // MARK: - Detail Content

    /// Detail view showing the selected settings panel
    @ViewBuilder
    private var detailContent: some View {
        switch selectedTab {
        case .general:
            GeneralSettingsView()
        case .menuBarLayout:
            SettingsMenuBarLayoutView()
        case .appearance:
            AppearanceSettingsView()
        case .about:
            AboutView()
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environment(AppState())
}
