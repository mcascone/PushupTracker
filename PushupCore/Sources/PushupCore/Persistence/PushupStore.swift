import Foundation
import SwiftData

@MainActor
public final class PushupStore {
    private let context: ModelContext

    public init(container: ModelContainer) {
        self.context = ModelContext(container)
    }

    public init(context: ModelContext) {
        self.context = context
    }

    @discardableResult
    public func insert(count: Int, at timestamp: Date = .now) throws -> PushupSet {
        let set = PushupSet(count: count, timestamp: timestamp)
        context.insert(set)
        try context.save()
        return set
    }

    public func delete(_ set: PushupSet) throws {
        context.delete(set)
        try context.save()
    }

    public func allSets() throws -> [PushupSet] {
        let descriptor = FetchDescriptor<PushupSet>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    public func setsForToday(now: Date = .now, calendar: Calendar = .current) throws -> [PushupSet] {
        try setsForDay(now, calendar: calendar)
    }

    public func setsForDay(_ date: Date, calendar: Calendar = .current) throws -> [PushupSet] {
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return [] }
        let predicate = #Predicate<PushupSet> { $0.timestamp >= start && $0.timestamp < end }
        let descriptor = FetchDescriptor<PushupSet>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        return try context.fetch(descriptor)
    }
}
