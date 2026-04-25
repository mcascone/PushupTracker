import Foundation
import SwiftData
import Testing
@testable import PushupCore

@MainActor
@Suite("PushupStore")
struct PushupStoreTests {
    private func makeStore() throws -> PushupStore {
        let schema = Schema([PushupSet.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return PushupStore(container: container)
    }

    @Test("insert adds a set")
    func insertAddsSet() throws {
        let store = try makeStore()
        try store.insert(count: 10)
        let all = try store.allSets()
        #expect(all.count == 1)
        #expect(all.first?.count == 10)
    }

    @Test("delete removes a set")
    func deleteRemovesSet() throws {
        let store = try makeStore()
        let set = try store.insert(count: 5)
        try store.delete(set)
        #expect(try store.allSets().isEmpty)
    }

    @Test("setsForToday returns only today's sets, sorted ascending")
    func todayQuery() throws {
        let store = try makeStore()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now)!
        let earlierToday = Calendar.current.startOfDay(for: .now).addingTimeInterval(60)
        try store.insert(count: 1, at: yesterday)
        try store.insert(count: 3, at: .now)
        try store.insert(count: 2, at: earlierToday)
        let today = try store.setsForToday()
        #expect(today.map(\.count) == [2, 3])
    }

    @Test("setsForDay returns sets in that day only")
    func dayQuery() throws {
        let store = try makeStore()
        let cal = Calendar.current
        let target = cal.date(byAdding: .day, value: -3, to: .now)!
        try store.insert(count: 7, at: target)
        try store.insert(count: 9, at: .now)
        let result = try store.setsForDay(target)
        #expect(result.count == 1)
        #expect(result.first?.count == 7)
    }

    @Test("allSets returns sets in reverse chronological order")
    func allSetsSorted() throws {
        let store = try makeStore()
        let earlier = Date(timeIntervalSince1970: 1_700_000_000)
        let later = Date(timeIntervalSince1970: 1_700_001_000)
        try store.insert(count: 1, at: earlier)
        try store.insert(count: 2, at: later)
        let all = try store.allSets()
        #expect(all.map(\.count) == [2, 1])
    }
}
