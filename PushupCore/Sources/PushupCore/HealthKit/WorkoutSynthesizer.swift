import Foundation

public struct WorkoutPlan: Equatable, Sendable {
    public struct Activity: Equatable, Sendable {
        public let setID: UUID
        public let count: Int
        public let start: Date
        public let end: Date
    }

    public let dayID: String
    public let start: Date
    public let end: Date
    public let totalCount: Int
    public let totalEnergyKcal: Double
    public let activities: [Activity]
}

public enum WorkoutSynthesizer {
    public static func plan(
        for sets: [PushupSet],
        on day: Date,
        calendar: Calendar = .current
    ) -> WorkoutPlan? {
        let matching = sets
            .filter { calendar.isDate($0.timestamp, inSameDayAs: day) }
            .sorted { $0.timestamp < $1.timestamp }
        guard !matching.isEmpty else { return nil }

        let activities = matching.map { set in
            WorkoutPlan.Activity(
                setID: set.id,
                count: set.count,
                start: set.timestamp,
                end: set.timestamp.addingTimeInterval(
                    Constants.secondsPerPushup * Double(set.count)
                )
            )
        }
        let totalCount = matching.reduce(0) { $0 + $1.count }

        return WorkoutPlan(
            dayID: Self.dayID(for: day, calendar: calendar),
            start: activities.first!.start,
            end: activities.last!.end,
            totalCount: totalCount,
            totalEnergyKcal: Double(totalCount) * Constants.kcalPerPushup,
            activities: activities
        )
    }

    public static func dayID(for day: Date, calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: day)
    }
}
