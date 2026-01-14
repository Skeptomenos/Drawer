//
//  DrawerPanelController.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import Combine
import SwiftUI

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
        } else {
            updateContent(content)
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
        
        let styledContent = AnyView(
            DrawerContainerView {
                content
            }
        )
        
        let hosting = NSHostingView(rootView: styledContent)
        hosting.frame = newPanel.contentView?.bounds ?? .zero
        hosting.autoresizingMask = [.width, .height]
        
        newPanel.contentView = hosting
        
        self.panel = newPanel
        self.hostingView = hosting
    }
    
    func updateContent<Content: View>(_ content: Content) {
        let styledContent = AnyView(
            DrawerContainerView {
                content
            }
        )
        hostingView?.rootView = styledContent
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

// MARK: - DrawerContainerView

struct DrawerContainerView<Content: View>: View {
    
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .frame(height: DrawerDesign.drawerHeight)
            .background(DrawerBackgroundView())
            .clipShape(RoundedRectangle(cornerRadius: DrawerDesign.cornerRadius, style: .continuous))
            .overlay(rimLight)
            .shadow(
                color: Color.black.opacity(DrawerDesign.shadowOpacity),
                radius: DrawerDesign.shadowRadius,
                x: 0,
                y: DrawerDesign.shadowYOffset
            )
    }
    
    private var rimLight: some View {
        RoundedRectangle(cornerRadius: DrawerDesign.cornerRadius, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Color.white.opacity(DrawerDesign.rimLightOpacity),
                        Color.white.opacity(DrawerDesign.rimLightOpacity * 0.5)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: DrawerDesign.rimLightWidth
            )
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
        view.layer?.cornerRadius = DrawerDesign.cornerRadius
        view.layer?.masksToBounds = true
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
