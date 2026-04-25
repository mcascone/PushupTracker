import SwiftUI
import SwiftData
import PushupCore

@main
struct PushupTrackerApp: App {
  let sharedModelContainer: ModelContainer
  let healthService: any HealthKitService
  @State private var syncController: HealthSyncController
  @Environment(\.scenePhase) private var scenePhase

  init() {
    let container: ModelContainer
    do {
      container = try SharedContainer.makeModelContainer()
    } catch {
      fatalError("Could not create shared ModelContainer: \(error)")
    }
    sharedModelContainer = container
    let service = HealthKitServiceLive()
    healthService = service
    _syncController = State(
      initialValue: HealthSyncController(
        container: container,
        service: service
      )
    )
  }

  var body: some Scene {
    WindowGroup {
      AppShell(healthService: healthService, onSyncNow: { await syncController.syncNow() })
        .onChange(of: scenePhase) { _, newPhase in
          if newPhase == .active {
            syncController.appBecameActive()
          }
        }
    }
    .modelContainer(sharedModelContainer)
  }
}
