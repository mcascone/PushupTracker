import SwiftUI
import PushupCore

struct AppShell: View {
  let healthService: any HealthKitService
  @Bindable var syncController: HealthSyncController

  var body: some View {
    TabView {
      TodayView()
        .tabItem { Label("Today", systemImage: "figure.strengthtraining.traditional") }

      HistoryView()
        .tabItem { Label("History", systemImage: "calendar") }

      TrendsView()
        .tabItem { Label("Trends", systemImage: "chart.bar.fill") }

      SettingsView(healthService: healthService, syncController: syncController)
        .tabItem { Label("Settings", systemImage: "gearshape") }
    }
  }
}
