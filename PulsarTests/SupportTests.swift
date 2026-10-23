import Foundation
import Testing
@testable import Pulsar

struct LocalHostMiddlewareTests {
    @Test(arguments: ["localhost", "localhost:80", "pulsar.local", "MyMac.local:8765", "192.168.1.10", "192.168.1.10:8765", "[::1]:8765", "[fe80::1]"])
    func acceptsLocalHosts(_ authority: String) {
        #expect(isLocalAuthority(authority))
    }

    @Test(arguments: ["evil.example", "evil.example:80", "rebind.attacker.com:8765", "local", "pulsar.local.evil.com", "[not-an-ip]", "999.1.1.1"])
    func rejectsOtherHosts(_ authority: String) {
        #expect(!isLocalAuthority(authority))
    }
}

struct AppSettingsTests {
    @Test func olderSettingsKeepDefaultsForNewKeys() throws {
        let data = Data(#"{"intervalMinutes": 30, "engine": "networkQuality"}"#.utf8)
        let settings = try JSONDecoder().decode(AppSettings.self, from: data)

        #expect(settings.intervalMinutes == 30)
        #expect(settings.engine == .networkQuality)
        #expect(settings.dashboardPort == AppSettings().dashboardPort)
        #expect(settings.dashboardHostname == "pulsar")
        #expect(!settings.acceptedOoklaLicense)
    }

    @Test func unknownEngineFallsBackToDefault() throws {
        let settings = try JSONDecoder().decode(AppSettings.self, from: Data(#"{"engine": "fast.com"}"#.utf8))
        #expect(settings.engine == AppSettings().engine)
    }

    @Test(arguments: [("Pulsar", "pulsar"), ("my pulsar!", "mypulsar"), ("dom-1", "dom-1"), ("Пульсар", ""), ("-edge-", "-edge-")])
    func sanitizesHostname(_ input: String, _ expected: String) {
        #expect(AppSettings.sanitizedHostname(input) == expected)
    }
}

struct ResultStoreTests {
    @Test func returnsResultsSinceDateNewestFirst() throws {
        let path = FileManager.default.temporaryDirectory.appending(path: "pulsar-test-\(UUID().uuidString).sqlite").path(percentEncoded: false)
        defer { try? FileManager.default.removeItem(atPath: path) }
        let store = try ResultStore(path: path)
        let now = Date.now

        let old = try store.insert(SpeedTestResult(date: now.addingTimeInterval(-10 * 86_400), engine: "ookla", downloadMbps: 1))
        let earlier = try store.insert(SpeedTestResult(date: now.addingTimeInterval(-3_600), engine: "ookla", downloadMbps: 2))
        let latest = try store.insert(SpeedTestResult(date: now, engine: "ookla", error: "offline"))

        #expect(old.id != nil)
        let results = try store.results(since: now.addingTimeInterval(-86_400))
        #expect(results.map(\.id) == [latest.id, earlier.id])
        #expect(results.first?.error == "offline")
        #expect(results.first?.succeeded == false)
    }
}

struct UpdateCheckerTests {
    @Test(arguments: [("v0.2.0", "0.1.0"), ("0.1.1", "0.1.0"), ("1.0", "0.9.9"), ("v0.10.0", "0.9.0")])
    func newer(_ candidate: String, _ current: String) {
        #expect(UpdateChecker.isVersion(candidate, newerThan: current))
    }

    @Test(arguments: [("v0.1.0", "0.1.0"), ("0.1", "0.1.0"), ("v0.0.9", "0.1.0"), ("0.9.0", "0.10.0")])
    func notNewer(_ candidate: String, _ current: String) {
        #expect(!UpdateChecker.isVersion(candidate, newerThan: current))
    }
}
