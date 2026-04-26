import AppIntents
import WidgetKit
import PushupCore

struct LogPushupsIntent: AppIntent {
  static let title: LocalizedStringResource = "Log Pushups"
  static let description = IntentDescription("Adds a set of pushups to today's log.")

  @Parameter(title: "Count")
  var count: Int

  init() {
    self.count = 10
  }

  init(count: Int) {
    self.count = count
  }

  @MainActor
  func perform() async throws -> some IntentResult {
    let container = try SharedContainer.makeModelContainer()
    let store = PushupStore(container: container)
    try store.insert(count: count)
    WidgetCenter.shared.reloadAllTimelines()
    return .result()
  }
}
