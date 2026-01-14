//
//  DrawerPanelController.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import SwiftUI
import Combine

// MARK: - DrawerPanelController

@MainActor
final class DrawerPanelController: ObservableObject {
    
    // MARK: - Published State
    
    @Published private(set) var isVisible: Bool = false
    
    // MARK: - Properties
    
    private var panel: DrawerPanel?
    private var hostingView: NSHostingView<AnyView>?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Panel Lifecycle
    
    func show<Content: View>(content: Content, alignedTo xPosition: CGFloat? = nil, on screen: NSScreen? = nil) {
        if panel == nil {
            createPanel(with: content)
        }
        
        guard let panel = panel else { return }
        
        if let x = xPosition {
            panel.position(alignedTo: x, on: screen)
        } else {
            panel.position(on: screen)
        }
        
        panel.orderFrontRegardless()
        isVisible = true
    }
    
    func hide() {
        panel?.orderOut(nil)
        isVisible = false
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
        
        let wrappedContent = AnyView(
            content
                .frame(height: DrawerPanel.defaultHeight)
                .background(DrawerBackgroundView())
                .clipShape(RoundedRectangle(cornerRadius: DrawerPanel.cornerRadius, style: .continuous))
        )
        
        let hosting = NSHostingView(rootView: wrappedContent)
        hosting.frame = newPanel.contentView?.bounds ?? .zero
        hosting.autoresizingMask = [.width, .height]
        
        newPanel.contentView = hosting
        
        self.panel = newPanel
        self.hostingView = hosting
    }
    
    func updateContent<Content: View>(_ content: Content) {
        let wrappedContent = AnyView(
            content
                .frame(height: DrawerPanel.defaultHeight)
                .background(DrawerBackgroundView())
                .clipShape(RoundedRectangle(cornerRadius: DrawerPanel.cornerRadius, style: .continuous))
        )
        hostingView?.rootView = wrappedContent
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

// MARK: - DrawerBackgroundView

struct DrawerBackgroundView: NSViewRepresentable {
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.state = .active
        view.wantsLayer = true
        view.layer?.cornerRadius = DrawerPanel.cornerRadius
        view.layer?.masksToBounds = true
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
