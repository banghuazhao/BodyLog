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
            HStack(spacing: 12) {
                ForEach(UnitSystem.allCases) { system in
                    UnitSystemCard(
                        system: system,
                        isSelected: state.unitSystem == system
                    ) {
                        state.unitSystem = system
                    }
                }
            }
            .listRowInsets(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
            .listRowBackground(Color.clear)
        } header: {
            Text("Units")
        } footer: {
            Text("Metrics with recognised units (kg, g, m, cm, mm, lbs, oz, ft, in) auto-convert when you switch. Custom symbols are unaffected.")
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
            Text("Tap a metric to set start and goal values.")
        }
    }
}

// MARK: - Unit System Card

private struct UnitSystemCard: View {
    let system: UnitSystem
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                // Header
                HStack(spacing: 6) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.subheadline)
                        .foregroundStyle(isSelected ? .white : .secondary)
                    Text(system.displayName)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(isSelected ? .white : .primary)
                }

                Text(system.activeUnits.joined(separator: ","))
                    .font(.caption.weight(.semibold))
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isSelected ? Color.blue : Color.secondary.opacity(0.07),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .overlay {
                if !isSelected {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
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

