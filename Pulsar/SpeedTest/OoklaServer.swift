import Foundation

/// A Speedtest.net server as `speedtest --servers` lists it.
struct OoklaServer: Codable, Equatable, Hashable, Identifiable, Sendable {
    let id: Int
    let name: String
    let location: String?
    let country: String?
    let host: String?

    var title: String {
        [name, location].compactMap { $0 }.joined(separator: ", ")
    }
}
