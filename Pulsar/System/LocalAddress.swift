import Darwin

/// This Mac's IPv4 address on the local network and the interface that carries it.
struct LocalAddress: Equatable, Sendable {
    let ip: String
    let interface: String

    /// The first IPv4 address on an Ethernet or Wi-Fi interface.
    static func current() -> LocalAddress? {
        var list: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&list) == 0, let first = list else { return nil }
        defer { freeifaddrs(list) }
        for entry in sequence(first: first, next: { $0.pointee.ifa_next }) {
            let flags = Int32(entry.pointee.ifa_flags)
            let interface = String(cString: entry.pointee.ifa_name)
            guard let address = entry.pointee.ifa_addr,
                  address.pointee.sa_family == UInt8(AF_INET),
                  flags & IFF_UP != 0, flags & IFF_LOOPBACK == 0,
                  interface.hasPrefix("en")
            else { continue }
            var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            if getnameinfo(address, socklen_t(address.pointee.sa_len), &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST) == 0 {
                return LocalAddress(ip: host.withUnsafeBufferPointer { String(cString: $0.baseAddress!) }, interface: interface)
            }
        }
        return nil
    }
}
