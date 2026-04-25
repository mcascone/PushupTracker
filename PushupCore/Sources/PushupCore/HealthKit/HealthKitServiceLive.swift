import Foundation
import os
#if canImport(HealthKit)
import HealthKit

public actor HealthKitServiceLive: HealthKitService {
    private let healthStore: HKHealthStore
    private let logger = Logger(subsystem: "healthkit", category: "HealthKitServiceLive")

    public init(healthStore: HKHealthStore = HKHealthStore()) {
        self.healthStore = healthStore
    }

    public func authorizationStatus() async -> HealthKitAuthorizationStatus {
        guard HKHealthStore.isHealthDataAvailable() else { return .denied }
        let workoutStatus = healthStore.authorizationStatus(for: HKObjectType.workoutType())
        let energyStatus = healthStore.authorizationStatus(for: HKQuantityType(.activeEnergyBurned))
        if workoutStatus == .sharingDenied || energyStatus == .sharingDenied {
            return .denied
        }
        if workoutStatus == .sharingAuthorized && energyStatus == .sharingAuthorized {
            return .granted
        }
        return .notDetermined
    }

    public func requestAuthorization() async throws -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }
        let typesToShare: Set<HKSampleType> = [
            HKObjectType.workoutType(),
            HKQuantityType(.activeEnergyBurned),
        ]
        try await healthStore.requestAuthorization(toShare: typesToShare, read: [])
        let workoutStatus = healthStore.authorizationStatus(for: HKObjectType.workoutType())
        let energyStatus = healthStore.authorizationStatus(for: HKQuantityType(.activeEnergyBurned))
        return workoutStatus == .sharingAuthorized && energyStatus == .sharingAuthorized
    }

    public func sync(dayID: String, plan: WorkoutPlan?) async throws {
        try await deleteExistingWorkout(dayID: dayID)
        guard let plan else { return }
        try await writeWorkout(dayID: dayID, plan: plan)
    }

    private func deleteExistingWorkout(dayID: String) async throws {
        let predicate = HKQuery.predicateForObjects(
            withMetadataKey: Constants.dayIDMetadataKey,
            allowedValues: [dayID]
        )
        let store = healthStore
        let workouts: [HKWorkout] = try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: .workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: (samples as? [HKWorkout]) ?? [])
            }
            store.execute(query)
        }
        guard !workouts.isEmpty else { return }
        try await healthStore.delete(workouts)
        logger.debug("Deleted \(workouts.count, privacy: .public) existing workout(s) for day \(dayID, privacy: .public)")
    }

    private func writeWorkout(dayID: String, plan: WorkoutPlan) async throws {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = Constants.activityType

        let builder = HKWorkoutBuilder(
            healthStore: healthStore,
            configuration: configuration,
            device: .local()
        )

        try await builder.beginCollection(at: plan.start)

        for activity in plan.activities {
            let activityConfig = HKWorkoutConfiguration()
            activityConfig.activityType = Constants.activityType
            let workoutActivity = HKWorkoutActivity(
                workoutConfiguration: activityConfig,
                start: activity.start,
                end: activity.end,
                metadata: [
                    "PushupCount": activity.count,
                    "PushupSetID": activity.setID.uuidString,
                ]
            )
            try await builder.addWorkoutActivity(workoutActivity)
        }

        let energySample = HKQuantitySample(
            type: HKQuantityType(.activeEnergyBurned),
            quantity: HKQuantity(unit: .kilocalorie(), doubleValue: plan.totalEnergyKcal),
            start: plan.start,
            end: plan.end
        )
        try await builder.addSamples([energySample])

        try await builder.addMetadata([
            Constants.dayIDMetadataKey: dayID,
            "PushupTrackerVersion": "1",
        ])

        try await builder.endCollection(at: plan.end)
        _ = try await builder.finishWorkout()
        logger.debug("Wrote workout for day \(dayID, privacy: .public) with \(plan.activities.count, privacy: .public) activities")
    }
}
#endif
