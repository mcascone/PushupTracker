import Foundation
import Testing
@testable import PushupCore

@Suite("HealthKitServiceMock")
struct HealthKitServiceMockTests {
    private struct StubError: Error, Equatable {}

    @Test("authorizationStatus returns configured value and counts calls")
    func authorizationStatusReturns() async {
        let mock = HealthKitServiceMock()

        var status = await mock.authorizationStatus()
        #expect(status == .notDetermined)

        await mock.setAuthorizationStatus(.granted)
        status = await mock.authorizationStatus()
        #expect(status == .granted)

        await mock.setAuthorizationStatus(.denied)
        status = await mock.authorizationStatus()
        #expect(status == .denied)

        await #expect(mock.statusCallCount == 3)
    }

    @Test("requestAuthorization records calls and returns configured result")
    func authorizationRecordsAndReturns() async throws {
        let mock = HealthKitServiceMock()
        await mock.setAuthorizationResult(false)

        let result = try await mock.requestAuthorization()

        #expect(result == false)
        await #expect(mock.authorizationCallCount == 1)

        _ = try await mock.requestAuthorization()
        await #expect(mock.authorizationCallCount == 2)
    }

    @Test("requestAuthorization throws configured error")
    func authorizationThrows() async {
        let mock = HealthKitServiceMock()
        await mock.setAuthorizationError(StubError())

        await #expect(throws: StubError.self) {
            _ = try await mock.requestAuthorization()
        }
    }

    @Test("sync records dayID and plan")
    func syncRecords() async throws {
        let mock = HealthKitServiceMock()
        let plan = WorkoutPlan(
            dayID: "2026-04-25",
            start: .now,
            end: .now.addingTimeInterval(60),
            totalCount: 10,
            totalEnergyKcal: 3.2,
            activities: []
        )

        try await mock.sync(dayID: "2026-04-25", plan: plan)
        try await mock.sync(dayID: "2026-04-24", plan: nil)

        let calls = await mock.syncCalls
        #expect(calls.count == 2)
        #expect(calls[0] == .init(dayID: "2026-04-25", plan: plan))
        #expect(calls[1] == .init(dayID: "2026-04-24", plan: nil))
    }

    @Test("sync throws configured error and does not record the call")
    func syncThrows() async {
        let mock = HealthKitServiceMock()
        await mock.setSyncError(StubError())

        await #expect(throws: StubError.self) {
            try await mock.sync(dayID: "2026-04-25", plan: nil)
        }
        await #expect(mock.syncCalls.isEmpty)
    }
}
