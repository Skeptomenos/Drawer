//
//  DrawerPanelController.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import os.log
import SwiftUI

// MARK: - Animation Constants

private enum DrawerAnimation {
    /// Duration for show animation (spring-like feel)
    static let showDuration: TimeInterval = 0.25

    /// Duration for hide animation (quick fade)
    static let hideDuration: TimeInterval = 0.15

    /// Vertical offset for slide-down animation
    static let slideOffset: CGFloat = 12

    /// Timing function for show (ease out for spring-like deceleration)
    static let showTimingFunction = CAMediaTimingFunction(controlPoints: 0.2, 0.9, 0.4, 1.0)

    /// Timing function for hide (ease in for quick exit)
    static let hideTimingFunction = CAMediaTimingFunction(name: .easeIn)
}

// MARK: - DrawerPanelController

@MainActor
@Observable
final class DrawerPanelController {

    // MARK: - Published State

    private(set) var isVisible: Bool = false {
        didSet {
            if oldValue != isVisible {
                onVisibilityChanged?(isVisible)
            }
        }
    }

    // MARK: - Callbacks

    /// Called when visibility changes (replaces Combine publisher for @Observable)
    @ObservationIgnored var onVisibilityChanged: ((Bool) -> Void)?

    // MARK: - Properties

    @ObservationIgnored private var panel: DrawerPanel?

    var panelFrame: CGRect {
        panel?.frame ?? .zero
    }
    @ObservationIgnored private var hostingView: NSHostingView<AnyView>?
    @ObservationIgnored private var isAnimating: Bool = false
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.drawer", category: "DrawerPanelController")

    // MARK: - Initialization

    init() {}

    // MARK: - Panel Lifecycle

    /// Gap between drawer panel and screen edge when right-aligned
    private static let screenEdgeGap: CGFloat = 5

    func show<Content: View>(content: Content, alignedTo xPosition: CGFloat? = nil, on screen: NSScreen? = nil) {
        guard !isAnimating else { return }

        if panel == nil {
            createPanel(with: content)
        } else {
            updateContent(content)
        }

        guard let panel = panel else { return }

        let targetScreen = screen ?? NSScreen.main

        if let alignX = xPosition, let targetScreen = targetScreen {
            let isXOnTargetScreen = alignX >= targetScreen.frame.minX && alignX <= targetScreen.frame.maxX

            if isXOnTargetScreen {
                let rightAlignedX = alignX - panel.frame.width
                panel.position(alignedTo: rightAlignedX, on: targetScreen)
            } else {
                let rightAlignedX = targetScreen.frame.maxX - panel.frame.width - Self.screenEdgeGap
                panel.position(alignedTo: rightAlignedX, on: targetScreen)

                #if DEBUG
                logger.debug("Separator X (\(alignX)) not on target screen, right-aligning to screen edge: \(rightAlignedX)")
                #endif
            }
        } else {
            panel.position(on: targetScreen)
        }

        animateShow(panel: panel)
    }

    func hide() {
        guard !isAnimating, let panel = panel else {
            panel?.orderOut(nil)
            isVisible = false
            return
        }

        animateHide(panel: panel)
    }

    // MARK: - Animations

    private func animateShow(panel: DrawerPanel) {
        isAnimating = true

        let targetFrame = panel.frame

        #if DEBUG
        logger.debug("=== DRAWER PANEL SHOW (B2.2) ===")
        logger.debug("Target frame: x=\(targetFrame.origin.x), y=\(targetFrame.origin.y), w=\(targetFrame.width), h=\(targetFrame.height)")
        logger.debug("Screen: \(NSScreen.main?.localizedName ?? "unknown")")
        #endif

        var startFrame = targetFrame
        startFrame.origin.y += DrawerAnimation.slideOffset
        panel.setFrame(startFrame, display: false)
        panel.alphaValue = 0

        panel.orderFrontRegardless()

        // Set visible state synchronously when panel is ordered front
        // This ensures consistent state in tests and production
        isVisible = true

        Task { @MainActor [weak self] in
            await NSAnimationContext.runAnimationGroup { context in
                context.duration = DrawerAnimation.showDuration
                context.timingFunction = DrawerAnimation.showTimingFunction
                context.allowsImplicitAnimation = true

                panel.animator().setFrame(targetFrame, display: true)
                panel.animator().alphaValue = 1
            }
            self?.isAnimating = false
            #if DEBUG
            self?.logger.debug("Drawer panel show animation complete")
            #endif
        }
    }

    private func animateHide(panel: DrawerPanel) {
        isAnimating = true

        #if DEBUG
        logger.debug("=== DRAWER PANEL HIDE (B2.2) ===")
        #endif

        // Set visible state synchronously when hide begins
        // This ensures consistent state in tests and production
        isVisible = false

        var endFrame = panel.frame
        endFrame.origin.y += DrawerAnimation.slideOffset / 2

        Task { @MainActor [weak self] in
            await NSAnimationContext.runAnimationGroup { context in
                context.duration = DrawerAnimation.hideDuration
                context.timingFunction = DrawerAnimation.hideTimingFunction
                context.allowsImplicitAnimation = true

                panel.animator().alphaValue = 0
                panel.animator().setFrame(endFrame, display: true)
            }
            panel.orderOut(nil)
            panel.alphaValue = 1
            self?.isAnimating = false
            #if DEBUG
            self?.logger.debug("Drawer panel hide animation complete")
            #endif
        }
    }

    func toggle<Content: View>(content: Content, alignedTo xPosition: CGFloat? = nil, on screen: NSScreen? = nil) {
        if isVisible {
            hide()
        } else {
            show(content: content, alignedTo: xPosition, on: screen)
        }
    }

    // MARK: - Panel Creation

    private func createPanel<Content: View>(with content: Content) {
        let newPanel = DrawerPanel()

        let styledContent = AnyView(
            DrawerContainerView {
                content
            }
            .fixedSize()
        )

        let hosting = NSHostingView(rootView: styledContent)
        let fittingSize = hosting.fittingSize
        
        var panelFrame = newPanel.frame
        panelFrame.size.width = max(fittingSize.width, DrawerPanel.defaultWidth)
        panelFrame.size.height = max(fittingSize.height, DrawerPanel.defaultHeight)
        newPanel.setFrame(panelFrame, display: false)
        
        hosting.frame = NSRect(origin: .zero, size: panelFrame.size)
        hosting.autoresizingMask = [.width, .height]

        newPanel.contentView = hosting

        self.panel = newPanel
        self.hostingView = hosting
        
        #if DEBUG
        logger.debug("Panel created with size: \(panelFrame.width)x\(panelFrame.height) (fittingSize: \(fittingSize.width)x\(fittingSize.height))")
        #endif
    }

    func updateContent<Content: View>(_ content: Content) {
        let styledContent = AnyView(
            DrawerContainerView {
                content
            }
            .fixedSize()
        )
        hostingView?.rootView = styledContent
        
        guard let hosting = hostingView, let panel = panel else { return }
        
        let fittingSize = hosting.fittingSize
        var panelFrame = panel.frame
        panelFrame.size.width = max(fittingSize.width, DrawerPanel.defaultWidth)
        panelFrame.size.height = max(fittingSize.height, DrawerPanel.defaultHeight)
        panel.setFrame(panelFrame, display: true)
        hosting.frame = NSRect(origin: .zero, size: panelFrame.size)
    }

    func updateWidth(_ width: CGFloat) {
        panel?.updateWidth(width)
    }

    // MARK: - Cleanup

    func dispose() {
        hide()
        panel = nil
        hostingView = nil
    }
}


