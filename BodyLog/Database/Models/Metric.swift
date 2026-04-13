// Created by Banghua Zhao on 12/04/2026
// Copyright Apps Bay Limited. All rights reserved.

import Foundation
import SQLiteData
import SwiftUI

// MARK: - BodyMetricKind

enum BodyMetricKind: Int, QueryBindable, Codable, Sendable {
    case weight        = 0   // kg  ↔ lbs   (×2.20462)
    case height        = 1   // cm  ↔ in    (×0.393701)
    case custom        = 2   // no conversion
    case circumference = 3   // cm  ↔ in    (×0.393701)
    case gramOunce     = 4   // g   ↔ oz    (×0.035274)
    case meterFoot     = 5   // m   ↔ ft    (×3.28084)
    case millimeterInch = 6  // mm  ↔ in    (×0.0393701)
}

extension BodyMetricKind {
    /// Infers the most appropriate kind from a user-typed unit symbol.
    /// Returns `.custom` for any unrecognised symbol.
    static func infer(from symbol: String) -> BodyMetricKind {
        switch symbol.trimmingCharacters(in: .whitespaces).lowercased() {
        case "kg", "lb", "lbs": return .weight
        case "cm", "in":        return .circumference
        case "g", "oz":         return .gramOunce
        case "m", "ft":         return .meterFoot
        case "mm":              return .millimeterInch
        default:                return .custom
        }
    }
}

// MARK: - Metric

@Table
nonisolated struct Metric: Identifiable, Hashable, Sendable {
    let id: Int
    var name: String = ""
    var symbol: String = ""
    var kind: BodyMetricKind = .custom
    var sortOrder: Int = 0
    var startValue: Double?
    var goalValue: Double?
    var colorHex: String?
}

// MARK: - Display & Conversion

extension Metric {
    func displaySymbol(unitSystem: UnitSystem) -> String {
        switch kind {
        case .weight:           return unitSystem == .imperial ? "lbs" : "kg"
        case .height,
             .circumference:   return unitSystem == .imperial ? "in"  : "cm"
        case .gramOunce:        return unitSystem == .imperial ? "oz"  : "g"
        case .meterFoot:        return unitSystem == .imperial ? "ft"  : "m"
        case .millimeterInch:   return unitSystem == .imperial ? "in"  : "mm"
        case .custom:           return symbol
        }
    }

    func displayValue(_ rawValue: Double, unitSystem: UnitSystem) -> Double {
        guard unitSystem == .imperial else { return rawValue }
        switch kind {
        case .weight:           return rawValue * 2.20462
        case .height,
             .circumference:   return rawValue * 0.393701
        case .gramOunce:        return rawValue * 0.035274
        case .meterFoot:        return rawValue * 3.28084
        case .millimeterInch:   return rawValue * 0.0393701
        case .custom:           return rawValue
        }
    }

    func rawValue(from displayValue: Double, unitSystem: UnitSystem) -> Double {
        guard unitSystem == .imperial else { return displayValue }
        switch kind {
        case .weight:           return displayValue / 2.20462
        case .height,
             .circumference:   return displayValue / 0.393701
        case .gramOunce:        return displayValue / 0.035274
        case .meterFoot:        return displayValue / 3.28084
        case .millimeterInch:   return displayValue / 0.0393701
        case .custom:           return displayValue
        }
    }

    /// 0.0 → 1.0 progress toward goal, or nil if start/goal are not set.
    func progress(currentValue: Double) -> Double? {
        guard let start = startValue, let goal = goalValue, start != goal else { return nil }
        return max(0, min(1, (currentValue - start) / (goal - start)))
    }
}

// MARK: - Appearance

extension Metric {
    /// The user-chosen color if set, otherwise the automatic default.
    var accentColor: Color {
        if let hex = colorHex, let color = Color(hex: hex) { return color }
        return defaultAccentColor
    }

    /// Automatic color derived from kind and sort order.
    var defaultAccentColor: Color {
        switch kind {
        case .weight:                       return .blue
        case .height:                       return .green
        case .meterFoot:                    return .green.opacity(0.8)
        case .gramOunce:                    return .blue.opacity(0.7)
        case .custom, .circumference,
             .millimeterInch:
            let palette: [Color] = [.purple, .orange, .teal, .pink, .indigo, .mint, .cyan]
            return palette[Swift.abs(sortOrder) % palette.count]
        }
    }

    var iconName: String {
        switch kind {
        case .weight, .gramOunce:           return "scalemass.fill"
        case .height, .meterFoot:           return "figure.stand"
        case .circumference,
             .millimeterInch:              return "ruler.fill"
        case .custom:                       return "chart.xyaxis.line"
        }
    }
}
