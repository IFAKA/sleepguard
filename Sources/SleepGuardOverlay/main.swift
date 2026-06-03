import AppKit
import SleepGuardCore
import SwiftUI

@main
@MainActor
final class OverlayApp: NSObject, NSApplicationDelegate {
    private var controller: OverlayWindowController?
    private var shouldPreventLogout = false

    static func main() {
        let app = NSApplication.shared
        let delegate = OverlayApp()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }

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

struct OverlayOptions {
    var configURL: URL?
    var preview = false
    var noLogout = false

    init(arguments: [String]) {
        var iterator = arguments.dropFirst().makeIterator()
        while let argument = iterator.next() {
            switch argument {
            case "--config":
                if let path = iterator.next() {
                    configURL = URL(fileURLWithPath: path)
                }
            case "--preview":
                preview = true
            case "--no-logout":
                noLogout = true
            default:
                break
            }
        }
    }
}

@MainActor
final class OverlayWindowController: ObservableObject {
    @Published var remainingText = ""
    @Published var statusText = ""
    @Published var isCollapsed = false
    @Published var snoozeAvailable: Bool
    @Published var isFinalPrompt = false

    private let schedule: SleepSchedule
    private let previewMode: Bool
    private let noLogout: Bool
    private var deadline: Date
    private var finalDeadline: Date?
    private var timer: Timer?
    private var window: NSPanel?

    init(schedule: SleepSchedule, previewMode: Bool, noLogout: Bool) {
        self.schedule = schedule
        self.previewMode = previewMode
        self.noLogout = noLogout
        self.snoozeAvailable = schedule.allowsOneSnooze

        if previewMode {
            self.deadline = Date().addingTimeInterval(15 * 60)
        } else {
            self.deadline = schedule.logoutTime.nextOccurrence()
        }
    }

    func show() {
        let contentView = OverlayView(controller: self)
        let hostingController = NSHostingController(rootView: contentView)
        let panel = OverlayPanel(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 156),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.contentViewController = hostingController
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.ignoresMouseEvents = false
        position(panel: panel)
        panel.orderFrontRegardless()
        self.window = panel

        tick()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    func toggleCollapsed() {
        isCollapsed.toggle()
        resize()
    }

    func snooze() {
        guard snoozeAvailable else { return }
        snoozeAvailable = false
        deadline = deadline.addingTimeInterval(TimeInterval(schedule.snoozeMinutes * 60))
        finalDeadline = nil
        isFinalPrompt = false
        tick()
    }

    func logoutNow() {
        requestGracefulLogout()
    }

    private func tick() {
        let now = Date()
        if let finalDeadline {
            let remaining = max(0, Int(finalDeadline.timeIntervalSince(now)))
            remainingText = format(seconds: remaining)
            statusText = "Final prompt: logging out soon unless you cancel in macOS."
            if remaining == 0 {
                requestGracefulLogout()
            }
            return
        }

        let remaining = max(0, Int(deadline.timeIntervalSince(now)))
        remainingText = format(seconds: remaining)
        statusText = "Graceful logout target: \(schedule.logoutTime.displayString). In bed target: \(schedule.inBedTime.displayString)."

        if remaining == 0 {
            isFinalPrompt = true
            isCollapsed = false
            finalDeadline = now.addingTimeInterval(TimeInterval(schedule.finalPromptMinutes * 60))
            resize()
        }
    }

    private func resize() {
        guard let window else { return }
        let targetSize = isCollapsed ? NSSize(width: 252, height: 56) : NSSize(width: 520, height: 156)
        var frame = window.frame
        frame.origin.y += frame.height - targetSize.height
        frame.size = targetSize
        window.setFrame(frame, display: true, animate: true)
        position(panel: window)
    }

    private func position(panel: NSPanel) {
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        let frame = panel.frame
        let x = visible.midX - frame.width / 2
        let y = visible.maxY - frame.height - 18
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    private func format(seconds: Int) -> String {
        let minutes = seconds / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func requestGracefulLogout() {
        timer?.invalidate()
        if noLogout {
            statusText = "Logout skipped in preview mode."
            return
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", "tell application \"System Events\" to log out"]
        try? process.run()
        NSApp.terminate(nil)
    }
}

final class OverlayPanel: NSPanel {
    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        false
    }
}

struct OverlayView: View {
    @ObservedObject var controller: OverlayWindowController

    var body: some View {
        Group {
            if controller.isCollapsed {
                collapsed
            } else {
                expanded
            }
        }
        .buttonStyle(.bordered)
        .tint(.accentColor)
    }

    private var expanded: some View {
        HStack(spacing: 16) {
            Image(systemName: controller.isFinalPrompt ? "exclamationmark.circle.fill" : "moon.zzz.fill")
                .font(.system(size: 30, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(controller.isFinalPrompt ? .orange : .blue)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 7) {
                Text(controller.isFinalPrompt ? "Final save check" : "Time to wrap up")
                    .font(.headline)
                Text(controller.statusText)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Text(controller.remainingText)
                    .font(.system(.title2, design: .rounded).monospacedDigit().weight(.semibold))
                    .accessibilityLabel("Countdown")
                    .accessibilityValue(controller.remainingText)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 8) {
                Button {
                    controller.toggleCollapsed()
                } label: {
                    Label("Collapse", systemImage: "chevron.up")
                }
                .accessibilityHint("Collapses SleepGuard into a small countdown pill.")

                Button {
                    controller.snooze()
                } label: {
                    Label("Snooze", systemImage: "clock.arrow.circlepath")
                }
                .disabled(!controller.snoozeAvailable || controller.isFinalPrompt)
                .accessibilityHint("Adds one short delay to the logout target.")

                Button(role: .destructive) {
                    controller.logoutNow()
                } label: {
                    Label("Log out now", systemImage: "rectangle.portrait.and.arrow.right")
                }
                .accessibilityHint("Requests the normal macOS logout flow.")
            }
        }
        .padding(18)
        .frame(width: 520, height: 156)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.separator, lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("SleepGuard bedtime overlay")
    }

    private var collapsed: some View {
        HStack(spacing: 10) {
            Image(systemName: "moon.zzz.fill")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.blue)
                .accessibilityHidden(true)
            Text(controller.remainingText)
                .font(.system(.body, design: .rounded).monospacedDigit().weight(.semibold))
                .accessibilityLabel("Countdown")
                .accessibilityValue(controller.remainingText)
            Button {
                controller.toggleCollapsed()
            } label: {
                Image(systemName: "chevron.down")
            }
            .help("Expand SleepGuard")
            .accessibilityLabel("Expand SleepGuard")
        }
        .padding(.horizontal, 14)
        .frame(width: 252, height: 56)
        .background(.regularMaterial, in: Capsule())
        .overlay {
            Capsule().stroke(.separator, lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("SleepGuard countdown pill")
    }
}
