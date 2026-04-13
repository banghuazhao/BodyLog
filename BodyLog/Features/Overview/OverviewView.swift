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

    private var unit: String { metric.displaySymbol(unitSystem: appState.unitSystem) }
    private var current: Double? { viewModel.currentDisplayValue(for: metric) }
    private var start: Double? { viewModel.startDisplayValue(for: metric) }
    private var goal: Double? { viewModel.goalDisplayValue(for: metric) }
    private var progress: Double? { viewModel.progress(for: metric) }

    private var initialValueString: String {
        current.map { $0.formatted(.number.precision(.fractionLength(1))) } ?? ""
    }

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
            QuickLogSheet(metric: metric, initialValue: initialValueString) { value, date in
                Task { await viewModel.quickAddEntry(value: value, date: date, for: metric) }
            }
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
    let initialValue: String
    let onSave: (Double, Date) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    @State private var value: String
    @State private var date: Date = Date()

    init(metric: Metric, initialValue: String, onSave: @escaping (Double, Date) -> Void) {
        self.metric = metric
        self.initialValue = initialValue
        self.onSave = onSave
        _value = State(initialValue: initialValue)
    }

    private var unit: String { metric.displaySymbol(unitSystem: appState.unitSystem) }
    private var color: Color { metric.accentColor }
    private var isValid: Bool { Double(value) != nil }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    Label(metric.name, systemImage: metric.iconName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(color)
                        .padding(.top, 8)

                    // Value card
                    VStack(spacing: 6) {
                        Text("Value")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            TextField("0.0", text: $value)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(isValid ? .primary : .secondary)
                            Text(unit)
                                .font(.title2.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(color.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
                    }

                    // Date card
                    VStack(spacing: 6) {
                        Text("Date & Time")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        DatePicker(
                            "Date",
                            selection: $date,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(color.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
            }
            .navigationTitle("Log \(metric.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let v = Double(value) { onSave(v, date) }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(isValid ? color : .secondary)
                    .disabled(!isValid)
                }
            }
            .tint(color)
        }
        .presentationDetents([.medium])
        .presentationCornerRadius(24)
    }
}
