import Foundation

public enum HealthKitAuthorizationStatus: Sendable, Equatable {
    case notDetermined
    case denied
    case granted
}

public protocol HealthKitService: Sendable {
    func authorizationStatus() async -> HealthKitAuthorizationStatus
    func requestAuthorization() async throws -> Bool
    func sync(dayID: String, plan: WorkoutPlan?) async throws
}
