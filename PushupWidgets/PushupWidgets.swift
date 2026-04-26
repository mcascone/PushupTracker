import WidgetKit
import SwiftUI
import AppIntents
import SwiftData
import PushupCore

struct PushupEntry: TimelineEntry {
  let date: Date
  let total: Int
}

struct PushupTotalProvider: TimelineProvider {
  nonisolated func placeholder(in context: Context) -> PushupEntry {
    PushupEntry(date: .now, total: 0)
  }

  nonisolated func getSnapshot(in context: Context, completion: @escaping (PushupEntry) -> Void) {
    completion(PushupEntry(date: .now, total: Self.todayTotal()))
  }

  nonisolated func getTimeline(in context: Context, completion: @escaping (Timeline<PushupEntry>) -> Void) {
    let total = Self.todayTotal()
    let now = Date()
    let calendar = Calendar.current
    let startOfTomorrow = calendar.date(
      byAdding: .day,
      value: 1,
      to: calendar.startOfDay(for: now)
    ) ?? now.addingTimeInterval(86_400)

    var entries: [PushupEntry] = []
    var t = now
    while t < startOfTomorrow {
      entries.append(PushupEntry(date: t, total: total))
      t = t.addingTimeInterval(15 * 60)
    }
    entries.append(PushupEntry(date: startOfTomorrow, total: 0))
    completion(Timeline(entries: entries, policy: .atEnd))
  }

  nonisolated private static func todayTotal() -> Int {
    guard let container = try? SharedContainer.makeModelContainer() else { return 0 }
    let context = ModelContext(container)
    let calendar = Calendar.current
    let start = calendar.startOfDay(for: .now)
    guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return 0 }
    let descriptor = FetchDescriptor<PushupSet>(
      predicate: #Predicate { $0.timestamp >= start && $0.timestamp < end }
    )
    let sets = (try? context.fetch(descriptor)) ?? []
    return sets.reduce(0) { $0 + $1.count }
  }
}

private struct QuickAddButton: View {
  let count: Int

  var body: some View {
    Button(intent: LogPushupsIntent(count: count)) {
      Text("+\(count)")
        .font(.subheadline.bold())
        .frame(maxWidth: .infinity)
    }
    .buttonStyle(.borderedProminent)
    .tint(.accentColor)
  }
}

private struct TotalLabel: View {
  let total: Int
  var size: CGFloat = 48

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text("\(total)")
        .font(.system(size: size, weight: .bold, design: .rounded))
        .minimumScaleFactor(0.5)
        .lineLimit(1)
      Text("pushups today")
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
  }
}

struct PushupSmallWidgetView: View {
  let entry: PushupEntry

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      TotalLabel(total: entry.total, size: 44)
      Spacer(minLength: 0)
      QuickAddButton(count: 10)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

struct PushupMediumWidgetView: View {
  let entry: PushupEntry

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      TotalLabel(total: entry.total, size: 56)
        .frame(maxWidth: .infinity, alignment: .leading)
      VStack(spacing: 6) {
        HStack(spacing: 6) {
          QuickAddButton(count: 1)
          QuickAddButton(count: 5)
        }
        HStack(spacing: 6) {
          QuickAddButton(count: 10)
          QuickAddButton(count: 25)
        }
      }
      .frame(maxWidth: 180)
    }
  }
}

struct PushupWidgetEntryView: View {
  @Environment(\.widgetFamily) private var family
  let entry: PushupEntry

  var body: some View {
    switch family {
    case .systemMedium:
      PushupMediumWidgetView(entry: entry)
    default:
      PushupSmallWidgetView(entry: entry)
    }
  }
}

struct PushupWidgets: Widget {
  let kind: String = "PushupWidgets"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: PushupTotalProvider()) { entry in
      PushupWidgetEntryView(entry: entry)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    .configurationDisplayName("Pushup Tracker")
    .description("Today's pushup total with quick-add buttons.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

#Preview(as: .systemSmall) {
  PushupWidgets()
} timeline: {
  PushupEntry(date: .now, total: 0)
  PushupEntry(date: .now, total: 42)
}

#Preview(as: .systemMedium) {
  PushupWidgets()
} timeline: {
  PushupEntry(date: .now, total: 85)
}
