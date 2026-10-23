import Foundation
import UserNotifications

@MainActor
final class Notifier {
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    /// Posts a notification when a run failed or came in below a threshold.
    func report(_ result: SpeedTestResult, settings: AppSettings) {
        if let error = result.error {
            if settings.notifyOnFailure {
                post(title: "Speed test failed", body: error)
            }
            return
        }

        var problems: [String] = []
        if settings.minDownloadMbps > 0, let download = result.downloadMbps, download < settings.minDownloadMbps {
            problems.append("Download \(Format.mbps(download)) Mbps, below \(Format.mbps(settings.minDownloadMbps))")
        }
        if settings.minUploadMbps > 0, let upload = result.uploadMbps, upload < settings.minUploadMbps {
            problems.append("Upload \(Format.mbps(upload)) Mbps, below \(Format.mbps(settings.minUploadMbps))")
        }
        if !problems.isEmpty {
            post(title: "Slow connection", body: problems.joined(separator: "\n"))
        }
    }

    private func post(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
