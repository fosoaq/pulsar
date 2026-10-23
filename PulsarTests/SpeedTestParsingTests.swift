import Foundation
import Testing
@testable import Pulsar

/// Real tool output, with addresses, ISP and server replaced by placeholders.
private func fixture(_ name: String) throws -> Data {
    let url = URL(filePath: #filePath).deletingLastPathComponent().appending(path: "Fixtures/\(name)")
    return try Data(contentsOf: url)
}

private let date = Date(timeIntervalSince1970: 1_800_000_000)

struct NetworkQualityParsingTests {
    @Test func parsesReport() throws {
        let result = try NetworkQualityEngine.parse(output: fixture("networkquality-result.json"), errorOutput: Data(), status: 0, date: date)

        #expect(result.date == date)
        #expect(result.engine == "networkQuality")
        #expect(abs(result.downloadMbps! - 850.168768) < 0.0001)
        #expect(abs(result.uploadMbps! - 703.284352) < 0.0001)
        #expect(abs(result.latencyMs! - 31.51) < 0.01)
        #expect(abs(result.responsivenessRPM! - 754.47) < 0.01)
        #expect(result.interfaceName == "en0")
        #expect(result.server == "sesto4-edge-fx-006.aaplimg.com")
        #expect(result.succeeded)
    }

    @Test func reportsToolErrorText() {
        #expect {
            try NetworkQualityEngine.parse(output: Data(), errorOutput: Data("No network connection".utf8), status: 1)
        } throws: { error in
            error.localizedDescription.contains("No network connection")
        }
    }

    @Test func rejectsReportWithoutThroughput() {
        #expect(throws: SpeedTestError.self) {
            try NetworkQualityEngine.parse(output: Data(#"{"base_rtt": 30}"#.utf8), errorOutput: Data(), status: 0)
        }
    }
}

struct OoklaParsingTests {
    @Test func parsesResult() throws {
        let result = try OoklaEngine.parse(output: fixture("ookla-result.json"), errorOutput: Data(), status: 0, date: date)

        #expect(result.engine == "ookla")
        // Bandwidth is bytes per second.
        #expect(abs(result.downloadMbps! - 103_348_023 * 8 / 1_000_000) < 0.0001)
        #expect(abs(result.uploadMbps! - 108_528_966 * 8 / 1_000_000) < 0.0001)
        #expect(result.latencyMs == 0.857)
        #expect(result.jitterMs == 0.081)
        #expect(result.downloadLatencyMs == 1.803)
        #expect(result.uploadLatencyMs == 1.558)
        #expect(result.packetLossPercent == 0)
        #expect(result.isp == "Example ISP")
        #expect(result.server == "Example Server, Example City")
        #expect(result.interfaceName == "en0")
        #expect(result.resultURL == "https://www.speedtest.net/result/c/00000000-0000-0000-0000-000000000000")
    }

    @Test func explainsLicensePrompt() {
        let prompt = Data("To accept the message please run speedtest interactively or use the following:\n\n    speedtest --accept-license\n".utf8)
        #expect {
            try OoklaEngine.parse(output: prompt, errorOutput: Data(), status: 1)
        } throws: { error in
            error.localizedDescription.contains("Settings")
        }
    }

    @Test func surfacesLoggedError() throws {
        let output = try fixture("ookla-error.json")
        #expect {
            try OoklaEngine.parse(output: output, errorOutput: Data(), status: 2)
        } throws: { error in
            error.localizedDescription.contains("Couldn't resolve host name")
        }
    }
}
