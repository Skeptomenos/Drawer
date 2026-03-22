//
//  Bridging.swift
//  Drawer
//
//  Swift wrappers for private CGS APIs.
//  Based on Ice (https://github.com/jordanbaird/Ice) implementation.
//  Copyright © 2026 Drawer. MIT License.
//

import CoreGraphics
import Foundation
import os.log

// MARK: - Bridging

enum Bridging {

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.drawer",
        category: "Bridging"
    )

    // MARK: - Window Count

    static func getWindowCount() -> Int {
        var count: Int32 = 0
        let result = CGSGetWindowCount(CGSMainConnectionID(), 0, &count)
        guard result == .success else {
            logger.error("CGSGetWindowCount failed: \(result.logString)")
            return 0
        }
        return Int(count)
    }

    static func getOnScreenWindowCount() -> Int {
        var count: Int32 = 0
        let result = CGSGetOnScreenWindowCount(CGSMainConnectionID(), 0, &count)
        guard result == .success else {
            logger.error("CGSGetOnScreenWindowCount failed: \(result.logString)")
            return 0
        }
        return Int(count)
    }

    // MARK: - Window Lists

    struct WindowListOption: OptionSet {
        let rawValue: Int

        static let onScreen = WindowListOption(rawValue: 1 << 0)
        static let menuBarItems = WindowListOption(rawValue: 1 << 1)
        static let activeSpace = WindowListOption(rawValue: 1 << 2)
    }

    static func getWindowList(option: WindowListOption = []) -> [CGWindowID] {
        let list: [CGWindowID]

        if option.contains(.menuBarItems) {
            list = option.contains(.onScreen)
                ? getOnScreenMenuBarWindowList()
                : getMenuBarWindowList()
        } else if option.contains(.onScreen) {
            list = getOnScreenWindowList()
        } else {
            list = getAllWindowList()
        }

        if option.contains(.activeSpace) {
            return list.filter { isWindowOnActiveSpace($0) }
        }
        return list
    }

    private static func getAllWindowList() -> [CGWindowID] {
        let count = getWindowCount()
        guard count > 0 else { return [] }

        // Add buffer margin to handle TOCTOU race condition:
        // Windows may be created between getWindowCount() and CGSGetWindowList()
        let bufferSize = count + 10
        var list = [CGWindowID](repeating: 0, count: bufferSize)
        var actualCount: Int32 = 0

        let result = CGSGetWindowList(
            CGSMainConnectionID(),
            0,
            Int32(bufferSize),
            &list,
            &actualCount
        )

        guard result == .success else {
            logger.error("CGSGetWindowList failed: \(result.logString)")
            return []
        }

        return Array(list[..<Int(actualCount)])
    }

    private static func getOnScreenWindowList() -> [CGWindowID] {
        let count = getOnScreenWindowCount()
        guard count > 0 else { return [] }

        // Add buffer margin to handle TOCTOU race condition:
        // Windows may be created between getOnScreenWindowCount() and CGSGetOnScreenWindowList()
        let bufferSize = count + 10
        var list = [CGWindowID](repeating: 0, count: bufferSize)
        var actualCount: Int32 = 0

        let result = CGSGetOnScreenWindowList(
            CGSMainConnectionID(),
            0,
            Int32(bufferSize),
            &list,
            &actualCount
        )

        guard result == .success else {
            logger.error("CGSGetOnScreenWindowList failed: \(result.logString)")
            return []
        }

        return Array(list[..<Int(actualCount)])
    }

    private static func getMenuBarWindowList() -> [CGWindowID] {
        let count = getWindowCount()
        guard count > 0 else { return [] }

        // Add buffer margin to handle TOCTOU race condition:
        // Windows may be created between getWindowCount() and CGSGetProcessMenuBarWindowList()
        let bufferSize = count + 10
        var list = [CGWindowID](repeating: 0, count: bufferSize)
        var actualCount: Int32 = 0

        let result = CGSGetProcessMenuBarWindowList(
            CGSMainConnectionID(),
            0,
            Int32(bufferSize),
            &list,
            &actualCount
        )

        guard result == .success else {
            logger.error("CGSGetProcessMenuBarWindowList failed: \(result.logString)")
            return []
        }

        return Array(list[..<Int(actualCount)])
    }

    private static func getOnScreenMenuBarWindowList() -> [CGWindowID] {
        let menuBarWindows = Set(getMenuBarWindowList())
        let onScreenWindows = Set(getOnScreenWindowList())
        return Array(menuBarWindows.intersection(onScreenWindows))
    }

    // MARK: - Window Frame

    static func getWindowFrame(for windowID: CGWindowID) -> CGRect? {
        var rect = CGRect.zero
        let result = CGSGetScreenRectForWindow(CGSMainConnectionID(), windowID, &rect)
        guard result == .success else {
            logger.debug("CGSGetScreenRectForWindow failed for window \(windowID): \(result.logString)")
            return nil
        }
        return rect
    }

    // MARK: - Space Functions

    static var activeSpaceID: CGSSpaceID {
        CGSGetActiveSpace(CGSMainConnectionID())
    }

    static func isWindowOnActiveSpace(_ windowID: CGWindowID) -> Bool {
        guard let spaces = getSpacesForWindow(windowID) else { return false }
        return spaces.contains(activeSpaceID)
    }

    private static func getSpacesForWindow(_ windowID: CGWindowID) -> [CGSSpaceID]? {
        // Use Swift's automatic bridging to create CFArray - matches Ice's implementation
        guard let spacesArray = CGSCopySpacesForWindows(
            CGSMainConnectionID(),
            kCGSAllSpacesMask,
            [windowID] as CFArray
        ) else {
            return nil
        }

        // Cast CFArray to Swift array of space IDs
        guard let spaceIDs = spacesArray as? [CGSSpaceID] else {
            logger.error("CGSCopySpacesForWindows returned array of unexpected type")
            return nil
        }

        return spaceIDs
    }

    // MARK: - Fullscreen Detection

    static func isSpaceFullscreen(_ spaceID: CGSSpaceID) -> Bool {
        // Fullscreen spaces have specific characteristics
        // For now, return false - can be enhanced later
        return false
    }
}
