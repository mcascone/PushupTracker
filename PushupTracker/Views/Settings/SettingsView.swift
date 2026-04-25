import SwiftUI

struct SettingsView: View {
  var body: some View {
    NavigationStack {
      Form {
        Section("Health") {
          Text("HealthKit status will appear here.")
            .foregroundStyle(.secondary)
        }

        Section("About") {
          LabeledContent("Version", value: Self.versionString)
          LabeledContent("Build", value: Self.buildString)
          LabeledContent("Credits", value: "Pushup Tracker")
          if let feedbackURL = Self.feedbackURL {
            Link("Send feedback", destination: feedbackURL)
          }
        }
      }
      .navigationTitle("Settings")
    }
  }

  private static var versionString: String {
    Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
  }

  private static var buildString: String {
    Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
  }

  private static var feedbackURL: URL? {
    URL(string: "mailto:feedback@example.com?subject=Pushup%20Tracker%20feedback")
  }
}

#Preview {
  SettingsView()
}
