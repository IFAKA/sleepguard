import AppKit
import SleepGuardCore
import SwiftUI

@MainActor
final class OverlayWindowController: ObservableObject {
    @Published var remainingText = ""
    @Published var statusText = ""
    @Published var isCollapsed = false
    @Published var snoozeAvailable: Bool
    @Published var isFinalPrompt = false

    private let schedule: SleepSchedule
    private let noLogout: Bool
    private var deadline: Date
    private var finalDeadline: Date?
    private var timer: Timer?
    private var window: NSPanel?

    let previewMode: Bool

    init(schedule: SleepSchedule, previewMode: Bool, noLogout: Bool) {
        self.schedule = schedule
        self.previewMode = previewMode
        self.noLogout = noLogout
        self.snoozeAvailable = schedule.allowsOneSnooze
        self.deadline = previewMode
            ? Date().addingTimeInterval(15 * 60)
            : schedule.logoutTime.nextOccurrence()
    }

    func show() {
        let panel = makePanel()
        position(panel: panel)
        panel.orderFrontRegardless()
        window = panel

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

    func closePreview() {
        guard previewMode else { return }
        timer?.invalidate()
        window?.close()
        NSApp.terminate(nil)
    }

    private func makePanel() -> NSPanel {
        let contentView = OverlayView(controller: self)
        let hostingController = NSHostingController(rootView: contentView)
        let panel = OverlayPanel(
            contentRect: NSRect(origin: .zero, size: OverlayMetrics.expandedSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.contentViewController = hostingController
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.alphaValue = 1
        panel.hasShadow = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.ignoresMouseEvents = false
        return panel
    }

    private func tick() {
        let now = Date()
        if let finalDeadline {
            let remaining = max(0, Int(finalDeadline.timeIntervalSince(now)))
            remainingText = CountdownFormatter.string(fromSeconds: remaining)
            statusText = "Final prompt: logging out soon unless you cancel in macOS."
            if remaining == 0 {
                requestGracefulLogout()
            }
            return
        }

        let remaining = max(0, Int(deadline.timeIntervalSince(now)))
        remainingText = CountdownFormatter.string(fromSeconds: remaining)
        statusText = previewMode
            ? "Preview mode. Press Escape or Close when finished."
            : "Graceful logout target: \(schedule.logoutTime.displayString). In bed target: \(schedule.inBedTime.displayString)."

        if remaining == 0 {
            isFinalPrompt = true
            isCollapsed = false
            finalDeadline = now.addingTimeInterval(TimeInterval(schedule.finalPromptMinutes * 60))
            resize()
        }
    }

    private func resize() {
        guard let window else { return }
        let targetSize = isCollapsed ? OverlayMetrics.collapsedSize : OverlayMetrics.expandedSize
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
        let x = max(visible.minX + OverlayMetrics.screenMargin, visible.maxX - frame.width - OverlayMetrics.screenMargin)
        let y = visible.maxY - frame.height - OverlayMetrics.screenMargin
        panel.setFrameOrigin(NSPoint(x: x, y: y))
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

private enum OverlayMetrics {
    static let expandedSize = NSSize(width: 520, height: 156)
    static let collapsedSize = NSSize(width: 252, height: 56)
    static let screenMargin: CGFloat = 24
}

private enum CountdownFormatter {
    static func string(fromSeconds seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
