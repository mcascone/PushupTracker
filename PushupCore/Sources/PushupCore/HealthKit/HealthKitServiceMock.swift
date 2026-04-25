import Foundation

public actor HealthKitServiceMock: HealthKitService {
    public struct SyncCall: Equatable, Sendable {
        public let dayID: String
        public let plan: WorkoutPlan?
    }

    public private(set) var authorizationCallCount: Int = 0
    public private(set) var syncCalls: [SyncCall] = []
    private var authorizationResult: Bool = true
    private var authorizationError: Error?
    private var syncError: Error?

    public init() {}

    public func setAuthorizationResult(_ value: Bool) {
        authorizationResult = value
    }

    public func setAuthorizationError(_ error: Error?) {
        authorizationError = error
    }

    public func setSyncError(_ error: Error?) {
        syncError = error
    }

    public func requestAuthorization() async throws -> Bool {
        authorizationCallCount += 1
        if let authorizationError { throw authorizationError }
        return authorizationResult
    }

    public func sync(dayID: String, plan: WorkoutPlan?) async throws {
        if let syncError { throw syncError }
        syncCalls.append(SyncCall(dayID: dayID, plan: plan))
    }
}
