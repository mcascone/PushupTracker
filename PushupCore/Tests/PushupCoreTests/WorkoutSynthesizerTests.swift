import Foundation
import Testing
@testable import PushupCore

@Suite("WorkoutSynthesizer")
struct WorkoutSynthesizerTests {
    private let calendar = Calendar(identifier: .gregorian)

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 12, _ min: Int = 0) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/New_York")!
        return cal.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }

    private var nyCalendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/New_York")!
        return cal
    }

    @Test("empty input returns nil")
    func emptyReturnsNil() {
        #expect(WorkoutSynthesizer.plan(for: [], on: .now) == nil)
    }

    @Test("returns nil when no sets match the day")
    func noMatchReturnsNil() {
        let day = date(2026, 4, 25)
        let other = PushupSet(count: 10, timestamp: date(2026, 4, 24))
        #expect(WorkoutSynthesizer.plan(for: [other], on: day, calendar: nyCalendar) == nil)
    }

    @Test("sorts activities by timestamp ascending")
    func sortsByTimestamp() {
        let day = date(2026, 4, 25)
        let early = PushupSet(count: 5, timestamp: date(2026, 4, 25, 8, 0))
        let mid = PushupSet(count: 3, timestamp: date(2026, 4, 25, 12, 0))
        let late = PushupSet(count: 2, timestamp: date(2026, 4, 25, 18, 0))
        let plan = WorkoutSynthesizer.plan(for: [late, early, mid], on: day, calendar: nyCalendar)
        #expect(plan?.activities.map(\.count) == [5, 3, 2])
    }

    @Test("excludes sets from other days")
    func excludesOtherDays() {
        let day = date(2026, 4, 25)
        let onDay = PushupSet(count: 10, timestamp: date(2026, 4, 25, 9, 0))
        let prevDay = PushupSet(count: 99, timestamp: date(2026, 4, 24, 23, 30))
        let nextDay = PushupSet(count: 50, timestamp: date(2026, 4, 26, 0, 30))
        let plan = WorkoutSynthesizer.plan(
            for: [onDay, prevDay, nextDay],
            on: day,
            calendar: nyCalendar
        )
        #expect(plan?.totalCount == 10)
        #expect(plan?.activities.count == 1)
    }

    @Test("activity end = start + secondsPerPushup * count")
    func activityEndComputed() {
        let start = date(2026, 4, 25, 9, 0)
        let set = PushupSet(count: 10, timestamp: start)
        let plan = WorkoutSynthesizer.plan(for: [set], on: start, calendar: nyCalendar)
        let activity = plan!.activities[0]
        #expect(activity.start == start)
        #expect(activity.end == start.addingTimeInterval(Constants.secondsPerPushup * 10))
    }

    @Test("plan start/end span first activity start through last activity end")
    func planSpansActivities() {
        let day = date(2026, 4, 25)
        let first = PushupSet(count: 5, timestamp: date(2026, 4, 25, 8, 0))
        let last = PushupSet(count: 25, timestamp: date(2026, 4, 25, 20, 0))
        let plan = WorkoutSynthesizer.plan(for: [first, last], on: day, calendar: nyCalendar)!
        #expect(plan.start == first.timestamp)
        #expect(plan.end == last.timestamp.addingTimeInterval(Constants.secondsPerPushup * 25))
    }

    @Test("totals: count sum and kcal = total * kcalPerPushup")
    func totals() {
        let day = date(2026, 4, 25)
        let sets = [
            PushupSet(count: 10, timestamp: date(2026, 4, 25, 8, 0)),
            PushupSet(count: 25, timestamp: date(2026, 4, 25, 12, 0)),
            PushupSet(count: 5, timestamp: date(2026, 4, 25, 18, 0)),
        ]
        let plan = WorkoutSynthesizer.plan(for: sets, on: day, calendar: nyCalendar)!
        #expect(plan.totalCount == 40)
        #expect(plan.totalEnergyKcal == 40.0 * Constants.kcalPerPushup)
    }

    @Test("dayID is yyyy-MM-dd in the supplied calendar's timezone")
    func dayIDFormat() {
        let day = date(2026, 4, 25)
        let id = WorkoutSynthesizer.dayID(for: day, calendar: nyCalendar)
        #expect(id == "2026-04-25")
    }
}
