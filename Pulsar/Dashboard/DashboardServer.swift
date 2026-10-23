import Foundation
import Hummingbird

/// Serves the dashboard page and a read-only JSON API on every interface.
@MainActor
final class DashboardServer {
    private var task: Task<Void, Never>?

    func start(port: Int, store: ResultStore, onError: @escaping @MainActor @Sendable (String) -> Void) {
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
                let days = min(max(request.uri.queryParameters.get("days", as: Int.self) ?? 7, 1), 365)
                let results = try store.results(since: .now.addingTimeInterval(-Double(days) * 86_400))
                return try Self.json(results)
            }
            router.get("/api/latest") { _, _ in
                let results = try store.results(since: .now.addingTimeInterval(-365 * 86_400))
                return try Self.json(results.first(where: \.succeeded))
            }

            let app = Application(
                router: router,
                configuration: .init(address: .hostname("0.0.0.0", port: port), serverName: "Pulsar")
            )
            do {
                try await app.run()
            } catch is CancellationError {
            } catch {
                await onError("Dashboard could not start on port \(port): \(error.localizedDescription)")
            }
        }
    }

    func stop() {
        task?.cancel()
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
