// Created by Banghua Zhao on 12/04/2026
// Copyright Apps Bay Limited. All rights reserved.

import SwiftUI

// MARK: - Metric Template

struct MetricTemplate: Identifiable {
    let id = UUID()
    let name: String
    let symbol: String
    let iconName: String
    let color: Color

    static let predefined: [MetricTemplate] = [
        MetricTemplate(name: "Body Fat", symbol: "%",  iconName: "percent",       color: .orange),
        MetricTemplate(name: "BMI",      symbol: "",   iconName: "chart.bar.fill", color: .purple),
        MetricTemplate(name: "Waist",    symbol: "cm", iconName: "ruler.fill",     color: .teal),
        MetricTemplate(name: "Hip",      symbol: "cm", iconName: "ruler.fill",     color: .pink),
        MetricTemplate(name: "Chest",    symbol: "cm", iconName: "ruler.fill",     color: .indigo),
        MetricTemplate(name: "Neck",     symbol: "cm", iconName: "ruler.fill",     color: .mint),
        MetricTemplate(name: "Arm",      symbol: "cm", iconName: "ruler.fill",     color: .cyan),
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

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// Kind is always inferred from the symbol — templates just pre-fill the fields.
    private var inferredKind: BodyMetricKind {
        BodyMetricKind.infer(from: symbol)
    }

    /// Shown when the typed symbol is a recognised unit.
    private var conversionHint: String? {
        switch inferredKind {
        case .weight:
            return "Recognised as weight — values will auto-convert between kg and lbs when you switch unit systems."
        case .circumference:
            return "Recognised as length — values will auto-convert between cm and in when you switch unit systems."
        default:
            return nil
        }
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
                                kind: inferredKind
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

    // MARK: Details section

    private var customSection: some View {
        Section {
            HStack(spacing: 10) {
                Image(systemName: selectedTemplate?.iconName ?? "plus.circle")
                    .foregroundStyle(selectedTemplate?.color ?? Color.secondary)
                    .frame(width: 22)
                TextField("Name", text: $name)
            }

            HStack(spacing: 10) {
                Image(systemName: inferredKind == .custom ? "tag.fill" : "arrow.triangle.2.circlepath")
                    .foregroundStyle(inferredKind == .custom ? Color.secondary : Color.blue)
                    .frame(width: 22)
                    .animation(.easeInOut(duration: 0.2), value: inferredKind == .custom)
                TextField("Unit symbol  (e.g. kg, cm, %)", text: $symbol)
            }
        } header: {
            Text("Details")
        } footer: {
            if let hint = conversionHint {
                Label(hint, systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: conversionHint != nil)
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
            Text("Tap a template to pre-fill the name and symbol above.")
        }
    }

    // MARK: Helpers

    private func toggleTemplate(_ template: MetricTemplate) {
        if selectedTemplate?.id == template.id {
            selectedTemplate = nil
            name = ""
            symbol = ""
        } else {
            selectedTemplate = template
            name = template.name
            symbol = template.symbol
        }
    }
}

// MARK: - Template Card

private struct TemplateCard: View {
    let template: MetricTemplate
    let isSelected: Bool
    let onTap: () -> Void

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
                Text(template.symbol.isEmpty ? "—" : template.symbol)
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
