import Foundation
import SwiftData
import os
import PushupCore

enum HealthSyncOutcome: Equatable {
  case success(Date)
  case failure(String)
}

@MainActor
@Observable
final class HealthSyncController {
  @ObservationIgnored private let service: any HealthKitService
  @ObservationIgnored private let container: ModelContainer
  @ObservationIgnored private var debounceTask: Task<Void, Never>?
  @ObservationIgnored private var didRequestAuthorization = false
  @ObservationIgnored private let logger = Logger(subsystem: "app", category: "HealthSyncController")
  private(set) var lastSyncOutcome: HealthSyncOutcome?

  init(container: ModelContainer, service: any HealthKitService) {
    self.container = container
    self.service = service
  }

  func appBecameActive() {
    debounceTask?.cancel()
    debounceTask = Task { [weak self] in
      try? await Task.sleep(for: .seconds(1))
      guard !Task.isCancelled, let self else { return }
      await self.requestAuthorizationIfNeeded()
      guard await self.service.authorizationStatus() != .denied else { return }
      await self.syncDay(Date())
    }
  }

  func syncNow() async {
    await requestAuthorizationIfNeeded()
    if await service.authorizationStatus() == .denied {
      lastSyncOutcome = .failure("Apple Health access is denied. Open Health settings to grant permission.")
      return
    }
    let calendar = Calendar.current
    let today = Date()
    await syncDay(today)
    if let yesterday = calendar.date(byAdding: .day, value: -1, to: today) {
      await syncDay(yesterday)
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

  private func syncDay(_ day: Date) async {
    let context = ModelContext(container)
    let calendar = Calendar.current
    let startOfDay = calendar.startOfDay(for: day)
    guard let startOfNextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }
    let descriptor = FetchDescriptor<PushupSet>(
      predicate: #Predicate { $0.timestamp >= startOfDay && $0.timestamp < startOfNextDay }
    )
    let sets: [PushupSet]
    do {
      sets = try context.fetch(descriptor)
    } catch {
      logger.error("Fetch failed: \(error.localizedDescription, privacy: .public)")
      lastSyncOutcome = .failure(error.localizedDescription)
      return
    }
    let plan = WorkoutSynthesizer.plan(for: sets, on: day, calendar: calendar)
    let dayID = WorkoutSynthesizer.dayID(for: day, calendar: calendar)
    do {
      try await service.sync(dayID: dayID, plan: plan)
    } catch {
      logger.error("Sync failed for \(dayID, privacy: .public): \(error.localizedDescription, privacy: .public)")
      lastSyncOutcome = .failure(error.localizedDescription)
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
      lastSyncOutcome = .failure(error.localizedDescription)
      return
    }
    lastSyncOutcome = .success(now)
  }
}
