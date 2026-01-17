//
//  GeneralSettingsView.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import SwiftUI

struct GeneralSettingsView: View {
    @ObservedObject private var settings = SettingsManager.shared
    
    var body: some View {
        Form {
            Section {
                Toggle("Launch at Login", isOn: $settings.launchAtLogin)
            }
            
            Section {
                Toggle("Auto-collapse after delay", isOn: $settings.autoCollapseEnabled)
                
                if settings.autoCollapseEnabled {
                    HStack {
                        Text("Delay:")
                        Slider(
                            value: $settings.autoCollapseDelay,
                            in: 1...60,
                            step: 1
                        )
                        Text("\(Int(settings.autoCollapseDelay))s")
                            .monospacedDigit()
                            .frame(width: 30, alignment: .trailing)
                    }
                }
            }
            
            // MARK: - Triggers Section
            
            Section("Triggers") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Show Drawer when:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Toggle("Hover over menu bar", isOn: $settings.showOnHover)
                        .help("Show the Drawer when mouse enters the menu bar area")
                    
                    Toggle("Scroll down in menu bar", isOn: $settings.showOnScrollDown)
                        .help("Show the Drawer when scrolling down with trackpad or mouse wheel in the menu bar area")
                }
                
                Divider()
                    .padding(.vertical, 4)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Hide Drawer when:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Toggle("Scroll up", isOn: $settings.hideOnScrollUp)
                        .help("Hide the Drawer when scrolling up with trackpad or mouse wheel")
                    
                    Toggle("Click outside or switch apps", isOn: $settings.hideOnClickOutside)
                        .help("Hide the Drawer when clicking outside it or switching to another application")
                    
                    Toggle("Move mouse away from drawer", isOn: $settings.hideOnMouseAway)
                        .help("Hide the Drawer when the mouse moves away from the drawer area")
                }
            }
            
            Section {
                HStack {
                    Text("Global Hotkey:")
                    Spacer()
                    if let hotkey = settings.globalHotkey {
                        Text(hotkey.description)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(4)
                        
                        Button("Clear") {
                            settings.globalHotkey = nil
                        }
                        .buttonStyle(.borderless)
                    } else {
                        Text("Not Set")
                            .foregroundStyle(.secondary)
                    }
                }
            } footer: {
                Text("Hotkey recording will be available in a future update.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

#Preview {
    GeneralSettingsView()
        .frame(width: 450, height: 480)
}
