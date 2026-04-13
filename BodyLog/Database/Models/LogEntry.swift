// Created by Banghua Zhao on 12/04/2026
// Copyright Apps Bay Limited. All rights reserved.

import Foundation
import SQLiteData

@Table
nonisolated struct LogEntry: Identifiable, Sendable {
    let id: Int
    var metricId: Metric.ID
    var date: Date
    var value: Double = 0
}
