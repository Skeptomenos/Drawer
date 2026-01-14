//
//  DrawerContentView.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import SwiftUI

// MARK: - DrawerContentView

struct DrawerContentView: View {
    
    let icons: [CapturedIcon]
    
    init(icons: [CapturedIcon] = []) {
        self.icons = icons
    }
    
    var body: some View {
        HStack(spacing: 8) {
            if icons.isEmpty {
                placeholderIcons
            } else {
                capturedIconsView
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
    
    private var capturedIconsView: some View {
        ForEach(icons) { icon in
            Image(decorative: icon.image, scale: NSScreen.main?.backingScaleFactor ?? 2.0)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 22, height: 22)
        }
    }
    
    private var placeholderIcons: some View {
        ForEach(0..<5, id: \.self) { index in
            Circle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 18, height: 18)
                .overlay(
                    Image(systemName: iconName(for: index))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white)
                )
        }
    }
    
    private func iconName(for index: Int) -> String {
        let icons = ["wifi", "battery.100", "speaker.wave.2", "clock", "gear"]
        return icons[index % icons.count]
    }
}

// MARK: - Preview

#Preview {
    DrawerContentView()
        .frame(height: 36)
        .background(Color.black.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .padding()
}
