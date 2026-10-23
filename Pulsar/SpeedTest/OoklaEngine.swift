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
            throw SpeedTestError(message: "Ookla speedtest is not installed. Install it with `brew install teamookla/speedtest/speedtest`.")
        }
        let (output, errorOutput, status) = try await runTool(path, arguments: ["--format=json", "--progress=no"] + (acceptLicense ? ["--accept-license", "--accept-gdpr"] : []))

        // The result is one JSON object per line; errors come as {"type":"log","level":"error",...}.
        let lines = String(decoding: output, as: UTF8.self).split(whereSeparator: \.isNewline)
        let messages = lines.compactMap { try? JSONDecoder().decode(Message.self, from: Data($0.utf8)) }
        if let report = messages.first(where: { $0.type == "result" }) {
            return result(from: report)
        }

        let allText = String(decoding: output + errorOutput, as: UTF8.self)
        if allText.contains("--accept-license") {
            throw SpeedTestError(message: "Accept the Speedtest license in Pulsar Settings.")
        }
        if let logged = messages.last(where: { $0.level == "error" })?.message {
            throw SpeedTestError(message: "speedtest: \(logged)")
        }
        throw SpeedTestError(message: "speedtest exited with status \(status): \(allText.trimmingCharacters(in: .whitespacesAndNewlines))")
    }

    private func result(from report: Message) -> SpeedTestResult {
        let server = report.server.map { [$0.name, $0.location].compactMap { $0 }.joined(separator: ", ") }
        return SpeedTestResult(
            date: .now,
            engine: kind.rawValue,
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
