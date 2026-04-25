import SwiftUI
import SwiftData
import PushupCore

@main
struct PushupTrackerApp: App {
  let sharedModelContainer: ModelContainer

  init() {
    do {
      sharedModelContainer = try SharedContainer.makeModelContainer()
    } catch {
      fatalError("Could not create shared ModelContainer: \(error)")
    }
  }

  var body: some Scene {
    WindowGroup {
      AppShell()
    }
    .modelContainer(sharedModelContainer)
  }
}
