import Foundation
import SwiftData
import os
import PushupCore

@MainActor
final class HealthSyncController {
  private let service: any HealthKitService
  private let container: ModelContainer
  private var debounceTask: Task<Void, Never>?
  private var didRequestAuthorization = false
  private let logger = Logger(subsystem: "app", category: "HealthSyncController")

  init(container: ModelContainer, service: any HealthKitService) {
    self.container = container
    self.service = service
  }

  func appBecameActive() {
    debounceTask?.cancel()
    debounceTask = Task { [weak self] in
      try? await Task.sleep(for: .seconds(1))
      guard !Task.isCancelled else { return }
      await self?.requestAuthorizationIfNeeded()
      await self?.syncToday()
    }
  }

  private func requestAuthorizationIfNeeded() async {
    guard !didRequestAuthorization else { return }
    didRequestAuthorization = true
    do {
      _ = try await service.requestAuthorization()
    } catch {
      logger.error("Authorization request failed: \(error.localizedDescription, privacy: .public)")
    }
  }

  private func syncToday() async {
    let context = ModelContext(container)
    let calendar = Calendar.current
    let today = Date()
    let startOfDay = calendar.startOfDay(for: today)
    guard let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }
    let descriptor = FetchDescriptor<PushupSet>(
      predicate: #Predicate { $0.timestamp >= startOfDay && $0.timestamp < startOfTomorrow }
    )
    let sets: [PushupSet]
    do {
      sets = try context.fetch(descriptor)
    } catch {
      logger.error("Fetch failed: \(error.localizedDescription, privacy: .public)")
      return
    }
    let plan = WorkoutSynthesizer.plan(for: sets, on: today, calendar: calendar)
    let dayID = WorkoutSynthesizer.dayID(for: today, calendar: calendar)
    do {
      try await service.sync(dayID: dayID, plan: plan)
    } catch {
      logger.error("Sync failed for \(dayID, privacy: .public): \(error.localizedDescription, privacy: .public)")
      return
    }
    let now = Date()
    for set in sets {
      set.healthKitSyncedAt = now
    }
    do {
      try context.save()
    } catch {
      logger.error("Saving sync stamp failed: \(error.localizedDescription, privacy: .public)")
    }
  }
}
