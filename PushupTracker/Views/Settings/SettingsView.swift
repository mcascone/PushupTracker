import SwiftUI
import PushupCore

struct SettingsView: View {
  let healthService: any HealthKitService
  @Bindable var syncController: HealthSyncController

  @State private var authStatus: HealthKitAuthorizationStatus = .notDetermined
  @State private var isSyncing = false
  @Environment(\.openURL) private var openURL

  private static let lastSyncFormat = Date.FormatStyle.dateTime.month(.abbreviated).day().hour().minute()

  var body: some View {
    NavigationStack {
      Form {
        Section("Health") {
          LabeledContent("Permission", value: statusLabel)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Apple Health permission")
            .accessibilityValue(statusLabel)
          if authStatus == .denied {
            Button("Open Health Settings") {
              if let url = URL(string: "x-apple-health://") {
                openURL(url)
              }
            }
            .accessibilityLabel("Open Health settings")
            .accessibilityHint("Opens the Apple Health app to change permissions")
          }
          Button("Sync now") {
            Task {
              isSyncing = true
              await syncController.syncNow()
              await refreshStatus()
              isSyncing = false
            }
          }
          .disabled(isSyncing)
          .accessibilityLabel(isSyncing ? "Syncing to Apple Health" : "Sync now")
          .accessibilityHint("Writes today's and yesterday's pushup sets to Apple Health")
          if let outcome = syncController.lastSyncOutcome {
            syncStatusRow(outcome)
          }
        }

        Section("About") {
          LabeledContent("Version", value: Self.versionString)
          LabeledContent("Build", value: Self.buildString)
          LabeledContent("Credits", value: "Pushup Tracker")
          if let feedbackURL = Self.feedbackURL {
            Link("Send feedback", destination: feedbackURL)
              .accessibilityLabel("Send feedback")
              .accessibilityHint("Opens your mail app to send feedback to the developer")
          }
        }
      }
      .navigationTitle("Settings")
      .task { await refreshStatus() }
    }
  }

  @ViewBuilder
  private func syncStatusRow(_ outcome: HealthSyncOutcome) -> some View {
    switch outcome {
    case .success(let date):
      let formatted = date.formatted(Self.lastSyncFormat)
      LabeledContent("Last sync", value: formatted)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Last sync succeeded")
        .accessibilityValue(formatted)
    case .failure(let message):
      VStack(alignment: .leading, spacing: 4) {
        Text("Last sync failed")
          .font(.subheadline)
          .foregroundStyle(.red)
        Text(message)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      .accessibilityElement(children: .ignore)
      .accessibilityLabel("Last sync failed")
      .accessibilityValue(message)
    }
  }

  private var statusLabel: String {
    switch authStatus {
    case .granted: "Granted"
    case .denied: "Denied"
    case .notDetermined: "Not Determined"
    }
  }

  private func refreshStatus() async {
    authStatus = await healthService.authorizationStatus()
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
