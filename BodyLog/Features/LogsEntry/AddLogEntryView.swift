// Created by Banghua Zhao on 12/04/2026
// Copyright Apps Bay Limited. All rights reserved.

import SwiftUI

struct AddLogEntryView: View {
    let viewModel: LogsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var value: String = ""
    @State private var date: Date = Date()

    private var metric: Metric? { viewModel.selectedMetric }
    private var unit: String { metric?.displaySymbol(unitSystem: viewModel.unitSystem) ?? "" }
    private var color: Color { metric?.accentColor ?? .blue }
    private var isValid: Bool { Double(value) != nil }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Metric label
                    if let metric {
                        Label(metric.name, systemImage: metric.iconName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(color)
                            .padding(.top, 8)
                    }

                    // Value input card
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

                    // Date input card
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
            .navigationTitle("Add Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let v = Double(value) {
                            Task { await viewModel.addEntry(value: v, date: date) }
                        }
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
