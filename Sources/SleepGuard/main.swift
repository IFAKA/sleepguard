import AppKit
import SleepGuardCore
import SwiftUI

@main
@MainActor
final class SleepGuardApp: NSObject, NSApplicationDelegate {
    private var window: NSWindow?
    private let store = ScheduleStore()
    private let launchAgentManager = LaunchAgentManager()

    static func main() {
        let app = NSApplication.shared
        let delegate = SleepGuardApp()
        app.delegate = delegate
        app.setActivationPolicy(.regular)
        app.run()
    }

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
        let content = SettingsView(viewModel: viewModel)
        let hostingController = NSHostingController(rootView: content)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "SleepGuard"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.contentMinSize = NSSize(width: 560, height: 430)
        window.setContentSize(NSSize(width: 640, height: 500))
        window.center()
        window.makeKeyAndOrderFront(nil)
        self.window = window
    }
}

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

struct OverlayExecutableResolver {
    func resolve() throws -> URL {
        let bundleURL = Bundle.main.bundleURL
        let bundledHelper = bundleURL
            .appendingPathComponent("Contents/Library/LoginItems/SleepGuardOverlay.app/Contents/MacOS/SleepGuardOverlay")

        if FileManager.default.isExecutableFile(atPath: bundledHelper.path) {
            return bundledHelper
        }

        let cwdCandidate = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(".build/release/SleepGuardOverlay")
        if FileManager.default.isExecutableFile(atPath: cwdCandidate.path) {
            return cwdCandidate
        }

        let debugCandidate = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(".build/debug/SleepGuardOverlay")
        if FileManager.default.isExecutableFile(atPath: debugCandidate.path) {
            return debugCandidate
        }

        throw CocoaError(.fileNoSuchFile)
    }
}

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            Form {
                Section {
                    Toggle("Enable bedtime schedule", isOn: $viewModel.schedule.isEnabled)
                        .accessibilityHint("When enabled, launchd starts the overlay at the warning time.")

                    DatePicker("Warning starts", selection: warningBinding, displayedComponents: .hourAndMinute)
                    DatePicker("Graceful logout target", selection: logoutBinding, displayedComponents: .hourAndMinute)
                    DatePicker("In-bed target", selection: inBedBinding, displayedComponents: .hourAndMinute)
                    DatePicker("Wake-up target", selection: wakeBinding, displayedComponents: .hourAndMinute)
                } header: {
                    Label("Daily rhythm", systemImage: "moon.zzz")
                }

                Section {
                    Toggle("Allow one snooze", isOn: $viewModel.schedule.allowsOneSnooze)
                    Stepper(
                        "Snooze: \(viewModel.schedule.snoozeMinutes) minutes",
                        value: $viewModel.schedule.snoozeMinutes,
                        in: 5...20,
                        step: 5
                    )
                    Picker("Final prompt", selection: $viewModel.schedule.finalPromptMinutes) {
                        Text("1 min").tag(1)
                        Text("2 min").tag(2)
                        Text("3 min").tag(3)
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel("Final prompt duration")
                } header: {
                    Label("Overlay behavior", systemImage: "rectangle.on.rectangle")
                }

                Section {
                    HStack(spacing: 12) {
                        Button {
                            viewModel.saveAndInstall()
                        } label: {
                            Label("Save Schedule", systemImage: "checkmark.circle")
                        }
                        .keyboardShortcut(.defaultAction)

                        Button {
                            viewModel.previewOverlay()
                        } label: {
                            Label("Preview Overlay", systemImage: "play.rectangle")
                        }

                        Button(role: .destructive) {
                            viewModel.removeSchedule()
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    }

                    StatusRow(isInstalled: viewModel.isInstalled, message: viewModel.statusMessage)
                }
            }
            .formStyle(.grouped)
            .padding(20)
        }
        .frame(minWidth: 560, minHeight: 430)
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: "bed.double.fill")
                .font(.system(size: 30, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.tint)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("SleepGuard")
                    .font(.title2.weight(.semibold))
                Text("Battery-first bedtime schedule with no idle background process.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(20)
    }

    private var warningBinding: Binding<Date> {
        Binding(get: { viewModel.warningDate }, set: { viewModel.warningDate = $0 })
    }

    private var logoutBinding: Binding<Date> {
        Binding(get: { viewModel.logoutDate }, set: { viewModel.logoutDate = $0 })
    }

    private var inBedBinding: Binding<Date> {
        Binding(get: { viewModel.inBedDate }, set: { viewModel.inBedDate = $0 })
    }

    private var wakeBinding: Binding<Date> {
        Binding(get: { viewModel.wakeDate }, set: { viewModel.wakeDate = $0 })
    }
}

struct StatusRow: View {
    var isInstalled: Bool
    var message: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: isInstalled ? "checkmark.seal.fill" : "powerplug")
                .foregroundStyle(isInstalled ? .green : .secondary)
                .accessibilityHidden(true)
            Text(message.isEmpty ? defaultMessage : message)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var defaultMessage: String {
        isInstalled
            ? "LaunchAgent installed. The overlay starts only at the scheduled warning time."
            : "No LaunchAgent installed. SleepGuard has no idle process."
    }
}
