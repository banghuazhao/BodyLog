// Created by Banghua Zhao on 12/04/2026
// Copyright Apps Bay Limited. All rights reserved.

import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @Environment(AppState.self) private var appState
    @Environment(\.openURL) private var openURL
    @State private var showingAddMetric = false
    @State private var editingMetric: Metric?
    @State private var mailUnavailableMessage: String?

    private let appStoreAppID = "6745432102"
    private var appStoreURL: URL? { URL(string: "https://itunes.apple.com/app/id\(appStoreAppID)") }
    private var reviewURL: URL? { URL(string: "https://itunes.apple.com/app/id\(appStoreAppID)?action=write-review") }
    private let feedbackEmail = "support@appsbay.co"

    var body: some View {
        NavigationStack {
            Form {
                unitSection
                metricsSection
                othersSection
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Metric") {
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
            .alert("Mail", isPresented: Binding(
                get: { mailUnavailableMessage != nil },
                set: { if !$0 { mailUnavailableMessage = nil } }
            )) {
                Button("OK", role: .cancel) { mailUnavailableMessage = nil }
            } message: {
                Text(mailUnavailableMessage ?? "")
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

    private var othersSection: some View {
        Section("Others") {
            NavigationLink(destination: MoreAppsView()) {
                Label("More Apps", systemImage: "storefront")
                    .foregroundStyle(.blue)
            }

            if let reviewURL {
                Button {
                    openURL(reviewURL)
                } label: {
                    Label("Rate Us", systemImage: "star.fill")
                }
            }

            Button {
                openFeedbackMail()
            } label: {
                Label("Feedback", systemImage: "envelope.fill")
            }

            if let appStoreURL {
                ShareLink(item: appStoreURL) {
                    Label("Share App", systemImage: "square.and.arrow.up")
                }
            }
        }
    }

    private func openFeedbackMail() {
        guard var components = URLComponents(string: "mailto:\(feedbackEmail)") else {
            mailUnavailableMessage = "Invalid feedback email address."
            return
        }
        components.queryItems = [
            URLQueryItem(name: "subject", value: "BodyLog Feedback"),
            URLQueryItem(name: "body", value: "Hi BodyLog team,\n\n")
        ]
        guard let mailURL = components.url else {
            mailUnavailableMessage = "Could not build the mail link."
            return
        }
        openURL(mailURL) { accepted in
            Task { @MainActor in
                if !accepted {
                    mailUnavailableMessage = "Could not open Mail. On Simulator, open the Mail app and sign in, or try on a device with Mail configured."
                }
            }
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

