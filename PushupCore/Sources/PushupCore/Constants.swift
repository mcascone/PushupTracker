import Foundation
#if canImport(HealthKit)
import HealthKit
#endif

public enum Constants {
    public static let secondsPerPushup: TimeInterval = 2.0
    public static let kcalPerPushup: Double = 0.32
    public static let dayIDMetadataKey = "PushupTrackerDayID"

    #if canImport(HealthKit)
    public static let activityType: HKWorkoutActivityType = .functionalStrengthTraining
    #endif
}
