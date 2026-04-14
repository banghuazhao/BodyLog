// Created by Banghua Zhao on 12/04/2026
// Copyright Apps Bay Limited. All rights reserved.

import SwiftUI

struct LogsView: View {
    @State private var viewModel = LogsViewModel()
    @State private var showingAddEntry = false
    @State private var editingRow: LogEntryRow?
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !viewModel.metrics.isEmpty {
                    @Bindable var vm = viewModel
                    MetricChipPicker(metrics: viewModel.metrics, selectedId: $vm.selectedMetricId)
                    Divider()
                }

                logList
            }
            .navigationTitle("Logs")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddEntry = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title3)
                    }
                    .backgroundStyle(viewModel.selectedMetric?.accentColor ?? .blue)
                    .disabled(viewModel.selectedMetricId == nil)
                }
            }
            .sheet(isPresented: $showingAddEntry) {
                AddLogEntryView(viewModel: viewModel)
            }
            .sheet(item: $editingRow) { row in
                EditLogEntryView(entry: row.entry, viewModel: viewModel)
            }
            .onAppear {
                viewModel.selectInitialMetricIfNeeded()
            }
            .onChange(of: viewModel.metrics) { _, _ in
                viewModel.selectInitialMetricIfNeeded()
            }
            .task(id: viewModel.selectedMetricId) {
                if let id = viewModel.selectedMetricId {
                    await viewModel.loadEntries(for: id)
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    // MARK: - Log list

    @ViewBuilder
    private var logList: some View {
        if viewModel.logRows.isEmpty {
            ContentUnavailableView(
                "No Entries",
                systemImage: "list.bullet.rectangle",
                description: Text(
                    viewModel.selectedMetricId == nil
                        ? "Select a metric to view entries."
                        : "Tap + to log your first entry."
                )
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            let unit = viewModel.selectedMetric?.displaySymbol(unitSystem: appState.unitSystem) ?? ""
            let color = viewModel.selectedMetric?.accentColor ?? .blue
            List {
                ForEach(viewModel.logRows) { row in
                    Button {
                        editingRow = row
                    } label: {
                        LogEntryRowView(row: row, unit: unit, color: color)
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button {
                            editingRow = row
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(color)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            Task {
                                if let index = viewModel.logRows.firstIndex(where: { $0.id == row.id }) {
                                    await viewModel.deleteEntries(at: IndexSet(integer: index))
                                }
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
    }
}

// MARK: - Log Entry Row

struct LogEntryRowView: View {
    let row: LogEntryRow
    let unit: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            // Date block
            VStack(alignment: .center, spacing: 2) {
                Text(row.entry.date.formatted(.dateTime.month(.abbreviated)))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Text(row.entry.date.formatted(.dateTime.day()))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(color)
            }
            .frame(width: 38)

            Rectangle()
                .fill(color.opacity(0.2))
                .frame(width: 1.5, height: 44)
                .clipShape(Capsule())

            // Value + time
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(row.displayValue.formatted(.number.precision(.fractionLength(1))))
                        .font(.title3.weight(.bold))
                    Text(unit)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                Text(row.entry.date.formatted(.dateTime.hour().minute()))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Change badge
            if let change = row.change {
                ChangeBadgeView(change: change, unit: unit)
            }
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Change Badge

private struct ChangeBadgeView: View {
    let change: Double
    let unit: String

    private var badgeColor: Color {
        change < 0 ? .green : (change > 0 ? .red : .secondary)
    }
    private var arrowName: String {
        change > 0 ? "arrow.up.right" : (change < 0 ? "arrow.down.right" : "minus")
    }

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: arrowName)
                .font(.caption2.weight(.bold))
            Text(abs(change).formatted(.number.precision(.fractionLength(1))))
                .font(.caption.weight(.bold))
        }
        .foregroundStyle(badgeColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(badgeColor.opacity(0.1), in: Capsule())
    }
}
