import Foundation
import Testing
@testable import Pulsar

private let date = Date(timeIntervalSince1970: 1_800_000_000)

private func result(download: Double? = 500, upload: Double? = 400, error: String? = nil) -> SpeedTestResult {
    SpeedTestResult(date: date, engine: "ookla", downloadMbps: download, uploadMbps: upload, latencyMs: 4, jitterMs: 0.5, packetLossPercent: 0, error: error)
}

struct AlertTests {
    @Test func failureAlertsOnlyWhenEnabled() {
        var settings = AppSettings()
        #expect(Alert.make(for: result(error: "offline"), settings: settings)?.body == "offline")
        settings.notifyOnFailure = false
        #expect(Alert.make(for: result(error: "offline"), settings: settings) == nil)
    }

    @Test func thresholdsAreOffByDefault() {
        #expect(Alert.make(for: result(download: 1, upload: 1), settings: AppSettings()) == nil)
    }

    @Test func listsEveryThresholdThatWasMissed() throws {
        var settings = AppSettings()
        settings.minDownloadMbps = 600
        settings.minUploadMbps = 300
        let downOnly = try #require(Alert.make(for: result(), settings: settings))
        #expect(downOnly.body.contains("500"))
        #expect(!downOnly.body.contains("400"))

        settings.minUploadMbps = 450
        let both = try #require(Alert.make(for: result(), settings: settings))
        #expect(both.body.split(separator: "\n").count == 2)
    }
}

struct DashboardFormatsTests {
    @Test func csvQuotesAndNeutralizesFields() {
        var row = result(error: "said \"no\", twice")
        row.server = "=HYPERLINK(\"x\")"
        let lines = DashboardFormats.csv([row]).components(separatedBy: "\r\n")

        #expect(lines[0].hasPrefix("date,engine,download_mbps"))
        #expect(lines[1].hasPrefix("2027-01-15T08:00:00Z,ookla,500.0,400.0,4.0,0.5,0.0,,"))
        #expect(lines[1].contains(#""'=HYPERLINK(""x"")""#))
        #expect(lines[1].hasSuffix(#""said ""no"", twice""#))
        #expect(lines[2].isEmpty)
    }

    @Test func metricsDescribeLastSuccessAndLatestOutcome() {
        let failed = result(download: nil, upload: nil, error: "offline")
        let text = DashboardFormats.metrics(latest: failed, lastSuccess: result())

        #expect(text.contains("pulsar_download_mbps 500.0\n"))
        #expect(text.contains("pulsar_upload_mbps 400.0\n"))
        #expect(text.contains("pulsar_last_test_success 0.0\n"))
        #expect(text.contains("# TYPE pulsar_latency_ms gauge\n"))
        #expect(!text.contains("pulsar_responsiveness_rpm"))
    }

    @Test func metricsAreEmptyBeforeTheFirstTest() {
        #expect(DashboardFormats.metrics(latest: nil, lastSuccess: nil) == "\n")
    }
}

struct WebhookPayloadTests {
    @Test func encodesEventAlertAndResult() throws {
        let payload = WebhookPayload(event: "test.completed", alert: .init(title: "Slow connection", body: "Download 5 Mbps"), result: result())
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let json = try #require(JSONSerialization.jsonObject(with: encoder.encode(payload)) as? [String: Any])

        #expect(json["event"] as? String == "test.completed")
        #expect((json["alert"] as? [String: String])?["title"] == "Slow connection")
        let body = try #require(json["result"] as? [String: Any])
        #expect(body["downloadMbps"] as? Double == 500)
        #expect(body["date"] as? String == "2027-01-15T08:00:00Z")
    }
}

struct RemoteChannelsTests {
    @Test func needsBothTelegramFieldsOrNtfy() {
        var settings = AppSettings()
        #expect(!RemoteChannels(settings: settings).hasAlertChannel)
        settings.telegramBotToken = "123:abc"
        #expect(!RemoteChannels(settings: settings).hasAlertChannel)
        settings.telegramChatID = " 42 "
        #expect(RemoteChannels(settings: settings).hasAlertChannel)
        #expect(RemoteChannels(settings: settings).telegramChatID == "42")
    }

    @Test func nothingConfiguredSendsNothing() async {
        let failures = await RemoteChannels(settings: AppSettings()).deliver(result: result(), alert: Alert(title: "t", body: "b"))
        #expect(failures.isEmpty)
    }

    @Test func invalidNtfyURLIsReported() async {
        var settings = AppSettings()
        settings.ntfyURL = "not a url"
        let failures = await RemoteChannels(settings: settings).deliver(result: nil, alert: Alert(title: "t", body: "b"))
        #expect(failures.count == 1)
        #expect(failures.first?.hasPrefix("ntfy:") == true)
    }
}
