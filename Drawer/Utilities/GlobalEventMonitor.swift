//
//  GlobalEventMonitor.swift
//  Drawer
//
//  Based on Hidden Bar's EventMonitor.swift by Thanh Nguyen (2019)
//  Copyright © 2026 Drawer. MIT License.
//

import Cocoa

final class GlobalEventMonitor {

    private var monitor: Any?
    private let mask: NSEvent.EventTypeMask
    private let handler: (NSEvent?) -> Void

    init(mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent?) -> Void) {
        self.mask = mask
        self.handler = handler
    }

    deinit {
        stop()
    }

    func start() {
        guard monitor == nil else { return }
        monitor = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: handler)
    }

    func stop() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }

    var isRunning: Bool {
        monitor != nil
    }
}

final class LocalEventMonitor {

    private var monitor: Any?
    private let mask: NSEvent.EventTypeMask
    private let handler: (NSEvent) -> NSEvent?

    init(mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent) -> NSEvent?) {
        self.mask = mask
        self.handler = handler
    }

    deinit {
        stop()
    }

    func start() {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: mask, handler: handler)
    }

    func stop() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }

    var isRunning: Bool {
        monitor != nil
    }
}
