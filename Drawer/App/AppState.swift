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
    
    init() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
    
    func toggleMenuBar() {
        isCollapsed.toggle()
    }
}
