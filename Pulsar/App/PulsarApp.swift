import SwiftUI

@main
struct PulsarApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        MenuBarExtra {
            MenuContentView()
                .environment(model)
        } label: {
            Image(systemName: model.isRunning ? "gauge.with.dots.needle.bottom.50percent" : "gauge.with.dots.needle.67percent")
        }
        .menuBarExtraStyle(.window)

        Window("History", id: "history") {
            HistoryView()
                .environment(model)
        }
        .defaultSize(width: 820, height: 560)

        Settings {
            SettingsView()
                .environment(model)
        }
    }
}
