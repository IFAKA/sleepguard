import Foundation

public struct LaunchAgentManager: Sendable {
    public static let label = "com.faka.sleepguard.overlay"

    public let launchAgentsDirectory: URL
    public let plistURL: URL

    public init() {
        let library = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library")
        self.launchAgentsDirectory = library.appendingPathComponent("LaunchAgents", isDirectory: true)
        self.plistURL = launchAgentsDirectory.appendingPathComponent("\(Self.label).plist")
    }

    public var isInstalled: Bool {
        FileManager.default.fileExists(atPath: plistURL.path)
    }

    public func install(schedule: SleepSchedule, overlayExecutableURL: URL, configURL: URL) throws {
        try FileManager.default.createDirectory(
            at: launchAgentsDirectory,
            withIntermediateDirectories: true
        )

        let plist: [String: Any] = [
            "Label": Self.label,
            "ProgramArguments": [
                overlayExecutableURL.path,
                "--config",
                configURL.path
            ],
            "StartCalendarInterval": schedule.warningTime.launchdDictionary,
            "StandardOutPath": logURL(fileName: "overlay.out.log").path,
            "StandardErrorPath": logURL(fileName: "overlay.err.log").path,
            "ProcessType": "Interactive"
        ]

        let data = try PropertyListSerialization.data(
            fromPropertyList: plist,
            format: .xml,
            options: 0
        )
        try data.write(to: plistURL, options: .atomic)
        try bootstrapOrReload()
    }

    public func uninstall() throws {
        try? bootout()
        if FileManager.default.fileExists(atPath: plistURL.path) {
            try FileManager.default.removeItem(at: plistURL)
        }
    }

    public func bootstrapOrReload() throws {
        try? bootout()
        try runLaunchctl(arguments: ["bootstrap", guiDomain, plistURL.path])
    }

    private var guiDomain: String {
        "gui/\(getuid())"
    }

    private func bootout() throws {
        try runLaunchctl(arguments: ["bootout", guiDomain, plistURL.path])
    }

    private func runLaunchctl(arguments: [String]) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = arguments

        let errorPipe = Pipe()
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let message = String(data: errorData, encoding: .utf8) ?? "launchctl failed"
            throw LaunchAgentError.launchctlFailed(message.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }

    private func logURL(fileName: String) -> URL {
        let logs = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Logs", isDirectory: true)
            .appendingPathComponent("SleepGuard", isDirectory: true)
        try? FileManager.default.createDirectory(at: logs, withIntermediateDirectories: true)
        return logs.appendingPathComponent(fileName)
    }
}

public enum LaunchAgentError: Error, LocalizedError {
    case launchctlFailed(String)

    public var errorDescription: String? {
        switch self {
        case .launchctlFailed(let message):
            "launchctl failed: \(message)"
        }
    }
}
