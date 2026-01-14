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
    @Published var hasCompletedOnboarding: Bool = false
    
    let menuBarManager: MenuBarManager
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        menuBarManager = MenuBarManager()
        
        menuBarManager.$isCollapsed
            .assign(to: &$isCollapsed)
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
    
    func toggleMenuBar() {
        menuBarManager.toggle()
    }
}
