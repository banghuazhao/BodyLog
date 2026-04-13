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
                // Metric chip picker
                if !viewModel.metrics.isEmpty {
                    @Bindable var vm = viewModel
                    MetricChipPicker(metrics: viewModel.metrics, selectedId: $vm.selectedMetricId)
                    Divider()
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
                        VStack(spacing: 16) {
                            timeRangePicker
                            chartCard
                            statsCard
                        }
                        .padding(16)
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

    // MARK: - Time range picker

    private var timeRangePicker: some View {
        @Bindable var vm = viewModel
        return HStack(spacing: 6) {
            ForEach(TimeRange.allCases) { range in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.selectedTimeRange = range
                    }
                } label: {
                    Text(range.rawValue)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            viewModel.selectedTimeRange == range
                                ? (viewModel.selectedMetric?.accentColor ?? .blue)
                                : Color.secondary.opacity(0.1),
                            in: Capsule()
                        )
                        .foregroundStyle(
                            viewModel.selectedTimeRange == range ? .white : .secondary
                        )
                }
                .buttonStyle(.plain)
            }
            Spacer()

            if let count = viewModel.filteredChartDataPoints.count as Int?, count > 0 {
                Text("\(count) entries")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Chart card

    private var chartCard: some View {
        let color = viewModel.selectedMetric?.accentColor ?? .blue
        let points = viewModel.filteredChartDataPoints
        let minY = viewModel.minValue
        let maxY = viewModel.maxValue
        let padding = max((maxY - minY) * 0.1, 0.5)

        return VStack(alignment: .leading, spacing: 12) {
            if let metric = viewModel.selectedMetric {
                Label(metric.name, systemImage: metric.iconName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(color)
            }

            Chart(points) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.displayValue)
                )
                .foregroundStyle(color)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2.5))

                AreaMark(
                    x: .value("Date", point.date),
                    yStart: .value("Min", minY - padding),
                    yEnd: .value("Value", point.displayValue)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [color.opacity(0.25), color.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

                if points.count <= 15 {
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Value", point.displayValue)
                    )
                    .foregroundStyle(color)
                    .symbolSize(25)
                }
            }
            .chartYAxisLabel(viewModel.yAxisLabel)
            .chartYScale(domain: (minY - padding)...(maxY + padding))
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisGridLine().foregroundStyle(.secondary.opacity(0.2))
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        .foregroundStyle(.secondary)
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine().foregroundStyle(.secondary.opacity(0.15))
                    AxisValueLabel()
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 220)
        }
        .padding(16)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(color.opacity(0.1), lineWidth: 1)
        }
        .shadow(color: color.opacity(0.07), radius: 10, y: 4)
    }

    // MARK: - Stats card

    @ViewBuilder
    private var statsCard: some View {
        let points = viewModel.filteredChartDataPoints
        if !points.isEmpty {
            let color = viewModel.selectedMetric?.accentColor ?? .blue
            let unit = viewModel.yAxisLabel
            let first = points.first!.displayValue
            let last = points.last!.displayValue
            let change = last - first
            let minVal = points.map(\.displayValue).min()!
            let maxVal = points.map(\.displayValue).max()!
            let avg = points.map(\.displayValue).reduce(0, +) / Double(points.count)

            VStack(alignment: .leading, spacing: 12) {
                Text("Statistics")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 10
                ) {
                    StatTile(title: "First", value: first, unit: unit, color: color)
                    StatTile(title: "Latest", value: last, unit: unit, color: color)
                    StatTile(title: "Change", value: change, unit: unit, color: color, showSign: true)
                    StatTile(title: "Average", value: avg, unit: unit, color: color)
                    StatTile(title: "Min", value: minVal, unit: unit, color: color)
                    StatTile(title: "Max", value: maxVal, unit: unit, color: color)
                }
            }
            .padding(16)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(color.opacity(0.1), lineWidth: 1)
            }
            .shadow(color: color.opacity(0.07), radius: 10, y: 4)
        }
    }
}

// MARK: - Stat Tile

private struct StatTile: View {
    let title: String
    let value: Double
    let unit: String
    let color: Color
    var showSign: Bool = false

    private var formatted: String {
        let str = value.formatted(.number.precision(.fractionLength(1)))
        return showSign && value > 0 ? "+\(str)" : str
    }

    private var valueColor: Color {
        guard showSign else { return .primary }
        return value < 0 ? .green : (value > 0 ? .red : .secondary)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Text(formatted)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(showSign ? valueColor : color)
            Text(unit)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(color.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
    }
}
