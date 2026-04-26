import SwiftUI
import PushupCore

struct DayDetailView: View {
  let dayStart: Date
  let sets: [PushupSet]

  var body: some View {
    List {
      Section {
        HStack {
          Text("Total")
          Spacer()
          Text("\(total) \(total == 1 ? "pushup" : "pushups")")
            .foregroundStyle(.secondary)
            .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Total: \(total) \(total == 1 ? "pushup" : "pushups")")
        HStack {
          Text("Sets")
          Spacer()
          Text("\(sets.count)")
            .foregroundStyle(.secondary)
            .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(sets.count) \(sets.count == 1 ? "set" : "sets")")
      }

      Section("Timeline") {
        ForEach(sets) { set in
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
      }
    }
    .navigationTitle(dayStart.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
    .navigationBarTitleDisplayMode(.inline)
  }

  private var total: Int { sets.reduce(0) { $0 + $1.count } }
}
