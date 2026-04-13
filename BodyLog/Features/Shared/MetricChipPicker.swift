// Created by Banghua Zhao on 12/04/2026
// Copyright Apps Bay Limited. All rights reserved.

import SwiftUI

/// A horizontally-scrolling chip picker for selecting a metric.
/// Scales gracefully to any number of metrics.
struct MetricChipPicker: View {
    let metrics: [Metric]
    @Binding var selectedId: Metric.ID?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(metrics) { metric in
                    ChipButton(
                        title: metric.name,
                        isSelected: selectedId == metric.id,
                        color: metric.accentColor
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedId = metric.id
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }
}

private struct ChipButton: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected ? color : color.opacity(0.1),
                    in: Capsule()
                )
                .foregroundStyle(isSelected ? .white : color)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}
