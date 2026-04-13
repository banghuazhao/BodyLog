// Created by Banghua Zhao on 12/04/2026
// Copyright Apps Bay Limited. All rights reserved.

import SwiftUI

struct OverviewView: View {
    @State private var viewModel = OverviewViewModel()
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.metrics.isEmpty {
                    ContentUnavailableView(
                        "No Metrics",
                        systemImage: "scalemass.fill",
                        description: Text("Add metrics in Settings to start tracking.")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.metrics) { metric in
                                MetricProgressCard(metric: metric, viewModel: viewModel)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Overview")
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}

// MARK: - Metric Progress Card

private struct MetricProgressCard: View {
    let metric: Metric
    let viewModel: OverviewViewModel

    @Environment(AppState.self) private var appState
    @State private var showingQuickLog = false
    @State private var quickLogValue: String = ""

    private var unit: String { metric.displaySymbol(unitSystem: appState.unitSystem) }
    private var current: Double? { viewModel.currentDisplayValue(for: metric) }
    private var start: Double? { viewModel.startDisplayValue(for: metric) }
    private var goal: Double? { viewModel.goalDisplayValue(for: metric) }
    private var progress: Double? { viewModel.progress(for: metric) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(metric.name)
                        .font(.headline)
                    if let current {
                        Text("\(current.formatted(.number.precision(.fractionLength(1)))) \(unit)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                    } else {
                        Text("No data yet")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button("Log", systemImage: "plus.circle.fill") {
                    quickLogValue = current.map {
                        $0.formatted(.number.precision(.fractionLength(1)))
                    } ?? ""
                    showingQuickLog = true
                }
                .font(.subheadline)
                .labelStyle(.iconOnly)
                .imageScale(.large)
            }

            // Progress bar
            if let start, let goal, let progress {
                VStack(alignment: .leading, spacing: 6) {
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                        .tint(progressTint(progress: progress, start: start, goal: goal))

                    HStack {
                        Text("Start: \(start.formatted(.number.precision(.fractionLength(1)))) \(unit)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("Goal: \(goal.formatted(.number.precision(.fractionLength(1)))) \(unit)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    let pct = Int(progress * 100)
                    Text("\(pct)% toward goal")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else if metric.startValue == nil || metric.goalValue == nil {
                Text("Set start & goal in Settings")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
        .sheet(isPresented: $showingQuickLog) {
            QuickLogSheet(
                metricName: metric.name,
                unit: unit,
                value: $quickLogValue
            ) { value in
                Task {
                    await viewModel.quickAddEntry(value: value, for: metric)
                }
            }
            .presentationDetents([.height(260)])
        }
    }

    private func progressTint(progress: Double, start: Double, goal: Double) -> Color {
        // Moving toward goal = green, stalling/reversing = orange
        if progress >= 0.95 { return .green }
        if progress > 0 { return .blue }
        return .orange
    }
}

// MARK: - Quick Log Sheet

private struct QuickLogSheet: View {
    let metricName: String
    let unit: String
    @Binding var value: String
    let onSave: (Double) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Log \(metricName)") {
                    HStack {
                        TextField("Value", text: $value)
                            .keyboardType(.decimalPad)
                        Text(unit)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Quick Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let doubleValue = Double(value) {
                            onSave(doubleValue)
                        }
                        dismiss()
                    }
                    .disabled(Double(value) == nil)
                }
            }
        }
    }
}
