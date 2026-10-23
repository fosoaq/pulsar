import Foundation

/// The non-HTML responses of the dashboard server.
enum DashboardFormats {
    static func csv(_ results: [SpeedTestResult]) -> String {
        let header = "date,engine,download_mbps,upload_mbps,latency_ms,jitter_ms,packet_loss_percent,responsiveness_rpm,interface,server,isp,result_url,error"
        let dateFormat = Date.ISO8601FormatStyle()
        let rows = results.map { result in
            [
                result.date.formatted(dateFormat),
                result.engine,
                number(result.downloadMbps),
                number(result.uploadMbps),
                number(result.latencyMs),
                number(result.jitterMs),
                number(result.packetLossPercent),
                number(result.responsivenessRPM),
                result.interfaceName ?? "",
                result.server ?? "",
                result.isp ?? "",
                result.resultURL ?? "",
                result.error ?? "",
            ]
            .map(field)
            .joined(separator: ",")
        }
        return ([header] + rows).joined(separator: "\r\n") + "\r\n"
    }

    /// Prometheus text format: the last successful test, plus whether the latest one worked.
    static func metrics(latest: SpeedTestResult?, lastSuccess: SpeedTestResult?) -> String {
        var lines: [String] = []
        func gauge(_ name: String, _ help: String, _ value: Double?) {
            guard let value else { return }
            lines += ["# HELP \(name) \(help)", "# TYPE \(name) gauge", "\(name) \(value)"]
        }
        gauge("pulsar_download_mbps", "Download speed of the last successful test.", lastSuccess?.downloadMbps)
        gauge("pulsar_upload_mbps", "Upload speed of the last successful test.", lastSuccess?.uploadMbps)
        gauge("pulsar_latency_ms", "Idle latency of the last successful test.", lastSuccess?.latencyMs)
        gauge("pulsar_jitter_ms", "Jitter of the last successful test.", lastSuccess?.jitterMs)
        gauge("pulsar_packet_loss_percent", "Packet loss of the last successful test.", lastSuccess?.packetLossPercent)
        gauge("pulsar_responsiveness_rpm", "Responsiveness under load of the last successful test.", lastSuccess?.responsivenessRPM)
        gauge("pulsar_last_success_timestamp_seconds", "When the last successful test finished.", lastSuccess?.date.timeIntervalSince1970)
        gauge("pulsar_last_test_timestamp_seconds", "When the latest test finished.", latest?.date.timeIntervalSince1970)
        gauge("pulsar_last_test_success", "1 if the latest test succeeded, 0 if it failed.", latest.map { $0.succeeded ? 1 : 0 })
        return lines.joined(separator: "\n") + "\n"
    }

    private static func number(_ value: Double?) -> String {
        value.map { String($0) } ?? ""
    }

    /// Quotes a field when it holds a comma, quote or line break; a formula character at the
    /// start, even after spaces, is neutralized so spreadsheets do not evaluate it.
    private static func field(_ value: String) -> String {
        var value = value
        let first = value.first { !$0.isWhitespace || $0 == "\t" || $0 == "\r" }
        if let first, "=+-@\t\r".contains(first), Double(value) == nil {
            value = "'" + value
        }
        guard value.contains(where: { ",\"\r\n".contains($0) }) else { return value }
        return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
