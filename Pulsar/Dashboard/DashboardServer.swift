import Foundation
import Hummingbird

/// What the dashboard can ask of the app.
struct DashboardControls: Sendable {
    struct Status: Encodable, Sendable {
        let running: Bool
        let paused: Bool
        let nextRun: Date
        let engine: String
        let serverID: Int?
        let minDownloadMbps: Double
        let minUploadMbps: Double
        let hostName: String
        let version: String
    }

    /// Starts a test, on the given Ookla server if any; false when one is running already or tests are paused.
    let runTest: @MainActor @Sendable (Int?) -> Bool
    let status: @MainActor @Sendable () -> Status
    /// Nearby Ookla servers; empty for networkQuality.
    let servers: @MainActor @Sendable () async -> [OoklaServer]
}

/// Serves the dashboard page, a JSON API, CSV export and Prometheus metrics on every interface.
@MainActor
final class DashboardServer {
    /// Browsers only send this header from the dashboard's own origin: another site
    /// would need a CORS preflight, which the server never approves. That keeps a page
    /// elsewhere from starting tests with a plain form or fetch.
    nonisolated static let runHeader = "X-Pulsar-Run"

    private var task: Task<Void, Never>?

    func start(port: Int, store: ResultStore, controls: DashboardControls, onError: @escaping @MainActor @Sendable (String) -> Void) {
        let previous = task
        previous?.cancel()
        task = Task.detached {
            // Let the previous server release the port before binding it again.
            await previous?.value
            guard !Task.isCancelled else { return }

            let router = Router()
            router.add(middleware: LocalHostMiddleware())
            router.get("/") { _, _ in
                Response(
                    status: .ok,
                    headers: [.contentType: "text/html; charset=utf-8"],
                    body: .init(byteBuffer: ByteBuffer(string: DashboardPage.html))
                )
            }
            router.get("/api/results") { request, _ in
                try Self.json(store.results(since: Self.start(request)))
            }
            router.get("/api/results.csv") { request, _ in
                let csv = try DashboardFormats.csv(store.results(since: Self.start(request)))
                return Response(
                    status: .ok,
                    headers: [
                        .contentType: "text/csv; charset=utf-8",
                        .contentDisposition: "attachment; filename=\"pulsar-results.csv\"",
                    ],
                    body: .init(byteBuffer: ByteBuffer(string: csv))
                )
            }
            router.get("/api/latest") { _, _ in
                let results = try store.results(since: .now.addingTimeInterval(-365 * 86_400))
                return try Self.json(results.first(where: \.succeeded))
            }
            router.get("/api/status") { _, _ in
                try await Self.json(controls.status())
            }
            router.post("/api/run") { request, _ in
                guard request.headers.contains(where: { $0.name.canonicalName == Self.runHeader.lowercased() }) else {
                    return Response(status: .forbidden)
                }
                let serverID = request.uri.queryParameters.get("server", as: Int.self)
                return await controls.runTest(serverID) ? Response(status: .accepted) : Response(status: .conflict)
            }
            router.get("/api/servers") { _, _ in
                try await Self.json(controls.servers())
            }
            router.get("/metrics") { _, _ in
                let results = try store.results(since: .now.addingTimeInterval(-365 * 86_400))
                let text = DashboardFormats.metrics(latest: results.first, lastSuccess: results.first(where: \.succeeded))
                return Response(
                    status: .ok,
                    headers: [.contentType: "text/plain; version=0.0.4; charset=utf-8"],
                    body: .init(byteBuffer: ByteBuffer(string: text))
                )
            }

            let app = Application(
                router: router,
                configuration: .init(address: .hostname("0.0.0.0", port: port), serverName: "Pulsar")
            )
            do {
                try await app.run()
            } catch is CancellationError {
            } catch {
                await onError(String(localized: "Dashboard could not start on port \(port): \(error.localizedDescription)"))
            }
        }
    }

    func stop() {
        task?.cancel()
    }

    /// `?days=` clamped to a year, 7 by default.
    private nonisolated static func start(_ request: Request) -> Date {
        let days = min(max(request.uri.queryParameters.get("days", as: Int.self) ?? 7, 1), 365)
        return .now.addingTimeInterval(-Double(days) * 86_400)
    }

    private nonisolated static func json(_ value: some Encodable) throws -> Response {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(value)
        return Response(
            status: .ok,
            headers: [.contentType: "application/json; charset=utf-8", .cacheControl: "no-store"],
            body: .init(byteBuffer: ByteBuffer(bytes: data))
        )
    }
}
