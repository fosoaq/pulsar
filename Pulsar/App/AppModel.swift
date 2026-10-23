import Foundation
import Observation
import ServiceManagement
import SystemConfiguration

/// Owns the history, the schedule and the services the settings switch on and off.
@MainActor
@Observable
final class AppModel {
    /// The last 30 days, newest first.
    private(set) var recent: [SpeedTestResult] = []
    private(set) var isRunning = false
    private(set) var dashboardError: String?
    private(set) var storeError: String?
    private(set) var hostnameError: String?
    /// Why the last delivery to Telegram, ntfy or the webhook failed, if it did.
    private(set) var deliveryError: String?
    /// A newer release on GitHub, found by the daily check.
    private(set) var availableUpdate: UpdateChecker.Release?
    /// Nearby Speedtest.net servers, loaded on demand.
    private(set) var ooklaServers: [OoklaServer] = []
    private(set) var ooklaServersError: String?

    var settings: AppSettings {
        didSet {
            guard settings != oldValue else { return }
            settings.save()
            applySettings(previous: oldValue)
        }
    }

    @ObservationIgnored private let store: ResultStore?
    @ObservationIgnored private let notifier = Notifier()
    @ObservationIgnored private let sleepGuard = SleepGuard()
    @ObservationIgnored private let dashboard = DashboardServer()
    @ObservationIgnored private let hostname = HostnameAdvertiser()
    @ObservationIgnored private var schedulerTask: Task<Void, Never>?
    @ObservationIgnored private var lastUpdateCheck = Date.distantPast
    @ObservationIgnored private var serversTask: Task<Void, Never>?
    @ObservationIgnored private var lastServersAttempt = Date.distantPast

    /// Unit tests load the app as their host; it must not start testing or serving then.
    static let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil

    init() {
        settings = AppSettings.load()
        guard !Self.isRunningTests else {
            store = nil
            return
        }
        do {
            store = try ResultStore.makeDefault()
        } catch {
            store = nil
            storeError = String(localized: "Could not open the history database: \(error.localizedDescription)")
        }
        pruneHistory()
        reload()
        notifier.requestAuthorization()
        hostname.onError = { [weak self] message in
            self?.hostnameError = message
        }
        applySettings(previous: nil)
        enableLaunchAtLoginOnFirstInstall()
        startScheduler()
    }

    /// A menu bar monitor is only useful while it runs, so the first launch from
    /// /Applications adds it to login items once; Settings can turn that off again.
    private func enableLaunchAtLoginOnFirstInstall() {
        let key = "didEnableLaunchAtLogin"
        guard !UserDefaults.standard.bool(forKey: key), Bundle.main.bundlePath.hasPrefix("/Applications/") else { return }
        UserDefaults.standard.set(true, forKey: key)
        try? SMAppService.mainApp.register()
    }

    func checkForUpdates() async {
        lastUpdateCheck = .now
        if let release = try? await UpdateChecker().check() {
            availableUpdate = release
        }
    }

    var latest: SpeedTestResult? { recent.first }

    var lastSuccess: SpeedTestResult? { recent.first(where: \.succeeded) }

    /// Due right away when nothing has run yet, and soon again after a failure.
    var nextRunDate: Date {
        guard let last = latest else { return .now }
        let minutes = last.succeeded ? settings.intervalMinutes : min(Self.retryMinutes, settings.intervalMinutes)
        return last.date.addingTimeInterval(TimeInterval(minutes * 60))
    }

    static let retryMinutes = 5

    /// Tests are paused until the user agrees to Ookla's license in Settings.
    var needsOoklaLicense: Bool {
        settings.engine == .ookla && !settings.acceptedOoklaLicense
    }

    /// The address other devices on the network can open: Pulsar's own `.local` name,
    /// or the Mac's Local hostname when that name is empty or taken.
    var dashboardURL: URL? {
        let ownName = settings.dashboardHostname.isEmpty || hostnameError != nil ? nil : settings.dashboardHostname
        return (ownName ?? SCDynamicStoreCopyLocalHostName(nil) as String?).flatMap { dashboardURL(host: "\($0).local") }
    }

    /// The same dashboard by IP, for devices that cannot resolve `.local` names.
    var dashboardIPURL: URL? {
        LocalAddress.current().flatMap { dashboardURL(host: $0.ip) }
    }

    private func dashboardURL(host: String) -> URL? {
        guard settings.dashboardEnabled else { return nil }
        var components = URLComponents()
        components.scheme = "http"
        components.host = host
        components.port = settings.dashboardPort == 80 ? nil : settings.dashboardPort
        return components.url
    }

    /// `serverID` overrides the configured Ookla server for this run only.
    func runNow(serverID: Int? = nil) {
        guard !isRunning, !needsOoklaLicense else { return }
        isRunning = true
        Task { await performRun(serverID: serverID ?? settings.ooklaServerID) }
    }

    /// Lists nearby servers once and keeps them; `refresh` asks the CLI again.
    ///
    /// The dashboard can ask for the list without any credentials, so at most one
    /// `speedtest --servers` runs at a time, and after an attempt that found nothing
    /// only `refresh` (from Settings) retries within five minutes.
    @discardableResult
    func loadOoklaServers(refresh: Bool = false) async -> [OoklaServer] {
        if let serversTask {
            await serversTask.value
            return ooklaServers
        }
        let coolingDown = lastServersAttempt.addingTimeInterval(300) > .now
        guard refresh || (ooklaServers.isEmpty && !coolingDown), OoklaEngine.executablePath != nil else { return ooklaServers }

        lastServersAttempt = .now
        let accept = settings.acceptedOoklaLicense
        let task = Task {
            do {
                ooklaServers = try await OoklaEngine.servers(acceptLicense: accept)
                ooklaServersError = nil
            } catch {
                ooklaServersError = error.localizedDescription
            }
        }
        serversTask = task
        await task.value
        serversTask = nil
        return ooklaServers
    }

    private func performRun(serverID: Int?) async {
        defer { isRunning = false }
        let engine = settings.engine.makeEngine(acceptingOoklaLicense: settings.acceptedOoklaLicense, ooklaServerID: serverID)
        var result: SpeedTestResult
        do {
            result = try await engine.run()
        } catch {
            result = SpeedTestResult(date: .now, engine: engine.kind.rawValue, error: error.localizedDescription)
        }

        if let store {
            do {
                result = try store.insert(result)
            } catch {
                storeError = String(localized: "Could not save the result: \(error.localizedDescription)")
            }
        }
        pruneHistory()
        if store == nil || storeError != nil {
            recent.insert(result, at: 0)
        } else {
            reload()
        }

        let alert = Alert.make(for: result, settings: settings)
        if let alert {
            notifier.post(alert)
        }
        await deliver(result: result, alert: alert)
    }

    /// Sends a sample alert through every configured channel.
    func sendTestNotification() async {
        let alert = Alert(title: String(localized: "Pulsar test notification"), body: String(localized: "Notifications from Pulsar reach you here."))
        notifier.post(alert)
        await deliver(result: nil, alert: alert)
    }

    private func deliver(result: SpeedTestResult?, alert: Alert?) async {
        let failures = await RemoteChannels(settings: settings).deliver(result: result, alert: alert)
        deliveryError = failures.isEmpty ? nil : failures.joined(separator: "\n")
    }

    private func reload() {
        guard let store else { return }
        do {
            recent = try store.results(since: .now.addingTimeInterval(-30 * 86_400))
        } catch {
            storeError = String(localized: "Could not read the history: \(error.localizedDescription)")
        }
    }

    private func pruneHistory() {
        guard settings.keepDays > 0, let store else { return }
        _ = try? store.deleteResults(before: .now.addingTimeInterval(-Double(settings.keepDays) * 86_400))
    }

    private func startScheduler() {
        schedulerTask = Task { [weak self] in
            while !Task.isCancelled {
                // Follows the Mac to a new IP address, e.g. after a DHCP renewal.
                self?.publishHostname()
                self?.checkForUpdatesIfDue()
                self?.runIfDue()
                try? await Task.sleep(for: .seconds(30))
            }
        }
    }

    private func checkForUpdatesIfDue() {
        guard lastUpdateCheck.addingTimeInterval(86_400) < .now else { return }
        Task { await checkForUpdates() }
    }

    private func runIfDue() {
        if !isRunning, nextRunDate <= .now {
            runNow()
        }
    }

    private func publishHostname() {
        let name = settings.dashboardEnabled && !settings.dashboardHostname.isEmpty ? settings.dashboardHostname : nil
        hostname.update(name: name, address: LocalAddress.current())
    }

    private func applySettings(previous: AppSettings?) {
        sleepGuard.setActive(settings.preventSleep)
        if previous?.dashboardHostname != settings.dashboardHostname || previous?.dashboardEnabled != settings.dashboardEnabled {
            hostnameError = nil
            publishHostname()
        }
        if previous?.dashboardEnabled != settings.dashboardEnabled || previous?.dashboardPort != settings.dashboardPort {
            restartDashboard()
        }
        if previous != nil, previous?.keepDays != settings.keepDays {
            pruneHistory()
            reload()
        }
    }

    private func restartDashboard() {
        dashboard.stop()
        dashboardError = nil
        guard settings.dashboardEnabled, let store else { return }
        let controls = DashboardControls(
            runTest: { [weak self] serverID in
                guard let self, !isRunning, !needsOoklaLicense else { return false }
                runNow(serverID: serverID)
                return true
            },
            status: { [weak self] in
                DashboardControls.Status(
                    running: self?.isRunning ?? false,
                    paused: self?.needsOoklaLicense ?? false,
                    nextRun: self?.nextRunDate ?? .now,
                    engine: self?.settings.engine.rawValue ?? "",
                    serverID: self?.settings.ooklaServerID,
                    minDownloadMbps: self?.settings.minDownloadMbps ?? 0,
                    minUploadMbps: self?.settings.minUploadMbps ?? 0,
                    hostName: SCDynamicStoreCopyComputerName(nil, nil) as String? ?? "",
                    version: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
                )
            },
            servers: { [weak self] in
                guard let self, settings.engine == .ookla else { return [] }
                return await loadOoklaServers()
            }
        )
        dashboard.start(port: settings.dashboardPort, store: store, controls: controls) { [weak self] message in
            self?.dashboardError = message
        }
    }
}
