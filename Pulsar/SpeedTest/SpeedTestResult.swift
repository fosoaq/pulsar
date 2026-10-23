import Foundation
import GRDB

/// One speed test run. A failed run is stored too, with `error` set and no measurements.
struct SpeedTestResult: Codable, Identifiable, Sendable, FetchableRecord, MutablePersistableRecord {
    var id: Int64?
    var date: Date
    var engine: String
    var downloadMbps: Double?
    var uploadMbps: Double?
    /// Idle ping.
    var latencyMs: Double?
    var jitterMs: Double?
    /// Ping while the connection is busy downloading or uploading (Ookla only).
    var downloadLatencyMs: Double?
    var uploadLatencyMs: Double?
    var packetLossPercent: Double?
    var responsivenessRPM: Double?
    var interfaceName: String?
    var server: String?
    var isp: String?
    var resultURL: String?
    var error: String?

    static let databaseTableName = "result"

    var succeeded: Bool { error == nil }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
