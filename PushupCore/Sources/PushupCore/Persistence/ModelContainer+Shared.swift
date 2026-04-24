import Foundation
import SwiftData

public enum SharedContainer {
    public static let appGroupID = "group.com.mcmusicworkshop.pushuptracker"
    public static let storeFilename = "PushupTracker.sqlite"

    public static func makeModelContainer() throws -> ModelContainer {
        guard let groupURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
        else {
            fatalError("App Group container unavailable — check entitlements on both targets")
        }
        let storeURL = groupURL.appending(path: storeFilename)
        let schema = Schema([PushupSet.self])
        let config = ModelConfiguration(schema: schema, url: storeURL)
        return try ModelContainer(for: schema, configurations: [config])
    }
}
