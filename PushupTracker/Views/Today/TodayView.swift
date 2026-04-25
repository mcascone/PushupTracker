import SwiftUI
import SwiftData
import PushupCore

struct TodayView: View {
  @Environment(\.modelContext) private var modelContext
  @Query(
    filter: TodayView.todayPredicate(),
    sort: \PushupSet.timestamp,
    order: .reverse
  )
  private var todaySets: [PushupSet]

  private static let quickAddCounts = [1, 5, 10, 25]

  var body: some View {
    VStack(spacing: 24) {
      heroSection
      quickAddButtons
      Spacer()
    }
    .padding()
  }

  private var heroSection: some View {
    VStack(spacing: 4) {
      Text("\(todayTotal)")
        .font(.system(size: 120, weight: .semibold, design: .rounded))
        .monospacedDigit()
        .contentTransition(.numericText())
      Text("\(todaySets.count) \(todaySets.count == 1 ? "set" : "sets") today")
        .font(.headline)
        .foregroundStyle(.secondary)
    }
  }

  private var quickAddButtons: some View {
    HStack(spacing: 12) {
      ForEach(Self.quickAddCounts, id: \.self) { count in
        Button { add(count) } label: {
          Text("+\(count)")
            .font(.title2.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: 56)
        }
        .buttonStyle(.borderedProminent)
      }
    }
  }

  private var todayTotal: Int {
    todaySets.reduce(0) { $0 + $1.count }
  }

  private func add(_ count: Int) {
    let set = PushupSet(count: count)
    modelContext.insert(set)
    try? modelContext.save()
  }

  private static func todayPredicate() -> Predicate<PushupSet> {
    let calendar = Calendar.current
    let start = calendar.startOfDay(for: .now)
    let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
    return #Predicate<PushupSet> { $0.timestamp >= start && $0.timestamp < end }
  }
}
