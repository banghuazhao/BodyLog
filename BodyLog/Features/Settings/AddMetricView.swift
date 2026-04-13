// Created by Banghua Zhao on 12/04/2026
// Copyright Apps Bay Limited. All rights reserved.

import SwiftUI

// MARK: - Metric Template

struct MetricTemplate: Identifiable {
    let id = UUID()
    let name: String
    let kind: BodyMetricKind
    let iconName: String
    let color: Color
    /// Symbol to use in metric mode; circumference kind shows "cm"/"in" automatically.
    let customSymbol: String

    /// Returns the symbol to display given the current unit system.
    func symbol(for unitSystem: UnitSystem) -> String {
        switch kind {
        case .circumference:
            return unitSystem == .imperial ? "in" : "cm"
        default:
            return customSymbol
        }
    }

    static let predefined: [MetricTemplate] = [
        MetricTemplate(
            name: "Body Fat", kind: .custom,
            iconName: "percent", color: .orange,
            customSymbol: "%"
        ),
        MetricTemplate(
            name: "BMI", kind: .custom,
            iconName: "chart.bar.fill", color: .purple,
            customSymbol: ""
        ),
        MetricTemplate(
            name: "Waist", kind: .circumference,
            iconName: "ruler.fill", color: .teal,
            customSymbol: "cm"
        ),
        MetricTemplate(
            name: "Hip", kind: .circumference,
            iconName: "ruler.fill", color: .pink,
            customSymbol: "cm"
        ),
        MetricTemplate(
            name: "Chest", kind: .circumference,
            iconName: "ruler.fill", color: .indigo,
            customSymbol: "cm"
        ),
        MetricTemplate(
            name: "Neck", kind: .circumference,
            iconName: "ruler.fill", color: .mint,
            customSymbol: "cm"
        ),
        MetricTemplate(
            name: "Arm", kind: .circumference,
            iconName: "ruler.fill", color: .cyan,
            customSymbol: "cm"
        ),
    ]
}

// MARK: - Add Metric View

struct AddMetricView: View {
    let viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    @State private var selectedTemplate: MetricTemplate?
    @State private var name: String = ""
    @State private var symbol: String = ""
    @State private var selectedKind: BodyMetricKind = .custom

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                customSection
                templateSection
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
                            await viewModel.addMetric(
                                name: name,
                                symbol: symbol,
                                kind: selectedKind
                            )
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
        }
        .presentationDetents([.large])
        .presentationCornerRadius(24)
    }

    // MARK: Template section

    private var templateSection: some View {
        Section {
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 10
            ) {
                ForEach(MetricTemplate.predefined) { template in
                    TemplateCard(
                        template: template,
                        unitSystem: appState.unitSystem,
                        isSelected: selectedTemplate?.id == template.id
                    ) {
                        toggleTemplate(template)
                    }
                }
            }
            .listRowInsets(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
            .listRowBackground(Color.clear)
        } header: {
            Text("Quick Pick")
        } footer: {
            Text("Tap a template to pre-fill the fields above, or enter a custom metric manually.")
        }
    }

    // MARK: Custom entry section

    private var customSection: some View {
        Section("Details") {
            HStack(spacing: 10) {
                Image(systemName: templateIcon)
                    .foregroundStyle(templateColor)
                    .frame(width: 22)
                TextField("Name", text: $name)
            }

            HStack(spacing: 10) {
                Image(systemName: "tag.fill")
                    .foregroundStyle(.secondary)
                    .frame(width: 22)
                TextField("Unit symbol  (e.g. %, bpm)", text: $symbol)
            }
        }
    }

    // MARK: Helpers

    private var templateIcon: String {
        selectedTemplate?.iconName ?? "plus.circle"
    }

    private var templateColor: Color {
        selectedTemplate?.color ?? .secondary
    }

    private func toggleTemplate(_ template: MetricTemplate) {
        if selectedTemplate?.id == template.id {
            selectedTemplate = nil
            name = ""
            symbol = ""
            selectedKind = .custom
        } else {
            selectedTemplate = template
            name = template.name
            symbol = template.symbol(for: appState.unitSystem)
            selectedKind = template.kind
        }
    }
}

// MARK: - Template Card

private struct TemplateCard: View {
    let template: MetricTemplate
    let unitSystem: UnitSystem
    let isSelected: Bool
    let onTap: () -> Void

    private var unit: String { template.symbol(for: unitSystem) }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Image(systemName: template.iconName)
                        .font(.headline)
                        .foregroundStyle(isSelected ? .white : template.color)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.white)
                    }
                }
                Text(template.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isSelected ? .white : .primary)
                Text(unit.isEmpty ? "—" : unit)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isSelected ? .white.opacity(0.85) : .secondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isSelected ? template.color : template.color.opacity(0.08),
                in: RoundedRectangle(cornerRadius: 14)
            )
            .overlay {
                if !isSelected {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(template.color.opacity(0.2), lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}
