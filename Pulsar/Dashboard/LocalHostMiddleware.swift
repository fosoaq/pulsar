import Foundation
import Hummingbird

/// Rejects requests whose Host is not `localhost`, a `.local` name or an IP address.
///
/// The dashboard listens on every interface, so a web page on any machine in the network
/// could otherwise rebind its own domain to this Mac's address and read the history.
/// Such a request still carries the attacker's domain in Host, which is what this checks.
struct LocalHostMiddleware<Context: RequestContext>: RouterMiddleware {
    func handle(_ request: Request, context: Context, next: (Request, Context) async throws -> Response) async throws -> Response {
        guard let authority = request.head.authority, Self.isLocal(authority: authority) else {
            return Response(status: .misdirectedRequest)
        }
        return try await next(request, context)
    }

    static func isLocal(authority: String) -> Bool {
        let host: Substring
        if authority.hasPrefix("[") {
            // [IPv6]:port
            guard let end = authority.firstIndex(of: "]") else { return false }
            host = authority[authority.index(after: authority.startIndex)..<end]
            var address = in6_addr()
            return inet_pton(AF_INET6, String(host), &address) == 1
        }
        host = authority.split(separator: ":", maxSplits: 1).first ?? ""
        let name = host.lowercased()
        if name == "localhost" || name.hasSuffix(".local") {
            return true
        }
        var address = in_addr()
        return inet_pton(AF_INET, name, &address) == 1
    }
}
