// Created by Banghua Zhao on 12/04/2026
// Copyright Apps Bay Limited. All rights reserved.

import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        TabView {
            Tab("Overview", systemImage: "chart.pie.fill") {
                OverviewView()
            }
            Tab("Logs", systemImage: "list.bullet.rectangle") {
                LogsView()
            }
            Tab("Trend", systemImage: "chart.line.uptrend.xyaxis") {
                TrendView()
            }
            Tab("Settings", systemImage: "gearshape.fill") {
                SettingsView()
            }
        }
    }
}
