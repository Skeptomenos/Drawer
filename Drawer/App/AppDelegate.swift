//
//  AppDelegate.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    
    private var onboardingWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        showOnboardingIfNeeded()
    }
    
    private func showOnboardingIfNeeded() {
        guard !SettingsManager.shared.hasCompletedOnboarding else { return }
        
        let onboardingView = OnboardingView(onComplete: { [weak self] in
            self?.closeOnboarding()
            SettingsManager.shared.hasCompletedOnboarding = true
        })
        
        let hostingView = NSHostingView(rootView: onboardingView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 520, height: 420)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 420),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.contentView = hostingView
        window.center()
        window.makeKeyAndOrderFront(nil)
        
        self.onboardingWindow = window
    }
    
    private func closeOnboarding() {
        onboardingWindow?.close()
        onboardingWindow = nil
    }
}
