//
//  AppState.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import Foundation
import Combine

@MainActor
final class AppState: ObservableObject {
    
    @Published var isCollapsed: Bool = true
    @Published var isDrawerVisible: Bool = false
    @Published var hasRequiredPermissions: Bool = false
    
    let menuBarManager: MenuBarManager
    let settings: SettingsManager
    private var cancellables = Set<AnyCancellable>()
    
    var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") }
        set { UserDefaults.standard.set(newValue, forKey: "hasCompletedOnboarding") }
    }
    
    init(settings: SettingsManager = .shared) {
        self.settings = settings
        self.menuBarManager = MenuBarManager(settings: settings)
        
        menuBarManager.$isCollapsed
            .assign(to: &$isCollapsed)
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
    }
    
    func toggleMenuBar() {
        menuBarManager.toggle()
    }
}
