// Created by Banghua Zhao on 12/04/2026
// Copyright Apps Bay Limited. All rights reserved.

import Foundation

enum UnitSystem: String, CaseIterable, Identifiable, Codable {
    case metric
    case imperial

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .metric:   return "Metric"
        case .imperial: return "Imperial"
        }
    }

    /// All recognised metric ↔ imperial unit pairs for this app.
    static let conversionPairs: [(metric: String, imperial: String)] = [
        ("kg",  "lbs"),
        ("g",   "oz"),
        ("m",   "ft"),
        ("cm",  "in"),
        ("mm",  "in"),
    ]

    /// Units used when this system is active.
    var activeUnits: [String] {
        switch self {
        case .metric:   return Self.conversionPairs.map(\.metric)
        case .imperial: return Self.conversionPairs.map(\.imperial)
        }
    }
}
