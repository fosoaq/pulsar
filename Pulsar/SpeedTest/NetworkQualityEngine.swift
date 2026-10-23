import Foundation

/// macOS's built-in `networkQuality`. Measures against Apple's CDN, needs nothing installed.
struct NetworkQualityEngine: SpeedTestEngine {
    let kind = SpeedTestEngineKind.networkQuality

    func run() async throws -> SpeedTestResult {
        let (output, errorOutput, status) = try await runTool("/usr/bin/networkQuality", arguments: ["-c", "-M", "60"])

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let report = try? decoder.decode(Report.self, from: output) else {
            let text = String(decoding: errorOutput.isEmpty ? output : errorOutput, as: UTF8.self)
            throw SpeedTestError(message: "networkQuality exited with status \(status): \(text.trimmingCharacters(in: .whitespacesAndNewlines))")
        }
        if let errorCode = report.errorCode {
            throw SpeedTestError(message: "networkQuality failed: \(report.errorDomain ?? "error") \(errorCode)")
        }
        guard let download = report.dlThroughput, let upload = report.ulThroughput else {
            throw SpeedTestError(message: "networkQuality returned no throughput")
        }

        return SpeedTestResult(
            date: .now,
            engine: kind.rawValue,
            downloadMbps: download / 1_000_000,
            uploadMbps: upload / 1_000_000,
            latencyMs: report.baseRtt,
            responsivenessRPM: report.responsiveness,
            interfaceName: report.interfaceName,
            server: report.testEndpoint
        )
    }

    /// The scalar part of `networkQuality -c`; throughput is in bits per second.
    private struct Report: Decodable {
        let dlThroughput: Double?
        let ulThroughput: Double?
        let baseRtt: Double?
        let responsiveness: Double?
        let interfaceName: String?
        let testEndpoint: String?
        let errorCode: Int?
        let errorDomain: String?
    }
}
