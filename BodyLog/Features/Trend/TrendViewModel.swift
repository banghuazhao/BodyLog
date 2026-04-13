// Created by Banghua Zhao on 12/04/2026
// Copyright Apps Bay Limited. All rights reserved.

import Foundation
import Observation
import SQLiteData

struct ChartDataPoint: Identifiable {
    let id: Int
    let date: Date
    let displayValue: Double
}

@Observable
@MainActor
final class TrendViewModel {
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

    var chartDataPoints: [ChartDataPoint] {
        guard let metric = selectedMetric else { return [] }
        return entries.map { entry in
            ChartDataPoint(
                id: entry.id,
                date: entry.date,
                displayValue: metric.displayValue(entry.value, unitSystem: unitSystem)
            )
        }
    }

    var yAxisLabel: String {
        selectedMetric?.displaySymbol(unitSystem: unitSystem) ?? ""
    }

    var minValue: Double {
        chartDataPoints.map(\.displayValue).min() ?? 0
    }

    var maxValue: Double {
        chartDataPoints.map(\.displayValue).max() ?? 100
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
                    .order { $0.date }  // ascending: oldest first for charting
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
