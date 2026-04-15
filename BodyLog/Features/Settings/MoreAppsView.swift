// Created by Cursor on 14/04/2026

import SwiftUI

struct AppItem: Identifiable {
    var id: String { title }

    let title: String
    let detail: String
    let iconAssetName: String
    let url: URL?
}

enum AppConstants {
    enum AppID {
        static let tripMarkID = "6464474080"
        static let moneyTrackerAppID = "1534244892"
        static let bmiDiaryAppID = "1521281509"
        static let novelsHubAppID = "1528820845"
    }
}

struct MoreAppsView: View {
    @Environment(\.openURL) private var openURL
    private let apps: [AppItem]

    init(apps: [AppItem] = AppItemStore.allItems) {
        self.apps = apps
    }

    var body: some View {
        List(apps) { app in
            Button {
                guard let url = app.url else { return }
                openURL(url)
            } label: {
                HStack(spacing: 12) {
                    Image(app.iconAssetName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(app.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(app.detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .contentShape(.rect)
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
        }
        .navigationTitle("More Apps")
    }
}

enum AppItemStore {
    static let allItems: [AppItem] = [
        AppItem(
            title: "TripMark",
            detail: "Vacation, Itinerary Planner",
            iconAssetName: "appIcon_tripmark",
            url: URL(string: "http://itunes.apple.com/app/id\(AppConstants.AppID.tripMarkID)")
        ),
        AppItem(
            title: "SwiftSum",
            detail: "Math Solver & Calculator App",
            iconAssetName: "appIcon_swiftsum",
            url: URL(string: "http://itunes.apple.com/app/id1610829871")
        ),
        AppItem(
            title: "Shows",
            detail: "Movie, TV Show Tracker",
            iconAssetName: "appIcon_shows",
            url: URL(string: "http://itunes.apple.com/app/id1624910011")
        ),
        AppItem(
            title: "Falling Block Puzzle",
            detail: "Retro",
            iconAssetName: "appIcon_falling_block_puzzle",
            url: URL(string: "https://apps.apple.com/app/id1609440799")
        ),
        AppItem(
            title: "Money Tracker",
            detail: "Budget, Expense & Bill Planner",
            iconAssetName: "appIcon_money_tracker",
            url: URL(string: "http://itunes.apple.com/app/id\(AppConstants.AppID.moneyTrackerAppID)")
        ),
        AppItem(
            title: "CalmCanvas",
            detail: "Meditation, Relaxing",
            iconAssetName: "appIcon_relaxing_up",
            url: URL(string: "http://itunes.apple.com/app/id1618712178")
        ),
        AppItem(
            title: "We Play Piano",
            detail: "Piano Keyboard",
            iconAssetName: "appIcon_we_play_piano",
            url: URL(string: "http://itunes.apple.com/app/id1625018611")
        ),
        AppItem(
            title: "ClassicReads",
            detail: "Novels & Fiction",
            iconAssetName: "appIcon_novels_Hub",
            url: URL(string: "http://itunes.apple.com/app/id\(AppConstants.AppID.novelsHubAppID)")
        ),
        AppItem(
            title: "World Weather Live",
            detail: "All Cities",
            iconAssetName: "appIcon_world_weather_live",
            url: URL(string: "http://itunes.apple.com/app/id1612773646")
        ),
        AppItem(
            title: "Minesweeper Z",
            detail: "Minesweeper App",
            iconAssetName: "appIcon_minesweeper",
            url: URL(string: "http://itunes.apple.com/app/id1621899572")
        ),
        AppItem(
            title: "Sudoku Lover",
            detail: "Sudoku Puzzles",
            iconAssetName: "appIcon_sudoku_lover",
            url: URL(string: "http://itunes.apple.com/app/id1620749798")
        ),
        AppItem(
            title: "BMI Diary",
            detail: "Fitness, Weight Loss & Health",
            iconAssetName: "appIcon_longivity",
            url: URL(string: "http://itunes.apple.com/app/id\(AppConstants.AppID.bmiDiaryAppID)")
        ),
        AppItem(
            title: "More Apps",
            detail: "Check out more apps made by us",
            iconAssetName: "appIcon_appStore",
            url: URL(string: "https://apps.apple.com/us/developer/%E7%92%90%E7%92%98-%E6%9D%A8/id1599035519")
        )
    ]
}
