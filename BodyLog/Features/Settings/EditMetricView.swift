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
    @State private var useCustomColor: Bool = false
    @State private var selectedColor: Color = .blue

    private var unit: String { metric.displaySymbol(unitSystem: appState.unitSystem) }

    var body: some View {
        NavigationStack {
            Form {
                infoSection
                goalSection
                colorSection
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
            .onAppear { initializeState() }
        }
    }

    // MARK: - Sections

    private var infoSection: some View {
        Section("Metric Info") {
            LabeledContent("Name", value: metric.name)
            LabeledContent("Unit", value: unit)
        }
    }

    private var goalSection: some View {
        Section {
            HStack {
                Text("Start")
                Spacer()
                TextField("e.g. 70", text: $startText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
                Text(unit).foregroundStyle(.secondary)
            }
            HStack {
                Text("Goal")
                Spacer()
                TextField("e.g. 65", text: $goalText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
                Text(unit).foregroundStyle(.secondary)
            }
        } header: {
            Text("Goal Tracking")
        } footer: {
            Text("Set your starting point and target value to track progress in Overview.")
        }
    }

    private var colorSection: some View {
        Section {
            Toggle(isOn: $useCustomColor.animation()) {
                HStack(spacing: 10) {
                    Circle()
                        .fill(useCustomColor ? selectedColor : metric.defaultAccentColor)
                        .frame(width: 22, height: 22)
                        .overlay(Circle().strokeBorder(.quaternary, lineWidth: 0.5))
                    Text("Custom Color")
                }
            }

            if useCustomColor {
                ColorPicker("Color", selection: $selectedColor, supportsOpacity: false)

                Button {
                    useCustomColor = false
                    selectedColor = metric.defaultAccentColor
                } label: {
                    Label("Reset to Default", systemImage: "arrow.uturn.backward")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Appearance")
        } footer: {
            Text(useCustomColor
                 ? "This color is used for cards, chips, and charts."
                 : "Using the automatic color for this metric type.")
        }
    }

    // MARK: - Helpers

    private func initializeState() {
        if let raw = metric.startValue {
            startText = metric.displayValue(raw, unitSystem: appState.unitSystem)
                .formatted(.number.precision(.fractionLength(1)))
        }
        if let raw = metric.goalValue {
            goalText = metric.displayValue(raw, unitSystem: appState.unitSystem)
                .formatted(.number.precision(.fractionLength(1)))
        }
        if let hex = metric.colorHex, let color = Color(hex: hex) {
            useCustomColor = true
            selectedColor = color
        } else {
            useCustomColor = false
            selectedColor = metric.defaultAccentColor
        }
    }

    private func save() {
        let startDisplay = Double(startText)
        let goalDisplay = Double(goalText)
        let startRaw = startDisplay.map { metric.rawValue(from: $0, unitSystem: appState.unitSystem) }
        let goalRaw = goalDisplay.map { metric.rawValue(from: $0, unitSystem: appState.unitSystem) }
        let hexToSave = useCustomColor ? selectedColor.hexString : nil

        Task {
            await viewModel.updateGoals(for: metric, startValue: startRaw, goalValue: goalRaw)
            await viewModel.updateColor(for: metric, colorHex: hexToSave)
        }
    }
}
