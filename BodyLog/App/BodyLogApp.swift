// Created by Banghua Zhao on 12/04/2026
// Copyright Apps Bay Limited. All rights reserved.

import SQLiteData
import SwiftUI

@main
struct BodyLogApp: App {
    init() {
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
