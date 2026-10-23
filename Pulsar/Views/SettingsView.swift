import ServiceManagement
import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            TestingSettings()
                .tabItem { Label("Testing", systemImage: "gauge.with.dots.needle.67percent") }
            NotificationSettings()
                .tabItem { Label("Notifications", systemImage: "bell.badge") }
            DashboardSettings()
                .tabItem { Label("Dashboard", systemImage: "globe") }
            GeneralSettings()
                .tabItem { Label("General", systemImage: "gearshape") }
        }
        .frame(width: 500)
    }
}

private struct TestingSettings: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model

        Form {
            Section {
                Picker("Engine", selection: $model.settings.engine) {
                    ForEach(SpeedTestEngineKind.allCases) { kind in
                        Text(kind.title).tag(kind)
                    }
                }
                Caption(verbatim: engineNote)

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
            }

            if model.settings.engine == .ookla, OoklaEngine.executablePath != nil {
                Section {
                    HStack {
                        Picker("Server", selection: serverSelection) {
                            Text("Automatic (nearest)").tag(Int?.none)
                            if let id = model.settings.ooklaServerID, !model.ooklaServers.contains(where: { $0.id == id }) {
                                Text(model.settings.ooklaServerName.isEmpty ? "#\(id)" : model.settings.ooklaServerName).tag(Int?.some(id))
                            }
                            ForEach(model.ooklaServers) { server in
                                Text(server.title).tag(Int?.some(server.id))
                            }
                        }
                        Button {
                            Task { await model.loadOoklaServers(refresh: true) }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .buttonStyle(.borderless)
                        .help("Reload the server list")
                    }
                    if let error = model.ooklaServersError {
                        Text(error)
                            .foregroundStyle(.red)
                    } else {
                        Caption("Scheduled tests use this server. A test started from the dashboard can pick another one.")
                    }
                }
                .task {
                    await model.loadOoklaServers()
                }
            }

            Section {
                Picker("Run a test every", selection: $model.settings.intervalMinutes) {
                    ForEach(AppSettings.intervalChoices, id: \.self) { minutes in
                        Text(Format.interval(minutes: minutes)).tag(minutes)
                    }
                }
                Caption("After a failed test Pulsar tries again in \(AppModel.retryMinutes) minutes.")
                Toggle("Keep the Mac awake for scheduled tests", isOn: $model.settings.preventSleep)
                Caption("Stops idle sleep while Pulsar runs. The display still turns off.")
            }

            Section {
                Picker("Keep history for", selection: $model.settings.keepDays) {
                    ForEach(AppSettings.keepDaysChoices, id: \.self) { days in
                        Text(Format.keepDays(days)).tag(days)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var serverSelection: Binding<Int?> {
        Binding(
            get: { model.settings.ooklaServerID },
            set: { id in
                model.settings.ooklaServerID = id
                model.settings.ooklaServerName = model.ooklaServers.first { $0.id == id }?.title ?? ""
            }
        )
    }

    private var engineNote: String {
        switch model.settings.engine {
        case .networkQuality:
            String(localized: "Built into macOS. Measures against Apple's servers, including responsiveness under load.")
        case .ookla:
            OoklaEngine.executablePath == nil
                ? String(localized: "Not installed. Run: brew install teamookla/speedtest/speedtest")
                : String(localized: "Measures against the nearest Speedtest.net server.")
        }
    }
}

private struct NotificationSettings: View {
    @Environment(AppModel.self) private var model
    @State private var isSending = false

    var body: some View {
        @Bindable var model = model

        Form {
            Section("When to notify") {
                Toggle("When a test fails", isOn: $model.settings.notifyOnFailure)
                TextField("When download is below, Mbps", value: nonNegative($model.settings.minDownloadMbps), format: .number)
                TextField("When upload is below, Mbps", value: nonNegative($model.settings.minUploadMbps), format: .number)
                Caption("0 turns a threshold off. Alerts always appear in Notification Center on this Mac.")
            }

            Section("Telegram") {
                SecureField("Bot token", text: $model.settings.telegramBotToken, prompt: Text("123456:ABC…"))
                TextField("Chat ID", text: $model.settings.telegramChatID, prompt: Text("123456789"))
                Caption("Create a bot with @BotFather, send it any message, then find your chat ID with @userinfobot.")
            }

            Section("ntfy") {
                TextField("Topic URL", text: $model.settings.ntfyURL, prompt: Text("https://ntfy.sh/my-pulsar"))
                Caption("Subscribe to the same topic in the ntfy app on your phone.")
            }

            Section("Webhook") {
                TextField("URL", text: $model.settings.webhookURL, prompt: Text("https://example.com/hook"))
                Caption("Receives every result as JSON, with an alert attached when one applies.")
            }

            Section {
                HStack {
                    Button("Send Test Notification") {
                        isSending = true
                        Task {
                            await model.sendTestNotification()
                            isSending = false
                        }
                    }
                    .disabled(isSending)
                    if isSending {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
                if let error = model.deliveryError {
                    Text(error)
                        .foregroundStyle(.red)
                        .textSelection(.enabled)
                }
            }
        }
        .formStyle(.grouped)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func nonNegative(_ binding: Binding<Double>) -> Binding<Double> {
        Binding(get: { binding.wrappedValue }, set: { binding.wrappedValue = max(0, $0) })
    }
}

private struct DashboardSettings: View {
    @Environment(AppModel.self) private var model
    @State private var hostnameDraft: String?

    var body: some View {
        @Bindable var model = model

        Form {
            Section {
                Toggle("Serve a dashboard on the local network", isOn: $model.settings.dashboardEnabled)
                LabeledContent("Address") {
                    HStack(spacing: 2) {
                        TextField("Address", text: hostnameField, prompt: Text("pulsar"))
                            .labelsHidden()
                            .multilineTextAlignment(.trailing)
                            .onSubmit(applyHostname)
                        Text(".local")
                            .foregroundStyle(.secondary)
                    }
                }
                .disabled(!model.settings.dashboardEnabled)
                TextField("Port", value: validPort($model.settings.dashboardPort), format: .number.grouping(.never))
                    .disabled(!model.settings.dashboardEnabled)
                Caption("Press Return to apply the address. Port 80 drops the port from the address. Leave the address empty to use this Mac's name.")
            }

            Section {
                if let url = model.dashboardURL {
                    Link(url.absoluteString, destination: url)
                }
                if let url = model.dashboardIPURL {
                    Text("On devices that cannot open .local names: \(url.absoluteString)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
                if let url = model.dashboardIPURL?.appending(path: "metrics") {
                    Text("Prometheus metrics: \(url.absoluteString)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
                if let error = model.dashboardError {
                    Text(error)
                        .foregroundStyle(.red)
                }
                if let error = model.hostnameError {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func validPort(_ binding: Binding<Int>) -> Binding<Int> {
        Binding(get: { binding.wrappedValue }, set: { if (1...65535).contains($0) { binding.wrappedValue = $0 } })
    }

    /// Edits a draft so the name is not republished on every keystroke.
    private var hostnameField: Binding<String> {
        Binding(
            get: { hostnameDraft ?? model.settings.dashboardHostname },
            set: { hostnameDraft = AppSettings.sanitizedHostname($0) }
        )
    }

    private func applyHostname() {
        guard let hostnameDraft else { return }
        model.settings.dashboardHostname = hostnameDraft.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        self.hostnameDraft = nil
    }
}

private struct GeneralSettings: View {
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var loginItemError: String?
    @State private var language = AppLanguage.current
    private let launchLanguage = AppLanguage.current

    var body: some View {
        Form {
            Section {
                Picker("Language", selection: $language) {
                    Text("System").tag(AppLanguage.system)
                    Text(verbatim: "English").tag(AppLanguage.english)
                    Text(verbatim: "Русский").tag(AppLanguage.russian)
                }
                .onChange(of: language) { _, newValue in
                    newValue.save()
                }
                if language != launchLanguage {
                    HStack {
                        Caption("Relaunch Pulsar to switch the language.")
                        Spacer()
                        Button("Relaunch Now", action: AppLanguage.relaunch)
                    }
                }
            }

            Section {
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
        .fixedSize(horizontal: false, vertical: true)
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

private struct Caption: View {
    let text: Text

    init(_ key: LocalizedStringKey) {
        text = Text(key)
    }

    init(verbatim string: String) {
        text = Text(string)
    }

    var body: some View {
        text
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}
