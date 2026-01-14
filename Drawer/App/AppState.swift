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
    @Published private(set) var capturedIcons: [CapturedIcon] = []
    @Published private(set) var isCapturing: Bool = false
    @Published private(set) var captureError: CaptureError?
    
    let menuBarManager: MenuBarManager
    let settings: SettingsManager
    let permissions: PermissionManager
    let drawerController: DrawerPanelController
    let iconCapturer: IconCapturer
    private var cancellables = Set<AnyCancellable>()
    
    var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") }
        set { UserDefaults.standard.set(newValue, forKey: "hasCompletedOnboarding") }
    }
    
    init(
        settings: SettingsManager = .shared,
        permissions: PermissionManager = .shared,
        iconCapturer: IconCapturer = .shared
    ) {
        self.settings = settings
        self.permissions = permissions
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
        isDrawerVisible = false
    }
    
    private func setupDrawerBindings() {
        drawerController.$isVisible
            .assign(to: &$isDrawerVisible)
        
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
            .compactMap { $0?.icons }
            .assign(to: &$capturedIcons)
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
        
        do {
            let result = try await iconCapturer.captureHiddenIcons(menuBarManager: menuBarManager)
            capturedIcons = result.icons
            
            let contentView = DrawerContentView(icons: capturedIcons)
            drawerController.show(content: contentView)
        } catch {
            captureError = error as? CaptureError
            let contentView = DrawerContentView(icons: [])
            drawerController.show(content: contentView)
        }
    }
}
