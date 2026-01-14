//
//  AppState.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import Combine

@MainActor
final class AppState: ObservableObject {
    
    @Published var isCollapsed: Bool = true
    @Published private(set) var isDrawerVisible: Bool = false
    @Published private(set) var hasRequiredPermissions: Bool = false
    
    let menuBarManager: MenuBarManager
    let settings: SettingsManager
    let permissions: PermissionManager
    let drawerController: DrawerPanelController
    private var cancellables = Set<AnyCancellable>()
    
    var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") }
        set { UserDefaults.standard.set(newValue, forKey: "hasCompletedOnboarding") }
    }
    
    init(settings: SettingsManager = .shared, permissions: PermissionManager = .shared) {
        self.settings = settings
        self.permissions = permissions
        self.menuBarManager = MenuBarManager(settings: settings)
        self.drawerController = DrawerPanelController()
        
        menuBarManager.$isCollapsed
            .assign(to: &$isCollapsed)
        
        setupPermissionBindings()
        setupDrawerBindings()
    }
    
    private func setupPermissionBindings() {
        permissions.permissionStatusChanged
            .sink { [weak self] in
                self?.hasRequiredPermissions = self?.permissions.hasAllPermissions ?? false
            }
            .store(in: &cancellables)
        
        hasRequiredPermissions = permissions.hasAllPermissions
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
    }
    
    func toggleMenuBar() {
        menuBarManager.toggle()
    }
    
    func toggleDrawer() {
        drawerController.toggle(content: DrawerContentView())
        isDrawerVisible = drawerController.isVisible
    }
    
    func showDrawer() {
        drawerController.show(content: DrawerContentView())
        isDrawerVisible = true
    }
    
    func hideDrawer() {
        drawerController.hide()
        isDrawerVisible = false
    }
    
    private func setupDrawerBindings() {
        drawerController.$isVisible
            .assign(to: &$isDrawerVisible)
        
        menuBarManager.onShowDrawer = { [weak self] in
            self?.toggleDrawer()
        }
    }
}
