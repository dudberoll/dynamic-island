import AppKit
import SwiftUI

@MainActor
public final class IslandPanelController {
    private let sourceURL: URL
    private var panel: NSPanel?

    public init(sourceURL: URL) {
        self.sourceURL = sourceURL
    }

    public func show() {
        if let panel {
            panel.orderFrontRegardless()
            return
        }

        let panel = IslandPanel(
            contentRect: rect(for: IslandTheme.collapsedSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = false

        let rootView = IslandRootView(sourceURL: sourceURL) { [weak self] size in
            self?.setSize(size)
        }
        panel.contentView = NSHostingView(rootView: rootView)

        self.panel = panel
        panel.orderFrontRegardless()
    }

    private func setSize(_ size: CGSize) {
        guard let panel else {
            return
        }

        panel.animator().setFrame(rect(for: size), display: true)
    }

    private func rect(for size: CGSize) -> NSRect {
        NotchGeometry.panelRect(for: size, on: NSScreen.main)
    }
}

private final class IslandPanel: NSPanel {
    override var canBecomeKey: Bool {
        true
    }
}
