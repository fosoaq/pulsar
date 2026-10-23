import SwiftUI

struct MenuContentView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            if let result = model.lastSuccess {
                metrics(result)
            } else if !model.isRunning {
                Text("No measurements yet.")
                    .foregroundStyle(.secondary)
            }

            if let error = model.latest?.error {
                warning(error)
            }
            if let error = model.storeError {
                warning(error)
            }

            let lastDay = model.recent.filter { $0.date > .now.addingTimeInterval(-86_400) }
            if lastDay.contains(where: \.succeeded) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Last 24 hours")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    SpeedChart(results: lastDay, compact: true)
                        .frame(height: 70)
                }
            }

            Divider()
            actions
        }
        .padding(14)
        .frame(width: 320)
    }

    private var header: some View {
        HStack {
            Text("Pulsar")
                .font(.headline)
            Spacer()
            if model.isRunning {
                ProgressView()
                    .controlSize(.small)
                Text("Testing…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Next test \(model.nextRunDate, style: .relative)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func metrics(_ result: SpeedTestResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 8) {
                GridRow {
                    metric("Download", systemImage: "arrow.down", value: Format.mbps(result.downloadMbps), unit: "Mbps")
                    metric("Upload", systemImage: "arrow.up", value: Format.mbps(result.uploadMbps), unit: "Mbps")
                }
                GridRow {
                    metric("Latency", systemImage: "timer", value: Format.milliseconds(result.latencyMs), unit: nil)
                    if let rpm = result.responsivenessRPM {
                        metric("Responsiveness", systemImage: "waveform.path.ecg", value: Format.rpm(rpm), unit: nil)
                    } else {
                        metric("Jitter", systemImage: "waveform.path", value: Format.milliseconds(result.jitterMs), unit: nil)
                    }
                }
            }
            Text("Measured \(result.date, style: .relative) ago")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func metric(_ title: String, systemImage: String, value: String, unit: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Label(title, systemImage: systemImage)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.title3.weight(.semibold).monospacedDigit())
                if let unit {
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func warning(_ text: String) -> some View {
        Label(text, systemImage: "exclamationmark.triangle.fill")
            .font(.callout)
            .foregroundStyle(.red)
            .lineLimit(4)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var actions: some View {
        VStack(alignment: .leading, spacing: 2) {
            MenuRow("Run Test Now", systemImage: "play.fill") {
                model.runNow()
            }
            .disabled(model.isRunning)

            if let url = model.dashboardURL {
                MenuRow("Open Dashboard", systemImage: "globe", detail: url.host()) {
                    NSWorkspace.shared.open(url)
                }
            }
            MenuRow("History…", systemImage: "chart.xyaxis.line") {
                openWindow(id: "history")
                NSApp.activate()
            }
            MenuRow("Settings…", systemImage: "gearshape") {
                openSettings()
                NSApp.activate()
            }

            Divider()
                .padding(.vertical, 4)

            MenuRow("Quit Pulsar", systemImage: "power") {
                NSApp.terminate(nil)
            }
        }
    }
}

/// A full-width row that highlights on hover, like a menu item.
private struct MenuRow: View {
    let title: String
    let systemImage: String
    var detail: String?
    let action: () -> Void

    @State private var isHovered = false
    @Environment(\.isEnabled) private var isEnabled

    init(_ title: String, systemImage: String, detail: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.detail = detail
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack {
                Label(title, systemImage: systemImage)
                Spacer()
                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered && isEnabled ? Color.primary.opacity(0.08) : .clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
