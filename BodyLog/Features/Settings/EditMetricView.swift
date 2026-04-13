// Created by Banghua Zhao on 12/04/2026
// Copyright Apps Bay Limited. All rights reserved.

import SwiftUI

struct EditMetricView: View {
    let metric: Metric
    let viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    @State private var startText: String = ""
    @State private var goalText: String = ""

    private var unit: String { metric.displaySymbol(unitSystem: appState.unitSystem) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(metric.name)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Unit")
                        Spacer()
                        Text(unit)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Metric Info")
                }

                Section {
                    HStack {
                        Text("Start")
                        Spacer()
                        TextField("e.g. 70", text: $startText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text(unit)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Goal")
                        Spacer()
                        TextField("e.g. 65", text: $goalText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text(unit)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Goal Tracking")
                } footer: {
                    Text("Set your starting point and target value to track progress in Overview.")
                }
            }
            .navigationTitle("Edit \(metric.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let raw = metric.startValue {
                    let display = metric.displayValue(raw, unitSystem: appState.unitSystem)
                    startText = display.formatted(.number.precision(.fractionLength(1)))
                }
                if let raw = metric.goalValue {
                    let display = metric.displayValue(raw, unitSystem: appState.unitSystem)
                    goalText = display.formatted(.number.precision(.fractionLength(1)))
                }
            }
        }
    }

    private func save() {
        let startDisplay = Double(startText)
        let goalDisplay = Double(goalText)
        let startRaw = startDisplay.map { metric.rawValue(from: $0, unitSystem: appState.unitSystem) }
        let goalRaw = goalDisplay.map { metric.rawValue(from: $0, unitSystem: appState.unitSystem) }
        Task {
            await viewModel.updateGoals(for: metric, startValue: startRaw, goalValue: goalRaw)
        }
    }
}
