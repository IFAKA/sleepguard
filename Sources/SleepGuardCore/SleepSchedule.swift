import Foundation

public struct SleepSchedule: Codable, Equatable, Sendable {
    public var warningTime: TimeOfDay
    public var logoutTime: TimeOfDay
    public var inBedTime: TimeOfDay
    public var wakeTime: TimeOfDay
    public var isEnabled: Bool
    public var allowsOneSnooze: Bool
    public var snoozeMinutes: Int
    public var finalPromptMinutes: Int

    public init(
        warningTime: TimeOfDay = TimeOfDay(hour: 20, minute: 45),
        logoutTime: TimeOfDay = TimeOfDay(hour: 21, minute: 15),
        inBedTime: TimeOfDay = TimeOfDay(hour: 21, minute: 45),
        wakeTime: TimeOfDay = TimeOfDay(hour: 5, minute: 45),
        isEnabled: Bool = true,
        allowsOneSnooze: Bool = true,
        snoozeMinutes: Int = 10,
        finalPromptMinutes: Int = 2
    ) {
        self.warningTime = warningTime
        self.logoutTime = logoutTime
        self.inBedTime = inBedTime
        self.wakeTime = wakeTime
        self.isEnabled = isEnabled
        self.allowsOneSnooze = allowsOneSnooze
        self.snoozeMinutes = snoozeMinutes
        self.finalPromptMinutes = finalPromptMinutes
    }

    public static let `default` = SleepSchedule()
}

public struct TimeOfDay: Codable, Equatable, Sendable, Hashable {
    public var hour: Int
    public var minute: Int

    public init(hour: Int, minute: Int) {
        self.hour = min(max(hour, 0), 23)
        self.minute = min(max(minute, 0), 59)
    }

    public init(date: Date, calendar: Calendar = .current) {
        self.hour = calendar.component(.hour, from: date)
        self.minute = calendar.component(.minute, from: date)
    }

    public func date(on referenceDate: Date = Date(), calendar: Calendar = .current) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: referenceDate)
        components.hour = hour
        components.minute = minute
        components.second = 0
        return calendar.date(from: components) ?? referenceDate
    }

    public func nextOccurrence(after date: Date = Date(), calendar: Calendar = .current) -> Date {
        let candidate = self.date(on: date, calendar: calendar)
        if candidate > date {
            return candidate
        }
        return calendar.date(byAdding: .day, value: 1, to: candidate) ?? candidate
    }

    public var launchdDictionary: [String: Int] {
        ["Hour": hour, "Minute": minute]
    }
}

public extension TimeOfDay {
    var displayString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date())
    }
}
