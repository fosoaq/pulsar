import dnssd
import Foundation

/// Publishes `<name>.local` over Bonjour, so the dashboard has an address of its own
/// that does not depend on the Mac's Local hostname.
@MainActor
final class HostnameAdvertiser {
    /// Called when another device already answers for the name.
    var onError: ((String) -> Void)?

    private var connection: DNSServiceRef?
    private var published: (name: String, address: LocalAddress)?

    /// Publishes, moves or withdraws the record; does nothing when nothing changed.
    func update(name: String?, address: LocalAddress?) {
        guard name != published?.name || address != published?.address else { return }
        stop()
        guard let name, let address else { return }

        var ipv4 = in_addr()
        guard inet_pton(AF_INET, address.ip, &ipv4) == 1 else { return }
        var ref: DNSServiceRef?
        guard DNSServiceCreateConnection(&ref) == DNSServiceErrorType(kDNSServiceErr_NoError), let ref else {
            onError?("Bonjour is not available, so \(name).local could not be published.")
            return
        }
        DNSServiceSetDispatchQueue(ref, .main)

        var record: DNSRecordRef?
        let status = withUnsafeBytes(of: &ipv4) { bytes in
            DNSServiceRegisterRecord(
                ref,
                &record,
                DNSServiceFlags(kDNSServiceFlagsUnique),
                if_nametoindex(address.interface),
                "\(name).local.",
                UInt16(kDNSServiceType_A),
                UInt16(kDNSServiceClass_IN),
                UInt16(bytes.count),
                bytes.baseAddress,
                120,
                { _, _, _, error, context in
                    guard let context, error != DNSServiceErrorType(kDNSServiceErr_NoError) else { return }
                    let advertiser = Unmanaged<HostnameAdvertiser>.fromOpaque(context).takeUnretainedValue()
                    // The connection delivers on the main queue.
                    MainActor.assumeIsolated { advertiser.failed(error) }
                },
                Unmanaged.passUnretained(self).toOpaque()
            )
        }
        guard status == DNSServiceErrorType(kDNSServiceErr_NoError) else {
            DNSServiceRefDeallocate(ref)
            failed(status, name: name)
            return
        }
        connection = ref
        published = (name, address)
    }

    func stop() {
        if let connection {
            DNSServiceRefDeallocate(connection)
        }
        connection = nil
        published = nil
    }

    private func failed(_ error: DNSServiceErrorType, name: String? = nil) {
        let name = name ?? published?.name ?? "The name"
        stop()
        if error == DNSServiceErrorType(kDNSServiceErr_NameConflict) {
            onError?("\(name).local is already used by another device on the network. Pick another name.")
        } else {
            onError?("Could not publish \(name).local (Bonjour error \(error)).")
        }
    }
}
