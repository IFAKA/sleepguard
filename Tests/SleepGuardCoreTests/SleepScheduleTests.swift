import Foundation
import Testing
@testable import SleepGuardCore

@Test func defaultScheduleMatchesProductPlan() {
    let schedule = SleepSchedule.default

    #expect(schedule.warningTime == TimeOfDay(hour: 20, minute: 45))
    #expect(schedule.logoutTime == TimeOfDay(hour: 21, minute: 15))
    #expect(schedule.inBedTime == TimeOfDay(hour: 21, minute: 45))
    #expect(schedule.wakeTime == TimeOfDay(hour: 5, minute: 45))
    #expect(schedule.allowsOneSnooze)
    #expect(schedule.snoozeMinutes == 10)
    #expect(schedule.finalPromptMinutes == 2)
}

@Test func launchAgentTemplateUsesCalendarSchedulingWithoutKeepAlive() throws {
    let templateURL = Bundle.module.url(
        forResource: "com.faka.sleepguard.overlay",
        withExtension: "plist"
    )
    #expect(templateURL != nil)

    let data = try Data(contentsOf: templateURL!)
    let plist = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]

    #expect(plist?["StartCalendarInterval"] != nil)
    #expect(plist?["KeepAlive"] == nil)
}
