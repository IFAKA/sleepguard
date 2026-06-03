import AppKit
import SleepGuardCore

@MainActor
final class SleepGuardApp: NSObject, NSApplicationDelegate {
    private let store = ScheduleStore()
    private let launchAgentManager = LaunchAgentManager()
    private var windowController: SettingsWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)
        showSettingsWindow()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    private func showSettingsWindow() {
        let viewModel = SettingsViewModel(
            store: store,
            launchAgentManager: launchAgentManager,
            overlayExecutableResolver: OverlayExecutableResolver()
        )
        let controller = SettingsWindowController(viewModel: viewModel)
        controller.showWindow(nil)
        windowController = controller
    }
}

let app = NSApplication.shared
let delegate = SleepGuardApp()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
