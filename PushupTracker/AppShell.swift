import SwiftUI

struct AppShell: View {
  var body: some View {
    TabView {
      TodayView()
        .tabItem { Label("Today", systemImage: "figure.strengthtraining.traditional") }

      Text("History")
        .tabItem { Label("History", systemImage: "calendar") }

      Text("Trends")
        .tabItem { Label("Trends", systemImage: "chart.bar.fill") }

      Text("Settings")
        .tabItem { Label("Settings", systemImage: "gearshape") }
    }
  }
}
