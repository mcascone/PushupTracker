import SwiftUI
import SwiftData
import PushupCore

struct HistoryView: View {
  @Query(sort: \PushupSet.timestamp, order: .reverse)
  private var allSets: [PushupSet]

  var body: some View {
    NavigationStack {
      List {
        ForEach(monthGroups, id: \.id) { month in
          Section(month.title) {
            ForEach(month.days, id: \.dayStart) { day in
              NavigationLink {
                DayDetailView(dayStart: day.dayStart, sets: day.sets)
              } label: {
                HStack {
                  Text(Self.rowDateFormat.format(day.dayStart))
                  Spacer()
                  Text("\(day.total) \(day.total == 1 ? "pushup" : "pushups")")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                }
              }
            }
          }
        }
      }
      .navigationTitle("History")
      .overlay {
        if allSets.isEmpty {
          ContentUnavailableView(
            "No history yet",
            systemImage: "calendar",
            description: Text("Logged days will appear here.")
          )
        }
      }
    }
  }

  private var monthGroups: [MonthGroup] {
    let calendar = Calendar.current
    let byDay = Dictionary(grouping: allSets) { calendar.startOfDay(for: $0.timestamp) }
    let days: [DayGroup] = byDay
      .map { dayStart, sets in
        let sorted = sets.sorted { $0.timestamp < $1.timestamp }
        let total = sorted.reduce(0) { $0 + $1.count }
        return DayGroup(dayStart: dayStart, sets: sorted, total: total)
      }
      .sorted { $0.dayStart > $1.dayStart }

    let byMonth = Dictionary(grouping: days) { day -> Date in
      let comps = calendar.dateComponents([.year, .month], from: day.dayStart)
      return calendar.date(from: comps) ?? day.dayStart
    }
    return byMonth
      .map { monthStart, days in
        MonthGroup(id: monthStart, title: Self.monthHeaderFormat.format(monthStart), days: days)
      }
      .sorted { $0.id > $1.id }
  }

  private static let rowDateFormat = Date.FormatStyle.dateTime.weekday(.wide).month(.abbreviated).day()
  private static let monthHeaderFormat = Date.FormatStyle.dateTime.month(.wide).year()
}

private struct MonthGroup {
  let id: Date
  let title: String
  let days: [DayGroup]
}

private struct DayGroup {
  let dayStart: Date
  let sets: [PushupSet]
  let total: Int
}

private extension Date.FormatStyle {
  func format(_ date: Date) -> String {
    date.formatted(self)
  }
}
