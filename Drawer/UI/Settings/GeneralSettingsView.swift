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
            
            Section {
                Toggle("Show Drawer on hover", isOn: $settings.showOnHover)
                    .help("Show the Drawer when mouse enters the menu bar area")
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
        .frame(width: 450, height: 320)
}
