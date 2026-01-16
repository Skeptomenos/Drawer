//
//  WindowInfo.swift
//  Drawer
//
//  Wrapper for CGWindowList window information.
//  Based on Ice (https://github.com/jordanbaird/Ice) implementation.
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import CoreGraphics
import Foundation

struct WindowInfo: Identifiable {
    let windowID: CGWindowID
    let frame: CGRect
    let title: String?
    let layer: Int
    let alpha: Double
    let ownerPID: pid_t
    let ownerName: String?
    let isOnScreen: Bool
    
    var id: CGWindowID { windowID }
    
    var isMenuBarItem: Bool {
        layer == kCGStatusWindowLevel
    }
    
    var owningApplication: NSRunningApplication? {
        NSRunningApplication(processIdentifier: ownerPID)
    }
    
    // MARK: - Initialization from CGWindowList Dictionary
    
    init?(dictionary: CFDictionary) {
        guard
            let info = dictionary as? [CFString: Any],
            let windowID = info[kCGWindowNumber] as? CGWindowID,
            let boundsDict = info[kCGWindowBounds],
            let frame = CGRect(dictionaryRepresentation: boundsDict as! CFDictionary),
            let layer = info[kCGWindowLayer] as? Int,
            let alpha = info[kCGWindowAlpha] as? Double,
            let ownerPID = info[kCGWindowOwnerPID] as? pid_t
        else {
            return nil
        }
        
        self.windowID = windowID
        self.frame = frame
        self.title = info[kCGWindowName] as? String
        self.layer = layer
        self.alpha = alpha
        self.ownerPID = ownerPID
        self.ownerName = info[kCGWindowOwnerName] as? String
        self.isOnScreen = info[kCGWindowIsOnscreen] as? Bool ?? false
    }
    
    // MARK: - Initialization from Window ID
    
    init?(windowID: CGWindowID) {
        var pointer = UnsafeRawPointer(bitPattern: Int(windowID))
        guard
            let array = CFArrayCreate(kCFAllocatorDefault, &pointer, 1, nil),
            let list = CGWindowListCreateDescriptionFromArray(array) as? [CFDictionary],
            let dictionary = list.first
        else {
            return nil
        }
        self.init(dictionary: dictionary)
    }
    
    // MARK: - Static Methods
    
    static func getAllWindows(
        option: CGWindowListOption = [.optionOnScreenOnly],
        relativeToWindow: CGWindowID = kCGNullWindowID
    ) -> [WindowInfo] {
        guard let windowList = CGWindowListCopyWindowInfo(option, relativeToWindow) as? [CFDictionary] else {
            return []
        }
        return windowList.compactMap { WindowInfo(dictionary: $0) }
    }
    
    static func getMenuBarItemWindows(onScreenOnly: Bool = true) -> [WindowInfo] {
        let option: CGWindowListOption = onScreenOnly
            ? [.optionOnScreenOnly, .excludeDesktopElements]
            : [.optionAll, .excludeDesktopElements]
        
        return getAllWindows(option: option).filter { $0.isMenuBarItem }
    }
    
    static func getMenuBarItemWindowsUsingCGS(onScreenOnly: Bool = true) -> [WindowInfo] {
        var option: Bridging.WindowListOption = [.menuBarItems]
        if onScreenOnly {
            option.insert(.onScreen)
        }
        
        return Bridging.getWindowList(option: option).compactMap { WindowInfo(windowID: $0) }
    }
}

// MARK: - MenuBarItemInfo

struct MenuBarItemInfo: Hashable, Identifiable {
    let windowID: CGWindowID
    let ownerPID: pid_t
    let ownerName: String?
    let title: String?
    
    var id: CGWindowID { windowID }
    
    init(from windowInfo: WindowInfo) {
        self.windowID = windowInfo.windowID
        self.ownerPID = windowInfo.ownerPID
        self.ownerName = windowInfo.ownerName
        self.title = windowInfo.title
    }
}

// MARK: - MenuBarItem

struct MenuBarItem: Identifiable {
    let window: WindowInfo
    let info: MenuBarItemInfo
    
    var id: CGWindowID { window.windowID }
    var windowID: CGWindowID { window.windowID }
    var frame: CGRect { window.frame }
    var title: String? { window.title }
    var isOnScreen: Bool { window.isOnScreen }
    var ownerName: String? { window.ownerName }
    
    init?(windowID: CGWindowID) {
        guard let window = WindowInfo(windowID: windowID) else {
            return nil
        }
        self.window = window
        self.info = MenuBarItemInfo(from: window)
    }
    
    init(window: WindowInfo) {
        self.window = window
        self.info = MenuBarItemInfo(from: window)
    }
    
    static func getMenuBarItems(
        on display: CGDirectDisplayID? = nil,
        onScreenOnly: Bool = true,
        activeSpaceOnly: Bool = true
    ) -> [MenuBarItem] {
        var option: Bridging.WindowListOption = [.menuBarItems]
        if onScreenOnly { option.insert(.onScreen) }
        if activeSpaceOnly { option.insert(.activeSpace) }
        
        var boundsPredicate: (CGWindowID) -> Bool = { _ in true }
        if let display {
            let displayBounds = CGDisplayBounds(display)
            boundsPredicate = { windowID in
                guard let windowFrame = Bridging.getWindowFrame(for: windowID) else { return false }
                return displayBounds.intersects(windowFrame)
            }
        }
        
        return Bridging.getWindowList(option: option)
            .lazy
            .filter(boundsPredicate)
            .compactMap { MenuBarItem(windowID: $0) }
    }
    
    static func getMenuBarItemsForDisplay(_ displayID: CGDirectDisplayID) -> [MenuBarItem] {
        getMenuBarItems(on: displayID, onScreenOnly: true, activeSpaceOnly: true)
    }
}
