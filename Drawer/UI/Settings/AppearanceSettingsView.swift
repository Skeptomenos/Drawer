//
//  AppearanceSettingsView.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import SwiftUI

struct AppearanceSettingsView: View {
    @ObservedObject private var settings = SettingsManager.shared
    
    var body: some View {
        Form {
            Section {
                Toggle("Hide separator icons", isOn: $settings.hideSeparators)
                    .help("Hide the separator line in the menu bar")
            }
            
            Section {
                Toggle("Always-hidden section", isOn: $settings.alwaysHiddenEnabled)
                    .help("Enable a second separator for icons that never show")
            }
            
            Section {
                Toggle("Use full menu bar width when expanded", isOn: $settings.useFullStatusBarOnExpand)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

#Preview {
    AppearanceSettingsView()
        .frame(width: 450, height: 320)
}
