import Foundation

enum Format {
    static func mbps(_ value: Double?) -> String {
        guard let value else { return "—" }
        return value >= 100 ? String(format: "%.0f", value) : String(format: "%.1f", value)
    }

    static func milliseconds(_ value: Double?) -> String {
        guard let value else { return "—" }
        return String(format: "%.0f ms", value)
    }

    static func rpm(_ value: Double?) -> String {
        guard let value else { return "—" }
        return "\(Int(value.rounded())) RPM"
    }

    static func interval(minutes: Int) -> String {
        let duration: Duration = .seconds(minutes * 60)
        return duration.formatted(.units(allowed: [.hours, .minutes], width: .wide))
    }

    static func keepDays(_ days: Int) -> String {
        if days == 0 { return String(localized: "Forever") }
        if days % 365 == 0 { return String(localized: "\(days / 365) years") }
        return String(localized: "\(days) days")
    }
}
