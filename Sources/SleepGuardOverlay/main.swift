import AppKit
import SleepGuardCore

@MainActor
final class OverlayApp: NSObject, NSApplicationDelegate {
    private var controller: OverlayWindowController?
    private var shouldPreventLogout = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        let options = OverlayOptions(arguments: CommandLine.arguments)
        let schedule = loadSchedule(from: options.configURL)
        shouldPreventLogout = options.noLogout

        let controller = OverlayWindowController(
            schedule: schedule,
            previewMode: options.preview,
            noLogout: options.noLogout
        )
        self.controller = controller
        controller.show()
    }

    private func loadSchedule(from url: URL?) -> SleepSchedule {
        if let url {
            do {
                let data = try Data(contentsOf: url)
                return try JSONDecoder().decode(SleepSchedule.self, from: data)
            } catch {
                NSLog("SleepGuardOverlay failed to read config: \(error.localizedDescription)")
            }
        }
        return (try? ScheduleStore().load()) ?? .default
    }
}

let app = NSApplication.shared
let delegate = OverlayApp()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
