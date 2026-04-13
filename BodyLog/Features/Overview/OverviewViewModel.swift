// Created by Banghua Zhao on 12/04/2026
// Copyright Apps Bay Limited. All rights reserved.

import Foundation
import Observation
import SQLiteData

@Observable
@MainActor
final class OverviewViewModel {
    @ObservationIgnored
    @FetchAll(Metric.order { $0.sortOrder })
    var metrics: [Metric]

    @ObservationIgnored
    @FetchAll(LogEntry.order { $0.date.desc() })
    var allEntries: [LogEntry]

    @ObservationIgnored
    @Dependency(\.defaultDatabase) private var database

    var errorMessage: String?

    // MARK: - Computed helpers

    func latestEntry(for metric: Metric) -> LogEntry? {
        allEntries.first { $0.metricId == metric.id }
    }

    func currentDisplayValue(for metric: Metric) -> Double? {
        guard let entry = latestEntry(for: metric) else { return nil }
        return metric.displayValue(entry.value, unitSystem: AppState.shared.unitSystem)
    }

    func startDisplayValue(for metric: Metric) -> Double? {
        guard let raw = metric.startValue else { return nil }
        return metric.displayValue(raw, unitSystem: AppState.shared.unitSystem)
    }

    func goalDisplayValue(for metric: Metric) -> Double? {
        guard let raw = metric.goalValue else { return nil }
        return metric.displayValue(raw, unitSystem: AppState.shared.unitSystem)
    }

    /// Returns progress 0…1 towards goal, or nil if no goal/start is set.
    func progress(for metric: Metric) -> Double? {
        guard let current = latestEntry(for: metric)?.value else { return nil }
        return metric.progress(currentValue: current)
    }

    // MARK: - Quick log

    func quickAddEntry(value: Double, date: Date, for metric: Metric) async {
        do {
            let raw = metric.rawValue(from: value, unitSystem: AppState.shared.unitSystem)
            try await database.write { db in
                try LogEntry.insert {
                    LogEntry.Draft(metricId: metric.id, date: date, value: raw)
                }.execute(db)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
