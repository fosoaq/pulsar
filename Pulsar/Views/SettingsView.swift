import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var loginItemError: String?

    var body: some View {
        @Bindable var model = model

        Form {
            Section("Speed test") {
                Picker("Engine", selection: $model.settings.engine) {
                    ForEach(SpeedTestEngineKind.allCases) { kind in
                        Text(kind.title).tag(kind)
                    }
                }
                Text(engineNote)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if model.settings.engine == .ookla {
                    Toggle(isOn: $model.settings.acceptedOoklaLicense) {
                        Text("I accept the Speedtest license")
                        Text("Personal, non-commercial use only. Pulsar passes --accept-license and --accept-gdpr to the CLI on your behalf.")
                    }
                    HStack(spacing: 12) {
                        Link("EULA", destination: URL(string: "https://www.speedtest.net/about/eula")!)
                        Link("Terms of Use", destination: URL(string: "https://www.speedtest.net/about/terms")!)
                        Link("Privacy Policy", destination: URL(string: "https://www.speedtest.net/about/privacy")!)
                    }
                    .font(.caption)
                }

                Picker("Run a test every", selection: $model.settings.intervalMinutes) {
                    ForEach(AppSettings.intervalChoices, id: \.self) { minutes in
                        Text(Format.interval(minutes: minutes)).tag(minutes)
                    }
                }
                Toggle("Keep the Mac awake for scheduled tests", isOn: $model.settings.preventSleep)
                Text("Stops idle sleep while Pulsar runs. The display still turns off.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Notifications") {
                Toggle("Notify when a test fails", isOn: $model.settings.notifyOnFailure)
                TextField("Notify when download is below, Mbps", value: nonNegative($model.settings.minDownloadMbps), format: .number)
                TextField("Notify when upload is below, Mbps", value: nonNegative($model.settings.minUploadMbps), format: .number)
                Text("0 turns a threshold off.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Dashboard") {
                Toggle("Serve a dashboard on the local network", isOn: $model.settings.dashboardEnabled)
                TextField("Port", value: validPort($model.settings.dashboardPort), format: .number.grouping(.never))
                    .disabled(!model.settings.dashboardEnabled)
                ForEach(model.dashboardURLs, id: \.self) { url in
                    Link(url.absoluteString, destination: url)
                }
                if model.settings.dashboardEnabled {
                    Text("The .local name is this Mac's Local hostname from System Settings → General → Sharing. Use the IP address on devices that cannot open .local names.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let error = model.dashboardError {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }

            Section("General") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in
                        setLaunchAtLogin(enabled)
                    }
                if let loginItemError {
                    Text(loginItemError)
                        .foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 480)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var engineNote: String {
        switch model.settings.engine {
        case .networkQuality:
            "Built into macOS. Measures against Apple's servers, including responsiveness under load."
        case .ookla:
            OoklaEngine.executablePath == nil
                ? "Not installed. Run: brew install teamookla/speedtest/speedtest"
                : "Measures against the nearest Speedtest.net server, like speedtest-tracker."
        }
    }

    private func nonNegative(_ binding: Binding<Double>) -> Binding<Double> {
        Binding(get: { binding.wrappedValue }, set: { binding.wrappedValue = max(0, $0) })
    }

    private func validPort(_ binding: Binding<Int>) -> Binding<Int> {
        Binding(get: { binding.wrappedValue }, set: { if (1024...65535).contains($0) { binding.wrappedValue = $0 } })
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        guard enabled != (SMAppService.mainApp.status == .enabled) else { return }
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            loginItemError = nil
        } catch {
            loginItemError = error.localizedDescription
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}
