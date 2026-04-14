// Created by Banghua Zhao on 12/04/2026
// Copyright Apps Bay Limited. All rights reserved.

import Foundation
import Observation
import SQLiteData

struct LogEntryRow: Identifiable {
    let entry: LogEntry
    let displayValue: Double
    let change: Double?

    var id: Int { entry.id }
}

@Observable
@MainActor
final class LogsViewModel {
    @ObservationIgnored
    @FetchAll(Metric.order { $0.sortOrder })
    var metrics: [Metric]

    @ObservationIgnored
    @FetchAll
    var entries: [LogEntry]

    @ObservationIgnored
    @Dependency(\.defaultDatabase) private var database

    var selectedMetricId: Metric.ID?
    var errorMessage: String?

    var selectedMetric: Metric? {
        metrics.first { $0.id == selectedMetricId }
    }

    var unitSystem: UnitSystem { AppState.shared.unitSystem }

    var logRows: [LogEntryRow] {
        guard let metric = selectedMetric else { return [] }
        return entries.enumerated().map { index, entry in
            let displayValue = metric.displayValue(entry.value, unitSystem: unitSystem)
            let change: Double?
            if index < entries.count - 1 {
                let older = entries[index + 1]
                let olderDisplay = metric.displayValue(older.value, unitSystem: unitSystem)
                change = displayValue - olderDisplay
            } else {
                change = nil
            }
            return LogEntryRow(entry: entry, displayValue: displayValue, change: change)
        }
    }

    // MARK: - Actions

    func selectInitialMetricIfNeeded() {
        if selectedMetricId == nil, let first = metrics.first {
            selectedMetricId = first.id
        }
    }

    func loadEntries(for metricId: Metric.ID) async {
        do {
            try await $entries.load(
                LogEntry
                    .where { $0.metricId.eq(metricId) }
                    .order { $0.date.desc() }
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addEntry(value: Double, date: Date) async {
        guard let metric = selectedMetric else { return }
        do {
            let raw = metric.rawValue(from: value, unitSystem: unitSystem)
            try await database.write { db in
                try LogEntry.insert {
                    LogEntry.Draft(metricId: metric.id, date: date, value: raw)
                }.execute(db)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateEntry(_ entry: LogEntry, value: Double, date: Date) async {
        guard let metric = selectedMetric else { return }
        do {
            let raw = metric.rawValue(from: value, unitSystem: unitSystem)
            try await database.write { db in
                try LogEntry.find(entry.id).update {
                    $0.value = raw
                    $0.date = date
                }.execute(db)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteEntries(at offsets: IndexSet) async {
        do {
            let ids = offsets.map { logRows[$0].entry.id }
            try await database.write { db in
                try LogEntry
                    .where { $0.id.in(ids) }
                    .delete()
                    .execute(db)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
