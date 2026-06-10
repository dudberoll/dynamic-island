import AppKit
import SwiftUI

@MainActor
public final class IslandPanelController {
    private let sourceURL: URL
    private let dismissBridge = IslandDismissBridge()
    private var panel: NSPanel?
    private var outsideClickMonitors: OutsideClickMonitorSet?

    public init(sourceURL: URL) {
        self.sourceURL = sourceURL
    }

    public func show() {
        if let panel {
            panel.orderFrontRegardless()
            installOutsideClickMonitors()
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

        let rootView = IslandRootView(sourceURL: sourceURL, dismissBridge: dismissBridge) { [weak self] size in
            self?.setSize(size)
        }
        panel.contentView = NSHostingView(rootView: rootView)

        self.panel = panel
        installOutsideClickMonitors()
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

    private func installOutsideClickMonitors() {
        guard outsideClickMonitors == nil else {
            return
        }

        outsideClickMonitors = OutsideClickMonitorSet { [weak self] event in
            Task { @MainActor in
                self?.requestDismissIfOutsidePanel(event)
            }
        }
    }

    private func removeOutsideClickMonitors() {
        outsideClickMonitors = nil
    }

    private func requestDismissIfOutsidePanel(_ event: NSEvent) {
        guard let panel else {
            return
        }

        let clickLocation = screenLocation(for: event)
        guard !panel.frame.contains(clickLocation) else {
            return
        }

        dismissBridge.requestOutsideClickDismiss()
    }

    private func screenLocation(for event: NSEvent) -> CGPoint {
        guard let window = event.window else {
            return NSEvent.mouseLocation
        }

        let windowPoint = event.locationInWindow
        let screenRect = window.convertToScreen(NSRect(origin: windowPoint, size: .zero))
        return screenRect.origin
    }
}

public final class IslandDismissBridge: ObservableObject {
    @Published public private(set) var outsideClickRequestID = 0

    public init() {}

    public func requestOutsideClickDismiss() {
        outsideClickRequestID &+= 1
    }
}

private final class IslandPanel: NSPanel {
    override var canBecomeKey: Bool {
        true
    }
}

private final class OutsideClickMonitorSet {
    private var localMouseMonitor: Any?
    private var globalMouseMonitor: Any?

    init(onMouseDown: @escaping (NSEvent) -> Void) {
        let mask: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown, .otherMouseDown]

        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { event in
            onMouseDown(event)
            return event
        }

        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { event in
            onMouseDown(event)
        }
    }

    deinit {
        if let localMouseMonitor {
            NSEvent.removeMonitor(localMouseMonitor)
        }

        if let globalMouseMonitor {
            NSEvent.removeMonitor(globalMouseMonitor)
        }
    }
}
