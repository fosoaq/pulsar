import Foundation

/// The official Ookla `speedtest` CLI, installed by the user (its license forbids bundling it).
struct OoklaEngine: SpeedTestEngine {
    let kind = SpeedTestEngineKind.ookla
    /// Set once the user has agreed in Settings; the CLI refuses to run until then.
    var acceptLicense = false

    static let searchPaths = ["/opt/homebrew/bin/speedtest", "/usr/local/bin/speedtest"]

    static var executablePath: String? {
        searchPaths.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    func run() async throws -> SpeedTestResult {
        guard let path = Self.executablePath else {
            throw SpeedTestError(message: String(localized: "Ookla speedtest is not installed. Install it with `brew install teamookla/speedtest/speedtest`."))
        }
        let (output, errorOutput, status) = try await runTool(path, arguments: ["--format=json", "--progress=no"] + (acceptLicense ? ["--accept-license", "--accept-gdpr"] : []))
        return try Self.parse(output: output, errorOutput: errorOutput, status: status)
    }

    static func parse(output: Data, errorOutput: Data, status: Int32, date: Date = .now) throws -> SpeedTestResult {
        // Normally one JSON object per line; errors come as {"type":"log","level":"error",...}.
        // A single pretty-printed object is accepted too.
        let lines = String(decoding: output, as: UTF8.self).split(whereSeparator: \.isNewline)
        let messages = (try? JSONDecoder().decode(Message.self, from: output)).map { [$0] }
            ?? lines.compactMap { try? JSONDecoder().decode(Message.self, from: Data($0.utf8)) }
        if let report = messages.first(where: { $0.type == "result" }) {
            return result(from: report, date: date)
        }

        let allText = String(decoding: output + errorOutput, as: UTF8.self)
        if allText.contains("--accept-license") {
            throw SpeedTestError(message: String(localized: "Accept the Speedtest license in Pulsar Settings."))
        }
        if let logged = messages.last(where: { $0.level == "error" })?.message {
            throw SpeedTestError(message: "speedtest: \(logged)")
        }
        throw SpeedTestError(message: "speedtest exited with status \(status): \(allText.trimmingCharacters(in: .whitespacesAndNewlines))")
    }

    private static func result(from report: Message, date: Date) -> SpeedTestResult {
        let server = report.server.map { [$0.name, $0.location].compactMap { $0 }.joined(separator: ", ") }
        return SpeedTestResult(
            date: date,
            engine: SpeedTestEngineKind.ookla.rawValue,
            // Ookla reports bandwidth in bytes per second.
            downloadMbps: report.download?.bandwidth.map { $0 * 8 / 1_000_000 },
            uploadMbps: report.upload?.bandwidth.map { $0 * 8 / 1_000_000 },
            latencyMs: report.ping?.latency,
            jitterMs: report.ping?.jitter,
            packetLossPercent: report.packetLoss,
            interfaceName: report.interface?.name,
            server: server,
            isp: report.isp,
            resultURL: report.result?.url
        )
    }

    private struct Message: Decodable {
        let type: String
        let level: String?
        let message: String?
        let ping: Ping?
        let download: Transfer?
        let upload: Transfer?
        let packetLoss: Double?
        let isp: String?
        let interface: Interface?
        let server: Server?
        let result: Link?

        struct Ping: Decodable { let latency: Double?; let jitter: Double? }
        struct Transfer: Decodable { let bandwidth: Double? }
        struct Interface: Decodable { let name: String? }
        struct Server: Decodable { let name: String?; let location: String? }
        struct Link: Decodable { let url: String? }
    }
}
