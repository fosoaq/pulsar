import Foundation

/// Looks for a newer release on GitHub. Pulsar is not signed with a Developer ID,
/// so it points to the release page instead of installing updates itself.
struct UpdateChecker: Sendable {
    struct Release: Equatable, Sendable {
        let version: String
        let url: URL
    }

    static let latestReleaseURL = URL(string: "https://api.github.com/repos/fosoaq/pulsar/releases/latest")!

    var currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"

    /// The latest release when it is newer than this build, nil otherwise.
    func check() async throws -> Release? {
        var request = URLRequest(url: Self.latestReleaseURL, timeoutInterval: 20)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: request)
        // 404 until the first release is published.
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        let latest = try JSONDecoder().decode(GitHubRelease.self, from: data)
        guard Self.isVersion(latest.tagName, newerThan: currentVersion), let url = URL(string: latest.htmlURL) else { return nil }
        return Release(version: Self.trimmed(latest.tagName), url: url)
    }

    static func isVersion(_ candidate: String, newerThan current: String) -> Bool {
        let a = components(candidate), b = components(current)
        for index in 0..<max(a.count, b.count) {
            let x = index < a.count ? a[index] : 0, y = index < b.count ? b[index] : 0
            if x != y { return x > y }
        }
        return false
    }

    private static func trimmed(_ tag: String) -> String {
        tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
    }

    private static func components(_ version: String) -> [Int] {
        trimmed(version).split(separator: ".").map { Int($0.prefix { $0.isNumber }) ?? 0 }
    }

    private struct GitHubRelease: Decodable {
        let tagName: String
        let htmlURL: String

        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
            case htmlURL = "html_url"
        }
    }
}
