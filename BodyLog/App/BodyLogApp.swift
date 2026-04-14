// Created by Banghua Zhao on 12/04/2026
// Copyright Apps Bay Limited. All rights reserved.

import SQLiteData
import SwiftUI
import GoogleMobileAds

@main
struct BodyLogApp: App {
    init() {
        MobileAds.shared.start(completionHandler: nil)
        prepareDependencies {
            $0.defaultDatabase = try! makeAppDatabase()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(AppState.shared)
        }
    }
}
