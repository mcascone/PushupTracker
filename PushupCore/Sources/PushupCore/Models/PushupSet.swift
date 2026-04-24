import Foundation
import SwiftData

@Model
public final class PushupSet {
    @Attribute(.unique) public var id: UUID
    public var count: Int
    public var timestamp: Date
    public var healthKitSyncedAt: Date?

    public init(count: Int, timestamp: Date = .now) {
        self.id = UUID()
        self.count = count
        self.timestamp = timestamp
        self.healthKitSyncedAt = nil
    }
}
