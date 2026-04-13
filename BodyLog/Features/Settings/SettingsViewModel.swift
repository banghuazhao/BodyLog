// Created by Banghua Zhao on 12/04/2026
// Copyright Apps Bay Limited. All rights reserved.

import Foundation
import Observation
import SQLiteData

@Observable
@MainActor
final class SettingsViewModel {
    @ObservationIgnored
    @FetchAll(Metric.order { $0.sortOrder })
    var metrics: [Metric]

    @ObservationIgnored
    @Dependency(\.defaultDatabase) private var database

    var errorMessage: String?

    // MARK: - Metric Management

    func addMetric(name: String, symbol: String, kind: BodyMetricKind = .custom) async {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        do {
            let nextOrder = (metrics.last?.sortOrder ?? -1) + 1
            try await database.write { db in
                try Metric.insert {
                    Metric.Draft(
                        name: name.trimmingCharacters(in: .whitespaces),
                        symbol: symbol.trimmingCharacters(in: .whitespaces),
                        kind: kind,
                        sortOrder: nextOrder
                    )
                }.execute(db)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteMetric(_ metric: Metric) async {
        do {
            try await database.write { db in
                try Metric.find(metric.id).delete().execute(db)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteMetrics(at offsets: IndexSet) async {
        let toDelete = offsets
            .map { metrics[$0] }
        for metric in toDelete {
            await deleteMetric(metric)
        }
    }

    func updateGoals(for metric: Metric, startValue: Double?, goalValue: Double?) async {
        do {
            try await database.write { db in
                try Metric.find(metric.id).update {
                    $0.startValue = #bind(startValue)
                    $0.goalValue = #bind(goalValue)
                }.execute(db)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateColor(for metric: Metric, colorHex: String?) async {
        do {
            try await database.write { db in
                try Metric.find(metric.id).update {
                    $0.colorHex = #bind(colorHex)
                }.execute(db)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
