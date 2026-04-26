import WidgetKit
import SwiftUI
import AppIntents
import SwiftData
import PushupCore

struct PushupEntry: TimelineEntry {
  let date: Date
  let total: Int
  let gaugeMax: Int
}

struct PushupTotalProvider: TimelineProvider {
  nonisolated func placeholder(in context: Context) -> PushupEntry {
    PushupEntry(date: .now, total: 0, gaugeMax: 100)
  }

  nonisolated func getSnapshot(in context: Context, completion: @escaping (PushupEntry) -> Void) {
    let snapshot = Self.snapshot()
    completion(PushupEntry(date: .now, total: snapshot.total, gaugeMax: snapshot.gaugeMax))
  }

  nonisolated func getTimeline(in context: Context, completion: @escaping (Timeline<PushupEntry>) -> Void) {
    let snapshot = Self.snapshot()
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
      entries.append(PushupEntry(date: t, total: snapshot.total, gaugeMax: snapshot.gaugeMax))
      t = t.addingTimeInterval(15 * 60)
    }
    entries.append(PushupEntry(date: startOfTomorrow, total: 0, gaugeMax: snapshot.gaugeMax))
    completion(Timeline(entries: entries, policy: .atEnd))
  }

  nonisolated private static func snapshot() -> (total: Int, gaugeMax: Int) {
    guard let container = try? SharedContainer.makeModelContainer() else {
      return (0, 100)
    }
    let context = ModelContext(container)
    let calendar = Calendar.current
    let startOfToday = calendar.startOfDay(for: .now)
    guard let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday),
          let windowStart = calendar.date(byAdding: .day, value: -29, to: startOfToday) else {
      return (0, 100)
    }
    let descriptor = FetchDescriptor<PushupSet>(
      predicate: #Predicate { $0.timestamp >= windowStart && $0.timestamp < endOfToday }
    )
    let sets = (try? context.fetch(descriptor)) ?? []

    var totalsByDay: [Date: Int] = [:]
    for set in sets {
      let day = calendar.startOfDay(for: set.timestamp)
      totalsByDay[day, default: 0] += set.count
    }
    let total = totalsByDay[startOfToday] ?? 0
    let gaugeMax: Int
    if totalsByDay.count < 7 {
      gaugeMax = 100
    } else {
      gaugeMax = max(totalsByDay.values.max() ?? 100, 1)
    }
    return (total, gaugeMax)
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
    .accessibilityLabel("Log \(count) pushup\(count == 1 ? "" : "s")")
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
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(total) pushup\(total == 1 ? "" : "s") today")
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

struct PushupCircularWidgetView: View {
  let entry: PushupEntry

  var body: some View {
    Gauge(value: Double(min(entry.total, entry.gaugeMax)), in: 0...Double(entry.gaugeMax)) {
      Text("Pushups")
    } currentValueLabel: {
      Text("\(entry.total)")
    }
    .gaugeStyle(.accessoryCircular)
    .accessibilityLabel("Pushups today")
    .accessibilityValue("\(entry.total) of \(entry.gaugeMax)")
  }
}

struct PushupRectangularWidgetView: View {
  let entry: PushupEntry

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text("\(entry.total) pushups")
        .font(.headline)
        .accessibilityLabel("\(entry.total) pushup\(entry.total == 1 ? "" : "s") today")
      Button(intent: LogPushupsIntent(count: 10)) {
        Text("+10")
          .font(.caption.bold())
      }
      .buttonStyle(.bordered)
      .accessibilityLabel("Log 10 pushups")
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

struct PushupWidgetEntryView: View {
  @Environment(\.widgetFamily) private var family
  let entry: PushupEntry

  var body: some View {
    switch family {
    case .systemMedium:
      PushupMediumWidgetView(entry: entry)
    case .accessoryCircular:
      PushupCircularWidgetView(entry: entry)
    case .accessoryRectangular:
      PushupRectangularWidgetView(entry: entry)
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
    .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
  }
}

#Preview(as: .systemSmall) {
  PushupWidgets()
} timeline: {
  PushupEntry(date: .now, total: 0, gaugeMax: 100)
  PushupEntry(date: .now, total: 42, gaugeMax: 100)
}

#Preview(as: .systemMedium) {
  PushupWidgets()
} timeline: {
  PushupEntry(date: .now, total: 85, gaugeMax: 100)
}

#Preview(as: .accessoryCircular) {
  PushupWidgets()
} timeline: {
  PushupEntry(date: .now, total: 42, gaugeMax: 100)
}

#Preview(as: .accessoryRectangular) {
  PushupWidgets()
} timeline: {
  PushupEntry(date: .now, total: 42, gaugeMax: 100)
}
