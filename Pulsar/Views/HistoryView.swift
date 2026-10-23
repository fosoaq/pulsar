import SwiftUI

struct HistoryView: View {
    @Environment(AppModel.self) private var model
    @State private var range = HistoryRange.week

    var body: some View {
        let start = Date.now.addingTimeInterval(-range.duration)
        let results = model.recent.filter { $0.date >= start }

        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Picker("Range", selection: $range) {
                    ForEach(HistoryRange.allCases) { range in
                        Text(range.title).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 240)

                Spacer()

                Button("Run Test Now", systemImage: "play.fill") {
                    model.runNow()
                }
                .disabled(model.isRunning || model.needsOoklaLicense)
            }

            if results.contains(where: \.succeeded) {
                SpeedChart(results: results)
                    .frame(height: 220)
            } else {
                ContentUnavailableView("No measurements in this range", systemImage: "chart.xyaxis.line")
                    .frame(height: 220)
            }

            Table(results) {
                TableColumn("Time") { result in
                    Text(result.date, format: .dateTime.day().month().hour().minute())
                }
                TableColumn("Download") { result in
                    Text(result.downloadMbps.map { "\(Format.mbps($0)) Mbps" } ?? "—")
                        .monospacedDigit()
                }
                TableColumn("Upload") { result in
                    Text(result.uploadMbps.map { "\(Format.mbps($0)) Mbps" } ?? "—")
                        .monospacedDigit()
                }
                TableColumn("Latency") { result in
                    Text(Format.milliseconds(result.latencyMs))
                        .monospacedDigit()
                }
                TableColumn("Engine") { result in
                    Text(SpeedTestEngineKind(rawValue: result.engine)?.title ?? result.engine)
                }
                TableColumn("Status") { result in
                    if let error = result.error {
                        Text(error)
                            .foregroundStyle(.red)
                            .help(error)
                    } else {
                        Text("OK")
                    }
                }
            }
        }
        .padding()
        .frame(minWidth: 640, minHeight: 440)
    }
}

enum HistoryRange: CaseIterable, Identifiable {
    case day, week, month

    var id: Self { self }

    var title: LocalizedStringKey {
        switch self {
        case .day: "24 hours"
        case .week: "7 days"
        case .month: "30 days"
        }
    }

    var duration: TimeInterval {
        switch self {
        case .day: 86_400
        case .week: 7 * 86_400
        case .month: 30 * 86_400
        }
    }
}
