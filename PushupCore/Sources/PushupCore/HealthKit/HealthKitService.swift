import Foundation

public protocol HealthKitService: Sendable {
    func requestAuthorization() async throws -> Bool
    func sync(dayID: String, plan: WorkoutPlan?) async throws
}
