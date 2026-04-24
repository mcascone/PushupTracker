import Foundation
import Testing
@testable import PushupCore

@Suite("PushupSet")
struct PushupSetTests {
    @Test("init sets count and defaults timestamp to now")
    func initDefaults() {
        let before = Date.now
        let set = PushupSet(count: 10)
        let after = Date.now

        #expect(set.count == 10)
        #expect(set.healthKitSyncedAt == nil)
        #expect(set.timestamp >= before)
        #expect(set.timestamp <= after)
    }

    @Test("init accepts an explicit timestamp")
    func initWithTimestamp() {
        let when = Date(timeIntervalSince1970: 1_700_000_000)
        let set = PushupSet(count: 5, timestamp: when)

        #expect(set.count == 5)
        #expect(set.timestamp == when)
    }

    @Test("each instance gets a unique id")
    func uniqueIDs() {
        let a = PushupSet(count: 1)
        let b = PushupSet(count: 1)

        #expect(a.id != b.id)
    }
}
