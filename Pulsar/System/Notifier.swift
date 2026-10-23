import Foundation
import UserNotifications

/// What to tell the user about a run, if anything.
struct Alert: Equatable, Sendable {
    let title: String
    let body: String

    /// An alert when a run failed or came in below a threshold.
    static func make(for result: SpeedTestResult, settings: AppSettings) -> Alert? {
        if let error = result.error {
            return settings.notifyOnFailure ? Alert(title: String(localized: "Speed test failed"), body: error) : nil
        }

        var problems: [String] = []
        if settings.minDownloadMbps > 0, let download = result.downloadMbps, download < settings.minDownloadMbps {
            problems.append(String(localized: "Download \(Format.mbps(download)) Mbps, below \(Format.mbps(settings.minDownloadMbps))"))
        }
        if settings.minUploadMbps > 0, let upload = result.uploadMbps, upload < settings.minUploadMbps {
            problems.append(String(localized: "Upload \(Format.mbps(upload)) Mbps, below \(Format.mbps(settings.minUploadMbps))"))
        }
        return problems.isEmpty ? nil : Alert(title: String(localized: "Slow connection"), body: problems.joined(separator: "\n"))
    }
}

/// Notification Center on this Mac.
@MainActor
final class Notifier {
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func post(_ alert: Alert) {
        let content = UNMutableNotificationContent()
        content.title = alert.title
        content.body = alert.body
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
