// Created by Banghua Zhao on 12/04/2026
// Copyright Apps Bay Limited. All rights reserved.

import Foundation
import Observation

@Observable
@MainActor
final class AppState {
    static let shared = AppState()

    var unitSystem: UnitSystem {
        didSet {
            UserDefaults.standard.set(unitSystem.rawValue, forKey: AppState.unitSystemKey)
        }
    }

    private static let unitSystemKey = "bodylog_unitSystem"

    private init() {
        let saved = UserDefaults.standard.string(forKey: AppState.unitSystemKey) ?? ""
        unitSystem = UnitSystem(rawValue: saved) ?? .metric
    }
}
