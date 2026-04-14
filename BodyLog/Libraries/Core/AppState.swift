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
    
    var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: AppState.onboardingCompletedKey)
        }
    }

    private static let unitSystemKey = "bodylog_unitSystem"
    private static let onboardingCompletedKey = "bodylog_onboardingCompleted"

    private init() {
        let saved = UserDefaults.standard.string(forKey: AppState.unitSystemKey) ?? ""
        unitSystem = UnitSystem(rawValue: saved) ?? .metric
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: AppState.onboardingCompletedKey)
    }
}
