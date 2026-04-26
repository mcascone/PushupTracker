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
  private static let undoDuration: Duration = .seconds(5)

  @State private var pendingUndoSetID: PersistentIdentifier?
  @State private var pendingUndoCount: Int = 0
  @State private var undoDismissTask: Task<Void, Never>?

  var body: some View {
    VStack(spacing: 24) {
      heroSection
      quickAddButtons
      timelineList
    }
    .padding()
    .safeAreaInset(edge: .bottom) {
      if pendingUndoSetID != nil {
        UndoBanner(
          message: "Logged \(pendingUndoCount) \(pendingUndoCount == 1 ? "pushup" : "pushups")",
          onUndo: undoLastLog
        )
      }
    }
    .animation(.easeInOut(duration: 0.2), value: pendingUndoSetID)
  }

  private var timelineList: some View {
    List {
      ForEach(todaySets) { set in
        HStack {
          Text(set.timestamp, format: .dateTime.hour().minute())
            .monospacedDigit()
            .foregroundStyle(.secondary)
          Text("—")
            .foregroundStyle(.secondary)
          Text("\(set.count) \(set.count == 1 ? "pushup" : "pushups")")
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(set.count) \(set.count == 1 ? "pushup" : "pushups") at \(set.timestamp.formatted(date: .omitted, time: .shortened))")
      }
      .onDelete(perform: deleteSets)
    }
    .listStyle(.plain)
    .overlay {
      if todaySets.isEmpty {
        ContentUnavailableView(
          "No sets yet today",
          systemImage: "figure.strengthtraining.functional",
          description: Text("Tap a quick-add button above to log your first set.")
        )
      }
    }
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
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(todayTotal) \(todayTotal == 1 ? "pushup" : "pushups") today, \(todaySets.count) \(todaySets.count == 1 ? "set" : "sets")")
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
        .accessibilityLabel("Log \(count) \(count == 1 ? "pushup" : "pushups")")
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
    showUndoBanner(for: set.persistentModelID, count: count)
  }

  private func deleteSets(at offsets: IndexSet) {
    for index in offsets {
      let set = todaySets[index]
      if set.persistentModelID == pendingUndoSetID {
        cancelUndoBanner()
      }
      modelContext.delete(set)
    }
    try? modelContext.save()
  }

  private func showUndoBanner(for id: PersistentIdentifier, count: Int) {
    undoDismissTask?.cancel()
    pendingUndoSetID = id
    pendingUndoCount = count
    undoDismissTask = Task {
      try? await Task.sleep(for: Self.undoDuration)
      guard !Task.isCancelled else { return }
      await MainActor.run {
        if pendingUndoSetID == id {
          pendingUndoSetID = nil
        }
      }
    }
  }

  private func cancelUndoBanner() {
    undoDismissTask?.cancel()
    undoDismissTask = nil
    pendingUndoSetID = nil
  }

  private func undoLastLog() {
    guard let id = pendingUndoSetID,
          let set = todaySets.first(where: { $0.persistentModelID == id })
    else {
      cancelUndoBanner()
      return
    }
    modelContext.delete(set)
    try? modelContext.save()
    cancelUndoBanner()
  }

  private static func todayPredicate() -> Predicate<PushupSet> {
    let calendar = Calendar.current
    let start = calendar.startOfDay(for: .now)
    let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
    return #Predicate<PushupSet> { $0.timestamp >= start && $0.timestamp < end }
  }
}
