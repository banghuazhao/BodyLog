// Created by Banghua Zhao on 12/04/2026
// Copyright Apps Bay Limited. All rights reserved.

import Foundation
import SQLiteData
import SwiftUI

enum BodyMetricKind: Int, QueryBindable, Codable, Sendable {
    case weight = 0
    case height = 1
    case custom = 2
}

@Table
nonisolated struct Metric: Identifiable, Hashable, Sendable {
    let id: Int
    var name: String = ""
    var symbol: String = ""
    var kind: BodyMetricKind = .custom
    var sortOrder: Int = 0
    var startValue: Double?
    var goalValue: Double?
}

extension Metric {
    func displaySymbol(unitSystem: UnitSystem) -> String {
        switch kind {
        case .weight: return unitSystem == .imperial ? "lbs" : "kg"
        case .height: return unitSystem == .imperial ? "in" : "cm"
        case .custom: return symbol
        }
    }

    func displayValue(_ rawValue: Double, unitSystem: UnitSystem) -> Double {
        switch kind {
        case .weight:
            return unitSystem == .imperial ? rawValue * 2.20462 : rawValue
        case .height:
            return unitSystem == .imperial ? rawValue * 0.393701 : rawValue
        case .custom:
            return rawValue
        }
    }

    func rawValue(from displayValue: Double, unitSystem: UnitSystem) -> Double {
        switch kind {
        case .weight:
            return unitSystem == .imperial ? displayValue / 2.20462 : displayValue
        case .height:
            return unitSystem == .imperial ? displayValue / 0.393701 : displayValue
        case .custom:
            return displayValue
        }
    }

    /// 0.0 → 1.0 progress toward the goal, or nil if start/goal/latest are not set.
    func progress(currentValue: Double) -> Double? {
        guard let start = startValue, let goal = goalValue, start != goal else { return nil }
        let p = (currentValue - start) / (goal - start)
        return max(0, min(1, p))
    }

    var accentColor: Color {
        switch kind {
        case .weight: return .blue
        case .height: return .green
        case .custom:
            let palette: [Color] = [.purple, .orange, .teal, .pink, .indigo, .mint, .cyan]
            return palette[sortOrder % palette.count]
        }
    }

    var iconName: String {
        switch kind {
        case .weight: return "scalemass.fill"
        case .height: return "figure.stand"
        case .custom: return "chart.xyaxis.line"
        }
    }
}
