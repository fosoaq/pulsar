import Foundation

/// Telegram and ntfy get alerts; the webhook gets every result.
struct RemoteChannels: Sendable {
    let telegramBotToken: String
    let telegramChatID: String
    let ntfyURL: String
    let webhookURL: String

    init(settings: AppSettings) {
        telegramBotToken = settings.telegramBotToken.trimmingCharacters(in: .whitespaces)
        telegramChatID = settings.telegramChatID.trimmingCharacters(in: .whitespaces)
        ntfyURL = settings.ntfyURL.trimmingCharacters(in: .whitespaces)
        webhookURL = settings.webhookURL.trimmingCharacters(in: .whitespaces)
    }

    var hasAlertChannel: Bool {
        !(telegramBotToken.isEmpty || telegramChatID.isEmpty) || !ntfyURL.isEmpty
    }

    /// Sends to every configured channel and returns one message per channel that failed.
    func deliver(result: SpeedTestResult?, alert: Alert?) async -> [String] {
        var failures: [String] = []
        if let alert, !telegramBotToken.isEmpty, !telegramChatID.isEmpty {
            await attempt("Telegram", into: &failures) { try await sendTelegram(alert) }
        }
        if let alert, !ntfyURL.isEmpty {
            await attempt("ntfy", into: &failures) { try await sendNtfy(alert) }
        }
        if !webhookURL.isEmpty, result != nil || alert != nil {
            await attempt("Webhook", into: &failures) { try await sendWebhook(result: result, alert: alert) }
        }
        return failures
    }

    private func attempt(_ channel: String, into failures: inout [String], _ send: () async throws -> Void) async {
        do {
            try await send()
        } catch {
            failures.append("\(channel): \(error.localizedDescription)")
        }
    }

    private func sendTelegram(_ alert: Alert) async throws {
        guard let url = URL(string: "https://api.telegram.org/bot\(telegramBotToken)/sendMessage") else {
            throw SpeedTestError(message: String(localized: "The bot token is not valid."))
        }
        try await post(url, json: ["chat_id": telegramChatID, "text": "\(alert.title)\n\(alert.body)"])
    }

    /// Publishes as JSON to the server root, which keeps non-ASCII titles intact.
    private func sendNtfy(_ alert: Alert) async throws {
        guard let topicURL = URL(string: ntfyURL), let scheme = topicURL.scheme, let host = topicURL.host(), !topicURL.lastPathComponent.isEmpty, topicURL.lastPathComponent != "/" else {
            throw SpeedTestError(message: String(localized: "Use a topic URL such as https://ntfy.sh/my-topic."))
        }
        var root = URLComponents()
        root.scheme = scheme
        root.host = host
        root.port = topicURL.port
        guard let url = root.url else { return }
        try await post(url, json: ["topic": topicURL.lastPathComponent, "title": alert.title, "message": alert.body, "tags": "satellite"])
    }

    private func sendWebhook(result: SpeedTestResult?, alert: Alert?) async throws {
        guard let url = URL(string: webhookURL), url.scheme == "http" || url.scheme == "https" else {
            throw SpeedTestError(message: String(localized: "The webhook URL is not valid."))
        }
        let payload = WebhookPayload(
            event: result.map { $0.succeeded ? "test.completed" : "test.failed" } ?? "test.notification",
            alert: alert.map { WebhookPayload.AlertBody(title: $0.title, body: $0.body) },
            result: result
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try await post(url, body: encoder.encode(payload))
    }

    private func post(_ url: URL, json: [String: String]) async throws {
        try await post(url, body: JSONEncoder().encode(json))
    }

    private func post(_ url: URL, body: Data) async throws {
        var request = URLRequest(url: url, timeoutInterval: 20)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            let detail = String(decoding: data.prefix(200), as: UTF8.self)
            throw SpeedTestError(message: "HTTP \(http.statusCode) \(detail)")
        }
    }
}

struct WebhookPayload: Encodable {
    struct AlertBody: Encodable {
        let title: String
        let body: String
    }

    let event: String
    let alert: AlertBody?
    let result: SpeedTestResult?
}
