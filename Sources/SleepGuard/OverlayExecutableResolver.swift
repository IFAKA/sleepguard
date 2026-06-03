import Foundation

struct OverlayExecutableResolver {
    func resolve() throws -> URL {
        let bundledHelper = Bundle.main.bundleURL
            .appendingPathComponent("Contents/Library/LoginItems/SleepGuardOverlay.app/Contents/MacOS/SleepGuardOverlay")

        if FileManager.default.isExecutableFile(atPath: bundledHelper.path) {
            return bundledHelper
        }

        let releaseCandidate = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(".build/release/SleepGuardOverlay")
        if FileManager.default.isExecutableFile(atPath: releaseCandidate.path) {
            return releaseCandidate
        }

        let debugCandidate = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(".build/debug/SleepGuardOverlay")
        if FileManager.default.isExecutableFile(atPath: debugCandidate.path) {
            return debugCandidate
        }

        throw CocoaError(.fileNoSuchFile)
    }
}
