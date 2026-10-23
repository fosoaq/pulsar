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
    /// Published as `<name>.local`; empty leaves only the Mac's own name and IP.
    var dashboardHostname = "pulsar"
    /// Days of history to keep; 0 keeps everything.
    var keepDays = 365
    // Remote channels; an empty field turns that channel off.
    var telegramBotToken = ""
    var telegramChatID = ""
    var ntfyURL = ""
    var webhookURL = ""

    static let intervalChoices = [15, 30, 60, 120, 180, 360, 720, 1440]
    static let keepDaysChoices = [30, 90, 180, 365, 730, 0]

    /// Keeps what a DNS label allows: lowercase letters, digits and hyphens, at most 63.
    /// Hyphens at the ends survive so they can be typed; `applyHostname` trims them.
    static func sanitizedHostname(_ name: String) -> String {
        let allowed = name.lowercased().filter { ("a"..."z").contains($0) || ("0"..."9").contains($0) || $0 == "-" }
        return String(allowed.prefix(63))
    }

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
        dashboardHostname = try container.decodeIfPresent(String.self, forKey: .dashboardHostname) ?? defaults.dashboardHostname
        keepDays = try container.decodeIfPresent(Int.self, forKey: .keepDays) ?? defaults.keepDays
        telegramBotToken = try container.decodeIfPresent(String.self, forKey: .telegramBotToken) ?? defaults.telegramBotToken
        telegramChatID = try container.decodeIfPresent(String.self, forKey: .telegramChatID) ?? defaults.telegramChatID
        ntfyURL = try container.decodeIfPresent(String.self, forKey: .ntfyURL) ?? defaults.ntfyURL
        webhookURL = try container.decodeIfPresent(String.self, forKey: .webhookURL) ?? defaults.webhookURL
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
