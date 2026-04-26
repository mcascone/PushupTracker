import SwiftUI
import SwiftData
import Charts
import PushupCore

struct TrendsView: View {
  @Query(sort: \PushupSet.timestamp, order: .forward)
  private var allSets: [PushupSet]

  @State private var window: Window = .week

  var body: some View {
    NavigationStack {
      Form {
        Section {
          Picker("Window", selection: $window) {
            ForEach(Window.allCases) { w in
              Text(w.label)
                .tag(w)
                .accessibilityLabel(w.accessibilityLabel)
            }
          }
          .pickerStyle(.segmented)
          .accessibilityLabel("Time window")
        }

        Section {
          Chart(dailyTotals, id: \.dayStart) { entry in
            BarMark(
              x: .value("Day", entry.dayStart, unit: .day),
              y: .value("Pushups", entry.total)
            )
          }
          .chartYAxis {
            AxisMarks(position: .leading)
          }
          .frame(height: 220)
          .accessibilityLabel("Daily pushup totals over the last \(window.days) days")
          .accessibilityValue(chartAccessibilityValue)
        }

        Section("Summary") {
          LabeledContent("Total", value: "\(summary.total)")
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Total pushups in window")
            .accessibilityValue("\(summary.total)")
          LabeledContent("Average / day", value: summary.averageText)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Average pushups per day")
            .accessibilityValue(summary.averageText)
          LabeledContent("Best day", value: summary.bestDayText)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Best day")
            .accessibilityValue(summary.bestDayText)
        }
      }
      .navigationTitle("Trends")
    }
  }

  private var dailyTotals: [DailyTotal] {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: .now)
    guard let windowStart = calendar.date(byAdding: .day, value: -(window.days - 1), to: today) else {
      return []
    }

    var totals: [Date: Int] = [:]
    for set in allSets {
      let day = calendar.startOfDay(for: set.timestamp)
      guard day >= windowStart && day <= today else { continue }
      totals[day, default: 0] += set.count
    }

    return (0..<window.days).compactMap { offset in
      guard let day = calendar.date(byAdding: .day, value: offset, to: windowStart) else { return nil }
      return DailyTotal(dayStart: day, total: totals[day] ?? 0)
    }
  }

  private var summary: Summary {
    let totals = dailyTotals
    let total = totals.reduce(0) { $0 + $1.total }
    let average = totals.isEmpty ? 0.0 : Double(total) / Double(totals.count)
    let best = totals.max { $0.total < $1.total }

    let averageText = total == 0 ? "—" : String(format: "%.1f", average)
    let bestDayText: String
    if let best, best.total > 0 {
      bestDayText = "\(Self.bestDayFormat.format(best.dayStart)) · \(best.total)"
    } else {
      bestDayText = "—"
    }
    return Summary(total: total, averageText: averageText, bestDayText: bestDayText)
  }

  private static let bestDayFormat = Date.FormatStyle.dateTime.month(.abbreviated).day()

  private var chartAccessibilityValue: String {
    let totals = dailyTotals
    let sum = totals.reduce(0) { $0 + $1.total }
    if sum == 0 {
      return "No pushups logged in the last \(window.days) days"
    }
    let average = Double(sum) / Double(totals.count)
    return "Total \(sum), average \(String(format: "%.1f", average)) per day"
  }
}

private struct DailyTotal {
  let dayStart: Date
  let total: Int
}

private struct Summary {
  let total: Int
  let averageText: String
  let bestDayText: String
}

private enum Window: Int, CaseIterable, Identifiable {
  case week = 7
  case month = 30
  case quarter = 90

  var id: Int { rawValue }
  var days: Int { rawValue }
  var label: String {
    switch self {
    case .week: "7"
    case .month: "30"
    case .quarter: "90"
    }
  }
  var accessibilityLabel: String {
    switch self {
    case .week: "7 days"
    case .month: "30 days"
    case .quarter: "90 days"
    }
  }
}

private extension Date.FormatStyle {
  func format(_ date: Date) -> String {
    date.formatted(self)
  }
}
