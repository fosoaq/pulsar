import Foundation

struct AppSettings: Codable, Equatable, Sendable {
    /// Ookla when it is installed, so a fresh install works without it too.
    var engine: SpeedTestEngineKind = OoklaEngine.executablePath != nil ? .ookla : .networkQuality
    var acceptedOoklaLicense = false
    var intervalMinutes = 60
    var preventSleep = true
    var notifyOnFailure = true
    /// 0 turns the threshold off.
    var minDownloadMbps = 0.0
    var minUploadMbps = 0.0
    var dashboardEnabled = true
    var dashboardPort = 8765

    static let intervalChoices = [15, 30, 60, 120, 180, 360, 720, 1440]

    init() {}

    // Every key is optional so settings saved by an older version still load.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = AppSettings()
        engine = (try? container.decodeIfPresent(SpeedTestEngineKind.self, forKey: .engine)) ?? defaults.engine
        acceptedOoklaLicense = try container.decodeIfPresent(Bool.self, forKey: .acceptedOoklaLicense) ?? defaults.acceptedOoklaLicense
        intervalMinutes = try container.decodeIfPresent(Int.self, forKey: .intervalMinutes) ?? defaults.intervalMinutes
        preventSleep = try container.decodeIfPresent(Bool.self, forKey: .preventSleep) ?? defaults.preventSleep
        notifyOnFailure = try container.decodeIfPresent(Bool.self, forKey: .notifyOnFailure) ?? defaults.notifyOnFailure
        minDownloadMbps = try container.decodeIfPresent(Double.self, forKey: .minDownloadMbps) ?? defaults.minDownloadMbps
        minUploadMbps = try container.decodeIfPresent(Double.self, forKey: .minUploadMbps) ?? defaults.minUploadMbps
        dashboardEnabled = try container.decodeIfPresent(Bool.self, forKey: .dashboardEnabled) ?? defaults.dashboardEnabled
        dashboardPort = try container.decodeIfPresent(Int.self, forKey: .dashboardPort) ?? defaults.dashboardPort
    }

    private static let defaultsKey = "settings"

    static func load() -> AppSettings {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data)
        else { return AppSettings() }
        return settings
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.defaultsKey)
    }
}
