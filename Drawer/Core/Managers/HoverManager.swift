//
//  HoverManager.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import Combine

@MainActor
final class HoverManager: ObservableObject {
    
    static let shared = HoverManager()
    
    @Published private(set) var isMouseInTriggerZone: Bool = false
    @Published private(set) var isMouseInDrawerArea: Bool = false
    @Published private(set) var isMonitoring: Bool = false
    
    private let menuBarHeight: CGFloat = 24
    private let debounceInterval: TimeInterval = 0.15
    private let hideDebounceInterval: TimeInterval = 0.3
    
    private var mouseMonitor: GlobalEventMonitor?
    private var showDebounceTimer: Timer?
    private var hideDebounceTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    var onShouldShowDrawer: (() -> Void)?
    var onShouldHideDrawer: (() -> Void)?
    
    private var drawerFrame: CGRect = .zero
    private var isDrawerVisible: Bool = false
    
    private init() {}
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        mouseMonitor = GlobalEventMonitor(mask: .mouseMoved) { [weak self] event in
            Task { @MainActor in
                self?.handleMouseMoved(event)
            }
        }
        mouseMonitor?.start()
        isMonitoring = true
    }
    
    func stopMonitoring() {
        mouseMonitor?.stop()
        mouseMonitor = nil
        showDebounceTimer?.invalidate()
        showDebounceTimer = nil
        hideDebounceTimer?.invalidate()
        hideDebounceTimer = nil
        isMonitoring = false
        isMouseInTriggerZone = false
        isMouseInDrawerArea = false
    }
    
    func updateDrawerFrame(_ frame: CGRect) {
        drawerFrame = frame
    }
    
    func setDrawerVisible(_ visible: Bool) {
        isDrawerVisible = visible
        if !visible {
            isMouseInDrawerArea = false
        }
    }
    
    private func handleMouseMoved(_ event: NSEvent?) {
        let mouseLocation = NSEvent.mouseLocation
        
        let wasInTriggerZone = isMouseInTriggerZone
        let wasInDrawerArea = isMouseInDrawerArea
        
        isMouseInTriggerZone = isInMenuBarTriggerZone(mouseLocation)
        isMouseInDrawerArea = isDrawerVisible && isInDrawerArea(mouseLocation)
        
        if isMouseInTriggerZone && !wasInTriggerZone && !isDrawerVisible {
            scheduleShowDrawer()
        } else if !isMouseInTriggerZone && wasInTriggerZone && !isDrawerVisible {
            cancelShowDrawer()
        }
        
        if isDrawerVisible {
            let isInSafeArea = isMouseInTriggerZone || isMouseInDrawerArea
            
            if !isInSafeArea && (wasInTriggerZone || wasInDrawerArea) {
                scheduleHideDrawer()
            } else if isInSafeArea {
                cancelHideDrawer()
            }
        }
    }
    
    private func isInMenuBarTriggerZone(_ point: NSPoint) -> Bool {
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(point) }) else {
            return false
        }
        
        let screenTop = screen.frame.maxY
        let triggerZoneTop = screenTop
        let triggerZoneBottom = screenTop - menuBarHeight
        
        return point.y >= triggerZoneBottom && point.y <= triggerZoneTop
    }
    
    private func isInDrawerArea(_ point: NSPoint) -> Bool {
        guard !drawerFrame.isEmpty else { return false }
        
        let expandedFrame = drawerFrame.insetBy(dx: -10, dy: -10)
        return expandedFrame.contains(point)
    }
    
    private func scheduleShowDrawer() {
        showDebounceTimer?.invalidate()
        showDebounceTimer = Timer.scheduledTimer(withTimeInterval: debounceInterval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, self.isMouseInTriggerZone else { return }
                self.onShouldShowDrawer?()
            }
        }
    }
    
    private func cancelShowDrawer() {
        showDebounceTimer?.invalidate()
        showDebounceTimer = nil
    }
    
    private func scheduleHideDrawer() {
        hideDebounceTimer?.invalidate()
        hideDebounceTimer = Timer.scheduledTimer(withTimeInterval: hideDebounceInterval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                let isInSafeArea = self.isMouseInTriggerZone || self.isMouseInDrawerArea
                if !isInSafeArea {
                    self.onShouldHideDrawer?()
                }
            }
        }
    }
    
    private func cancelHideDrawer() {
        hideDebounceTimer?.invalidate()
        hideDebounceTimer = nil
    }
}
