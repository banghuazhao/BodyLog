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
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
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
        VStack(alignment: .leading, spacing: 0) {
            topSection
            if let s = start, let g = goal, let prog = progress {
                Divider().padding(.horizontal, 16)
                progressSection(progress: prog, start: s, goal: g)
            } else {
                noGoalHint
            }
        }
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(metric.accentColor.opacity(0.15), lineWidth: 1)
        }
        .shadow(color: metric.accentColor.opacity(0.08), radius: 10, y: 4)
        .sheet(isPresented: $showingQuickLog) {
            QuickLogSheet(metric: metric, value: $quickLogValue) { value in
                Task { await viewModel.quickAddEntry(value: value, for: metric) }
            }
            .presentationDetents([.height(280)])
            .presentationCornerRadius(24)
        }
    }

    // MARK: Top section: icon+name, big value, ring

    private var topSection: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Label(metric.name, systemImage: metric.iconName)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(metric.accentColor)

                if let current {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(current.formatted(.number.precision(.fractionLength(1))))
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .contentTransition(.numericText(value: current))
                            .animation(.spring(response: 0.4), value: current)
                        Text(unit)
                            .font(.title3.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("—")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                        Text(unit)
                            .font(.title3.weight(.medium))
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 10) {
                Button {
                    quickLogValue = current.map {
                        $0.formatted(.number.precision(.fractionLength(1)))
                    } ?? ""
                    showingQuickLog = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(metric.accentColor)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
    }

    // MARK: Progress bar section

    private func progressSection(progress: Double, start: Double, goal: Double) -> some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(metric.accentColor.opacity(0.12))
                        .frame(height: 6)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [metric.accentColor.opacity(0.6), metric.accentColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(6, geo.size.width * progress), height: 6)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                }
            }
            .frame(height: 6)

            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Start")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(start.formatted(.number.precision(.fractionLength(1)))) \(unit)")
                        .font(.caption.weight(.semibold))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text("Goal")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(goal.formatted(.number.precision(.fractionLength(1)))) \(unit)")
                        .font(.caption.weight(.semibold))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: No-goal hint

    private var noGoalHint: some View {
        Label("Set start & goal in Settings", systemImage: "target")
            .font(.caption)
            .foregroundStyle(.tertiary)
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
    }
}

// MARK: - Quick Log Sheet

private struct QuickLogSheet: View {
    let metric: Metric
    @Binding var value: String
    let onSave: (Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    private var unit: String { metric.displaySymbol(unitSystem: appState.unitSystem) }
    private var isValid: Bool { Double(value) != nil }

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            Capsule()
                .fill(.secondary.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 12)

            // Title
            Label(metric.name, systemImage: metric.iconName)
                .font(.headline)
                .foregroundStyle(metric.accentColor)
                .padding(.top, 20)

            // Value input
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                TextField("0.0", text: $value)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(isValid ? .primary : .secondary)
                    .frame(maxWidth: .infinity)
                Text(unit)
                    .font(.title2.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)

            // Save button
            Button {
                if let v = Double(value) { onSave(v) }
                dismiss()
            } label: {
                Text("Save Entry")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        isValid ? metric.accentColor : Color.secondary.opacity(0.3),
                        in: RoundedRectangle(cornerRadius: 16)
                    )
            }
            .disabled(!isValid)
            .padding(.horizontal, 24)

            Spacer()
        }
    }
}
