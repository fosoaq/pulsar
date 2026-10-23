import Foundation

/// A way of measuring the connection. Each engine wraps a command-line tool.
protocol SpeedTestEngine: Sendable {
    var kind: SpeedTestEngineKind { get }
    func run() async throws -> SpeedTestResult
}

enum SpeedTestEngineKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case networkQuality
    case ookla

    var id: Self { self }

    var title: String {
        switch self {
        case .networkQuality: "Apple networkQuality"
        case .ookla: "Ookla Speedtest CLI"
        }
    }

    func makeEngine(acceptingOoklaLicense: Bool, ooklaServerID: Int? = nil) -> any SpeedTestEngine {
        switch self {
        case .networkQuality: NetworkQualityEngine()
        case .ookla: OoklaEngine(acceptLicense: acceptingOoklaLicense, serverID: ooklaServerID)
        }
    }
}

struct SpeedTestError: LocalizedError {
    let message: String

    var errorDescription: String? { message }
}

/// Runs a tool to completion off the main actor and returns its standard output.
func runTool(_ path: String, arguments: [String]) async throws -> (output: Data, errorOutput: Data, status: Int32) {
    try await Task.detached(priority: .utility) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        process.standardInput = FileHandle.nullDevice
        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr
        try process.run()
        // Read before waiting: the report is larger than a pipe buffer, so waiting first would deadlock.
        let output = stdout.fileHandleForReading.readDataToEndOfFile()
        let errorOutput = stderr.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return (output, errorOutput, process.terminationStatus)
    }.value
}
