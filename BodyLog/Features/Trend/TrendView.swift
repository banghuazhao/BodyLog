// Created by Banghua Zhao on 12/04/2026
// Copyright Apps Bay Limited. All rights reserved.

import Charts
import SwiftUI

struct TrendView: View {
    @State private var viewModel = TrendViewModel()
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !viewModel.metrics.isEmpty {
                    @Bindable var vm = viewModel
                    Picker("Metric", selection: $vm.selectedMetricId) {
                        ForEach(viewModel.metrics) { metric in
                            Text(metric.name).tag(metric.id as Metric.ID?)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(.bar)
                }

                if viewModel.chartDataPoints.isEmpty {
                    ContentUnavailableView(
                        "No Data",
                        systemImage: "chart.line.uptrend.xyaxis",
                        description: Text("Log some entries to see your trend over time.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            chartCard
                            statsCard
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Trend")
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
        }
    }

    // MARK: - Chart Card

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.selectedMetric?.name ?? "")
                .font(.headline)

            Chart(viewModel.chartDataPoints) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.displayValue)
                )
                .foregroundStyle(.blue)
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Date", point.date),
                    yStart: .value("Min", viewModel.minValue * 0.95),
                    yEnd: .value("Value", point.displayValue)
                )
                .foregroundStyle(.blue.opacity(0.1))
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.displayValue)
                )
                .foregroundStyle(.blue)
                .symbolSize(30)
            }
            .chartYAxisLabel(viewModel.yAxisLabel)
            .chartYScale(domain: (viewModel.minValue * 0.95)...(viewModel.maxValue * 1.05))
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
            .frame(height: 240)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Stats Card

    private var statsCard: some View {
        let points = viewModel.chartDataPoints
        guard !points.isEmpty else { return AnyView(EmptyView()) }

        let unit = viewModel.yAxisLabel
        let first = points.first!.displayValue
        let last = points.last!.displayValue
        let change = last - first
        let minVal = points.map(\.displayValue).min()!
        let maxVal = points.map(\.displayValue).max()!
        let avg = points.map(\.displayValue).reduce(0, +) / Double(points.count)

        return AnyView(
            VStack(alignment: .leading, spacing: 16) {
                Text("Statistics")
                    .font(.headline)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    StatTile(title: "First", value: first, unit: unit)
                    StatTile(title: "Latest", value: last, unit: unit)
                    StatTile(title: "Change", value: change, unit: unit, showSign: true)
                    StatTile(title: "Average", value: avg, unit: unit)
                    StatTile(title: "Minimum", value: minVal, unit: unit)
                    StatTile(title: "Maximum", value: maxVal, unit: unit)
                }
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        )
    }
}

// MARK: - Stat Tile

private struct StatTile: View {
    let title: String
    let value: Double
    let unit: String
    var showSign: Bool = false

    private var valueText: String {
        let formatted = value.formatted(.number.precision(.fractionLength(1)))
        if showSign && value > 0 { return "+\(formatted)" }
        return formatted
    }

    private var valueColor: Color {
        guard showSign else { return .primary }
        return value < 0 ? .green : (value > 0 ? .red : .primary)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(valueText) \(unit)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(valueColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
