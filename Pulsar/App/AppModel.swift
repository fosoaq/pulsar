import Foundation
import Observation
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
    @ObservationIgnored private var schedulerTask: Task<Void, Never>?

    init() {
        settings = AppSettings.load()
        do {
            store = try ResultStore.makeDefault()
        } catch {
            store = nil
            storeError = "Could not open the history database: \(error.localizedDescription)"
        }
        reload()
        notifier.requestAuthorization()
        applySettings(previous: nil)
        startScheduler()
    }

    var latest: SpeedTestResult? { recent.first }

    var lastSuccess: SpeedTestResult? { recent.first(where: \.succeeded) }

    /// Due right away when nothing has run yet.
    var nextRunDate: Date {
        guard let last = latest?.date else { return .now }
        return last.addingTimeInterval(TimeInterval(settings.intervalMinutes * 60))
    }

    /// The address other devices on the network can open.
    var dashboardURL: URL? {
        guard settings.dashboardEnabled else { return nil }
        let host = (SCDynamicStoreCopyLocalHostName(nil) as String?).map { "\($0).local" } ?? "localhost"
        return URL(string: "http://\(host):\(settings.dashboardPort)")
    }

    func runNow() {
        guard !isRunning else { return }
        isRunning = true
        Task { await performRun() }
    }

    private func performRun() async {
        defer { isRunning = false }
        let engine = settings.engine.makeEngine()
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
                storeError = "Could not save the result: \(error.localizedDescription)"
            }
        }
        if store == nil || storeError != nil {
            recent.insert(result, at: 0)
        } else {
            reload()
        }
        notifier.report(result, settings: settings)
    }

    private func reload() {
        guard let store else { return }
        do {
            recent = try store.results(since: .now.addingTimeInterval(-30 * 86_400))
        } catch {
            storeError = "Could not read the history: \(error.localizedDescription)"
        }
    }

    private func startScheduler() {
        schedulerTask = Task { [weak self] in
            while !Task.isCancelled {
                self?.runIfDue()
                try? await Task.sleep(for: .seconds(30))
            }
        }
    }

    private func runIfDue() {
        if !isRunning, nextRunDate <= .now {
            runNow()
        }
    }

    private func applySettings(previous: AppSettings?) {
        sleepGuard.setActive(settings.preventSleep)
        if previous?.dashboardEnabled != settings.dashboardEnabled || previous?.dashboardPort != settings.dashboardPort {
            restartDashboard()
        }
    }

    private func restartDashboard() {
        dashboard.stop()
        dashboardError = nil
        guard settings.dashboardEnabled, let store else { return }
        dashboard.start(port: settings.dashboardPort, store: store) { [weak self] message in
            self?.dashboardError = message
        }
    }
}
