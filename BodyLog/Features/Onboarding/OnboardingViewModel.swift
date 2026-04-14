// Created by Banghua Zhao on 14/04/2026
// Copyright Apps Bay Limited. All rights reserved.

import Foundation
import Observation
import SQLiteData

@Observable
@MainActor
final class OnboardingViewModel {
    @ObservationIgnored
    @FetchAll(Metric.order { $0.sortOrder })
    var metrics: [Metric]

    @ObservationIgnored
    @Dependency(\.defaultDatabase) private var database

    var selectedUnitSystem: UnitSystem
    var weightStartText: String = ""
    var weightGoalText: String = ""
    var heightStartText: String = ""
    var heightGoalText: String = ""
    var isSaving: Bool = false
    var errorMessage: String?

    private var hasLoadedInitialValues = false

    init() {
        selectedUnitSystem = AppState.shared.unitSystem
    }

    var unitSuffixes: (weight: String, height: String) {
        switch selectedUnitSystem {
        case .metric: return ("kg", "cm")
        case .imperial: return ("lbs", "in")
        }
    }

    var canFinish: Bool {
        parse(weightStartText) != nil &&
        parse(weightGoalText) != nil &&
        parse(heightStartText) != nil &&
        parse(heightGoalText) != nil &&
        !isSaving
    }

    func loadInitialValuesIfNeeded() {
        guard !hasLoadedInitialValues else { return }
        hasLoadedInitialValues = true

        guard let weight = metrics.first(where: { $0.kind == .weight }),
              let height = metrics.first(where: { $0.kind == .height }) else {
            return
        }

        if let start = weight.startValue {
            weightStartText = format(weight.displayValue(start, unitSystem: selectedUnitSystem))
        }
        if let goal = weight.goalValue {
            weightGoalText = format(weight.displayValue(goal, unitSystem: selectedUnitSystem))
        }
        if let start = height.startValue {
            heightStartText = format(height.displayValue(start, unitSystem: selectedUnitSystem))
        }
        if let goal = height.goalValue {
            heightGoalText = format(height.displayValue(goal, unitSystem: selectedUnitSystem))
        }
    }

    func saveOnboardingData() async -> Bool {
        guard let weightStart = parse(weightStartText),
              let weightGoal = parse(weightGoalText),
              let heightStart = parse(heightStartText),
              let heightGoal = parse(heightGoalText) else {
            errorMessage = "Please enter valid numbers for all fields."
            return false
        }

        isSaving = true
        defer { isSaving = false }

        do {
            let unitSystem = selectedUnitSystem
            let weightMetric = metrics.first(where: { $0.kind == .weight })
            let heightMetric = metrics.first(where: { $0.kind == .height })
            let baseOrder = (metrics.map(\.sortOrder).max() ?? -1) + 1
            let weightOrder = baseOrder
            let heightOrder = baseOrder + (weightMetric == nil ? 1 : 0)

            try await database.write { db in
                if let weightMetric {
                    let rawStart = weightMetric.rawValue(from: weightStart, unitSystem: unitSystem)
                    let rawGoal = weightMetric.rawValue(from: weightGoal, unitSystem: unitSystem)
                    try Metric.find(weightMetric.id).update {
                        $0.startValue = #bind(rawStart)
                        $0.goalValue = #bind(rawGoal)
                    }.execute(db)
                } else {
                    let rawStart = unitSystem == .imperial ? (weightStart / 2.20462) : weightStart
                    let rawGoal = unitSystem == .imperial ? (weightGoal / 2.20462) : weightGoal
                    try Metric.insert {
                        Metric.Draft(
                            name: "Weight",
                            symbol: "kg",
                            kind: .weight,
                            sortOrder: weightOrder,
                            startValue: rawStart,
                            goalValue: rawGoal
                        )
                    }.execute(db)
                }

                if let heightMetric {
                    let rawStart = heightMetric.rawValue(from: heightStart, unitSystem: unitSystem)
                    let rawGoal = heightMetric.rawValue(from: heightGoal, unitSystem: unitSystem)
                    try Metric.find(heightMetric.id).update {
                        $0.startValue = #bind(rawStart)
                        $0.goalValue = #bind(rawGoal)
                    }.execute(db)
                } else {
                    let rawStart = unitSystem == .imperial ? (heightStart / 0.393701) : heightStart
                    let rawGoal = unitSystem == .imperial ? (heightGoal / 0.393701) : heightGoal
                    try Metric.insert {
                        Metric.Draft(
                            name: "Height",
                            symbol: "cm",
                            kind: .height,
                            sortOrder: heightOrder,
                            startValue: rawStart,
                            goalValue: rawGoal
                        )
                    }.execute(db)
                }
            }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func parse(_ value: String) -> Double? {
        let normalized = value.replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }

    private func format(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(1)))
    }
}
