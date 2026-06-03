import Foundation
import SleepGuardCore

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var schedule: SleepSchedule
    @Published var statusMessage = ""
    @Published var isInstalled: Bool

    private let store: ScheduleStore
    private let launchAgentManager: LaunchAgentManager
    private let overlayExecutableResolver: OverlayExecutableResolver

    init(
        store: ScheduleStore,
        launchAgentManager: LaunchAgentManager,
        overlayExecutableResolver: OverlayExecutableResolver
    ) {
        self.store = store
        self.launchAgentManager = launchAgentManager
        self.overlayExecutableResolver = overlayExecutableResolver
        self.schedule = (try? store.load()) ?? .default
        self.isInstalled = launchAgentManager.isInstalled
    }

    var warningDate: Date {
        get { schedule.warningTime.date() }
        set { schedule.warningTime = TimeOfDay(date: newValue) }
    }

    var logoutDate: Date {
        get { schedule.logoutTime.date() }
        set { schedule.logoutTime = TimeOfDay(date: newValue) }
    }

    var inBedDate: Date {
        get { schedule.inBedTime.date() }
        set { schedule.inBedTime = TimeOfDay(date: newValue) }
    }

    var wakeDate: Date {
        get { schedule.wakeTime.date() }
        set { schedule.wakeTime = TimeOfDay(date: newValue) }
    }

    func saveAndInstall() {
        do {
            try store.save(schedule)
            if schedule.isEnabled {
                try launchAgentManager.install(
                    schedule: schedule,
                    overlayExecutableURL: try overlayExecutableResolver.resolve(),
                    configURL: store.configURL
                )
                statusMessage = "Schedule saved. SleepGuard will start at \(schedule.warningTime.displayString)."
            } else {
                try launchAgentManager.uninstall()
                statusMessage = "Schedule saved. SleepGuard is disabled."
            }
            isInstalled = launchAgentManager.isInstalled
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func removeSchedule() {
        do {
            try launchAgentManager.uninstall()
            isInstalled = false
            statusMessage = "LaunchAgent removed. No SleepGuard process will run while idle."
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func previewOverlay() {
        do {
            try store.save(schedule)
            let process = Process()
            process.executableURL = try overlayExecutableResolver.resolve()
            process.arguments = ["--config", store.configURL.path, "--preview", "--no-logout"]
            try process.run()
            statusMessage = "Preview opened without changing the LaunchAgent."
        } catch {
            statusMessage = error.localizedDescription
        }
    }
}
