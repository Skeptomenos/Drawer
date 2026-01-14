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
    @Published private(set) var isCapturing: Bool = false
    @Published private(set) var captureError: CaptureError?
    
    let menuBarManager: MenuBarManager
    let settings: SettingsManager
    let permissions: PermissionManager
    let drawerController: DrawerPanelController
    let drawerManager: DrawerManager
    let iconCapturer: IconCapturer
    private var cancellables = Set<AnyCancellable>()
    
    var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") }
        set { UserDefaults.standard.set(newValue, forKey: "hasCompletedOnboarding") }
    }
    
    init(
        settings: SettingsManager = .shared,
        permissions: PermissionManager = .shared,
        drawerManager: DrawerManager = .shared,
        iconCapturer: IconCapturer = .shared
    ) {
        self.settings = settings
        self.permissions = permissions
        self.drawerManager = drawerManager
        self.iconCapturer = iconCapturer
        self.menuBarManager = MenuBarManager(settings: settings)
        self.drawerController = DrawerPanelController()
        
        menuBarManager.$isCollapsed
            .assign(to: &$isCollapsed)
        
        setupPermissionBindings()
        setupDrawerBindings()
        setupCapturerBindings()
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
        if isDrawerVisible {
            hideDrawer()
        } else {
            showDrawerWithCapture()
        }
    }
    
    func showDrawer() {
        showDrawerWithCapture()
    }
    
    func hideDrawer() {
        drawerController.hide()
        drawerManager.hide()
        isDrawerVisible = false
    }
    
    private func setupDrawerBindings() {
        drawerController.$isVisible
            .assign(to: &$isDrawerVisible)
        
        drawerManager.$isVisible
            .sink { [weak self] visible in
                if !visible {
                    self?.drawerController.hide()
                }
            }
            .store(in: &cancellables)
        
        menuBarManager.onShowDrawer = { [weak self] in
            self?.showDrawerWithCapture()
        }
    }
    
    private func setupCapturerBindings() {
        iconCapturer.$isCapturing
            .assign(to: &$isCapturing)
        
        iconCapturer.$lastError
            .assign(to: &$captureError)
        
        iconCapturer.$lastCaptureResult
            .compactMap { $0 }
            .sink { [weak self] result in
                self?.drawerManager.updateItems(from: result)
            }
            .store(in: &cancellables)
    }
    
    func showDrawerWithCapture() {
        Task {
            await captureAndShowDrawer()
        }
    }
    
    func captureAndShowDrawer() async {
        guard permissions.hasScreenRecording else {
            permissions.requestScreenRecording()
            return
        }
        
        drawerManager.setLoading(true)
        
        do {
            let result = try await iconCapturer.captureHiddenIcons(menuBarManager: menuBarManager)
            drawerManager.updateItems(from: result)
            drawerManager.setLoading(false)
            
            let contentView = DrawerContentView(
                items: drawerManager.items,
                isLoading: false,
                onItemTap: { [weak self] item in
                    self?.handleItemTap(item)
                }
            )
            drawerController.show(content: contentView)
            drawerManager.show()
        } catch {
            drawerManager.setError(error)
            drawerManager.setLoading(false)
            captureError = error as? CaptureError
            
            let contentView = DrawerContentView(
                items: [],
                isLoading: false
            )
            drawerController.show(content: contentView)
            drawerManager.show()
        }
    }
    
    private func handleItemTap(_ item: DrawerItem) {
        hideDrawer()
    }
}
