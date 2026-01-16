//
//  Private.swift
//  Drawer
//
//  Private CGS (CoreGraphics Server) API declarations.
//  These are undocumented Apple APIs used to get accurate menu bar item window frames.
//
//  Based on Ice (https://github.com/jordanbaird/Ice) implementation.
//  Copyright © 2026 Drawer. MIT License.
//

import CoreGraphics

// MARK: - CGS Connection

/// Returns the default connection ID for the current process.
@_silgen_name("CGSMainConnectionID")
func CGSMainConnectionID() -> CGSConnectionID

// MARK: - CGS Types

/// Connection identifier for CGS operations.
typealias CGSConnectionID = UInt32

/// Space identifier for CGS operations.
typealias CGSSpaceID = UInt64

/// Result code for CGS operations.
struct CGSError: RawRepresentable, Equatable {
    let rawValue: Int32
    
    init(rawValue: Int32) {
        self.rawValue = rawValue
    }
    
    static let success = CGSError(rawValue: 0)
    
    var logString: String {
        "CGSError(\(rawValue))"
    }
}

// MARK: - Window Functions

/// Returns the number of windows for the connection.
@_silgen_name("CGSGetWindowCount")
func CGSGetWindowCount(
    _ connection: CGSConnectionID,
    _ ownerPID: pid_t,
    _ count: UnsafeMutablePointer<Int32>
) -> CGSError

/// Returns a list of window IDs for the connection.
@_silgen_name("CGSGetWindowList")
func CGSGetWindowList(
    _ connection: CGSConnectionID,
    _ ownerPID: pid_t,
    _ maxCount: Int32,
    _ list: UnsafeMutablePointer<CGWindowID>,
    _ actualCount: UnsafeMutablePointer<Int32>
) -> CGSError

/// Returns the screen rect for a window.
@_silgen_name("CGSGetScreenRectForWindow")
func CGSGetScreenRectForWindow(
    _ connection: CGSConnectionID,
    _ windowID: CGWindowID,
    _ rect: UnsafeMutablePointer<CGRect>
) -> CGSError

/// Returns the on-screen window count.
@_silgen_name("CGSGetOnScreenWindowCount")
func CGSGetOnScreenWindowCount(
    _ connection: CGSConnectionID,
    _ ownerPID: pid_t,
    _ count: UnsafeMutablePointer<Int32>
) -> CGSError

/// Returns a list of on-screen window IDs.
@_silgen_name("CGSGetOnScreenWindowList")
func CGSGetOnScreenWindowList(
    _ connection: CGSConnectionID,
    _ ownerPID: pid_t,
    _ maxCount: Int32,
    _ list: UnsafeMutablePointer<CGWindowID>,
    _ actualCount: UnsafeMutablePointer<Int32>
) -> CGSError

// MARK: - Menu Bar Window Functions

/// Returns a list of menu bar window IDs for a process.
@_silgen_name("CGSGetProcessMenuBarWindowList")
func CGSGetProcessMenuBarWindowList(
    _ connection: CGSConnectionID,
    _ ownerPID: pid_t,
    _ maxCount: Int32,
    _ list: UnsafeMutablePointer<CGWindowID>,
    _ actualCount: UnsafeMutablePointer<Int32>
) -> CGSError

// MARK: - Space Functions

/// Returns the current active space ID.
@_silgen_name("CGSGetActiveSpace")
func CGSGetActiveSpace(_ connection: CGSConnectionID) -> CGSSpaceID

/// Returns the space ID for a window.
@_silgen_name("CGSCopySpacesForWindows")
func CGSCopySpacesForWindows(
    _ connection: CGSConnectionID,
    _ mask: Int32,
    _ windowIDs: CFArray
) -> CFArray?

// MARK: - Space Masks

/// Mask for all spaces.
let kCGSAllSpacesMask: Int32 = 0x7

/// Mask for current space only.
let kCGSCurrentSpaceMask: Int32 = 0x5

// MARK: - Window Level Constants

/// The window level for status bar items (menu bar).
let kCGStatusWindowLevel: Int = 25
