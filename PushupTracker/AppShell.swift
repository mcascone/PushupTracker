import SwiftUI
import PushupCore

struct AppShell: View {
  let healthService: any HealthKitService

  var body: some View {
    TabView {
      TodayView()
        .tabItem { Label("Today", systemImage: "figure.strengthtraining.traditional") }

      Text("History")
        .tabItem { Label("History", systemImage: "calendar") }

      Text("Trends")
        .tabItem { Label("Trends", systemImage: "chart.bar.fill") }

      SettingsView(healthService: healthService)
        .tabItem { Label("Settings", systemImage: "gearshape") }
    }
  }
}
