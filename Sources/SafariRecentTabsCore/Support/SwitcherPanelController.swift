import AppKit
import SwiftUI

@MainActor
public protocol SwitcherPanelControlling {
    func show(state: SwitcherState)
    func hide()
}

@MainActor
public final class SwitcherPanelController: SwitcherPanelControlling {
    private let faviconProvider: FaviconProvider
    private var panel: NSPanel?

    public init(faviconProvider: FaviconProvider) {
        self.faviconProvider = faviconProvider
    }

    public func show(state: SwitcherState) {
        let panel = panel ?? makePanel()
        let view = SwitcherOverlayView(state: state, faviconProvider: faviconProvider)
        panel.contentView = NSHostingView(rootView: view)
        place(panel: panel, tabCount: state.tabs.count)
        panel.orderFrontRegardless()
        self.panel = panel
    }

    public func hide() {
        panel?.orderOut(nil)
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 760, height: 190),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .screenSaver
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        return panel
    }

    private func place(panel: NSPanel, tabCount: Int) {
        guard let screen = NSScreen.main else {
            return
        }
        let frame = SwitcherOverlayMetrics.panelFrame(tabCount: tabCount, visibleFrame: screen.visibleFrame)
        panel.setFrame(frame, display: true)
    }
}
