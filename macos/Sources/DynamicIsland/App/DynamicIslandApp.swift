import AppKit
import DynamicIslandCore
import SwiftUI

@main
struct DynamicIslandApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panelController: IslandPanelController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let controller = IslandPanelController(
            sourceURL: URL(fileURLWithPath: "/Users/dudberoll/obsidian-local/to-dos.md")
        )
        panelController = controller
        controller.show()
    }
}
