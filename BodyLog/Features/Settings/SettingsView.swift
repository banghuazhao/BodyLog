// Created by Banghua Zhao on 12/04/2026
// Copyright Apps Bay Limited. All rights reserved.

import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @Environment(AppState.self) private var appState
    @State private var showingAddMetric = false
    @State private var editingMetric: Metric?

    var body: some View {
        NavigationStack {
            Form {
                unitSection
                metricsSection
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Metric", systemImage: "plus") {
                        showingAddMetric = true
                    }
                }
            }
            .sheet(isPresented: $showingAddMetric) {
                AddMetricView(viewModel: viewModel)
            }
            .sheet(item: $editingMetric) { metric in
                EditMetricView(metric: metric, viewModel: viewModel)
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    // MARK: - Sections

    private var unitSection: some View {
        Section {
            @Bindable var state = appState
            Picker("Unit System", selection: $state.unitSystem) {
                ForEach(UnitSystem.allCases) { system in
                    Text(system.displayName).tag(system)
                }
            }
            .pickerStyle(.navigationLink)
        } header: {
            Text("Units")
        } footer: {
            Text("Changing units converts how values are displayed. Built-in metrics (Weight, Height) will convert automatically.")
        }
    }

    private var metricsSection: some View {
        Section {
            ForEach(viewModel.metrics) { metric in
                MetricSettingsRow(metric: metric, appState: appState) {
                    editingMetric = metric
                }
            }
            .onDelete { offsets in
                Task { await viewModel.deleteMetrics(at: offsets) }
            }
        } header: {
            Text("Metrics")
        } footer: {
            Text("Tap a metric to set start and goal values. Built-in metrics cannot be deleted.")
        }
    }
}

// MARK: - Metric Settings Row

private struct MetricSettingsRow: View {
    let metric: Metric
    let appState: AppState
    let onTap: () -> Void

    private var unit: String { metric.displaySymbol(unitSystem: appState.unitSystem) }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Color swatch
                Circle()
                    .fill(metric.accentColor)
                    .frame(width: 26, height: 26)
                    .overlay(Circle().strokeBorder(.quaternary, lineWidth: 0.5))

                VStack(alignment: .leading, spacing: 2) {
                    Text(metric.name)
                        .font(.body)
                        .foregroundStyle(.primary)

                    let startStr = metric.startValue.map {
                        metric.displayValue($0, unitSystem: appState.unitSystem)
                            .formatted(.number.precision(.fractionLength(1)))
                    } ?? "—"
                    let goalStr = metric.goalValue.map {
                        metric.displayValue($0, unitSystem: appState.unitSystem)
                            .formatted(.number.precision(.fractionLength(1)))
                    } ?? "—"

                    Text("Start: \(startStr) \(unit)  •  Goal: \(goalStr) \(unit)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Add Metric View

struct AddMetricView: View {
    let viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var symbol: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Metric Details") {
                    TextField("Name (e.g. Body Fat)", text: $name)
                    TextField("Unit symbol (e.g. kg, cm, %)", text: $symbol)
                }
            }
            .navigationTitle("Add Metric")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            await viewModel.addMetric(name: name, symbol: symbol)
                        }
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
