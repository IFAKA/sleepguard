import Foundation

public struct ScheduleStore: Sendable {
    public let applicationSupportDirectory: URL
    public let configURL: URL

    public init(fileManager: FileManager = .default) {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        self.applicationSupportDirectory = base.appendingPathComponent("SleepGuard", isDirectory: true)
        self.configURL = applicationSupportDirectory.appendingPathComponent("schedule.json")
    }

    public func load() throws -> SleepSchedule {
        guard FileManager.default.fileExists(atPath: configURL.path) else {
            return .default
        }

        let data = try Data(contentsOf: configURL)
        return try JSONDecoder().decode(SleepSchedule.self, from: data)
    }

    public func save(_ schedule: SleepSchedule) throws {
        try FileManager.default.createDirectory(
            at: applicationSupportDirectory,
            withIntermediateDirectories: true
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(schedule)
        try data.write(to: configURL, options: .atomic)
    }
}
