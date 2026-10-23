import Foundation
import GRDB

/// Test history in `~/Library/Application Support/Pulsar/pulsar.sqlite`.
final class ResultStore: Sendable {
    private let dbQueue: DatabaseQueue

    init(path: String) throws {
        dbQueue = try DatabaseQueue(path: path)
        try Self.migrator.migrate(dbQueue)
    }

    static func makeDefault() throws -> ResultStore {
        let directory = URL.applicationSupportDirectory.appending(path: "Pulsar", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return try ResultStore(path: directory.appending(path: "pulsar.sqlite").path(percentEncoded: false))
    }

    private static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1") { db in
            try db.create(table: SpeedTestResult.databaseTableName) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("date", .datetime).notNull().indexed()
                t.column("engine", .text).notNull()
                t.column("downloadMbps", .double)
                t.column("uploadMbps", .double)
                t.column("latencyMs", .double)
                t.column("jitterMs", .double)
                t.column("packetLossPercent", .double)
                t.column("responsivenessRPM", .double)
                t.column("interfaceName", .text)
                t.column("server", .text)
                t.column("isp", .text)
                t.column("resultURL", .text)
                t.column("error", .text)
            }
        }
        migrator.registerMigration("v2-loaded-latency") { db in
            try db.alter(table: SpeedTestResult.databaseTableName) { t in
                t.add(column: "downloadLatencyMs", .double)
                t.add(column: "uploadLatencyMs", .double)
            }
        }
        return migrator
    }

    func insert(_ result: SpeedTestResult) throws -> SpeedTestResult {
        try dbQueue.write { db in
            var result = result
            try result.insert(db)
            return result
        }
    }

    /// Returns how many were removed.
    @discardableResult
    func deleteResults(before date: Date) throws -> Int {
        try dbQueue.write { db in
            try SpeedTestResult.filter(Column("date") < date).deleteAll(db)
        }
    }

    /// Newest first.
    func results(since date: Date) throws -> [SpeedTestResult] {
        try dbQueue.read { db in
            try SpeedTestResult
                .filter(Column("date") >= date)
                .order(Column("date").desc)
                .fetchAll(db)
        }
    }
}
