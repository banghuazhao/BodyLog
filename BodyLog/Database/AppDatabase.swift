// Created by Banghua Zhao on 12/04/2026
// Copyright Apps Bay Limited. All rights reserved.

import Foundation
import SQLiteData

func makeAppDatabase() throws -> any DatabaseWriter {
    var configuration = Configuration()
    configuration.foreignKeysEnabled = true
    let database = try SQLiteData.defaultDatabase(configuration: configuration)

    var migrator = DatabaseMigrator()
    #if DEBUG
    migrator.eraseDatabaseOnSchemaChange = true
    #endif

    migrator.registerMigration("v1_create_tables") { db in
        try #sql(
            """
            CREATE TABLE "metrics" (
              "id"         INTEGER PRIMARY KEY AUTOINCREMENT, 
              "name"       TEXT    NOT NULL DEFAULT '',
              "symbol"     TEXT    NOT NULL DEFAULT '',
              "kind"       INTEGER NOT NULL DEFAULT 2,
              "sortOrder"  INTEGER NOT NULL DEFAULT 0,
              "startValue" REAL,
              "goalValue"  REAL
            ) STRICT
            """
        ).execute(db)

        try #sql(
            """
            CREATE TABLE "logEntries" (
              "id"       INTEGER PRIMARY KEY AUTOINCREMENT, 
              "metricId" TEXT NOT NULL REFERENCES "metrics"("id") ON DELETE CASCADE,
              "date"     TEXT NOT NULL,
              "value"    REAL NOT NULL DEFAULT 0
            ) STRICT
            """
        ).execute(db)
    }

    migrator.registerMigration("v1_seed_defaults") { db in
        try db.seed {
            Metric.Draft(name: "Weight", symbol: "kg", kind: .weight, sortOrder: 0, startValue: 60, goalValue: 50)
            Metric.Draft(name: "Height", symbol: "cm", kind: .height, sortOrder: 1, startValue: 158, goalValue: 162)
        }
    }

    try migrator.migrate(database)
    return database
}
