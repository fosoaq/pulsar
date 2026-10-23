import Charts
import SwiftUI

/// Download and upload over time; failed runs are left out.
struct SpeedChart: View {
    let results: [SpeedTestResult]
    var compact = false

    private static let download = String(localized: "Download")
    private static let upload = String(localized: "Upload")

    var body: some View {
        Chart {
            ForEach(results.filter(\.succeeded), id: \.date) { result in
                if let download = result.downloadMbps {
                    LineMark(x: .value("Time", result.date), y: .value("Mbps", download), series: .value("Direction", Self.download))
                        .foregroundStyle(by: .value("Direction", Self.download))
                }
                if let upload = result.uploadMbps {
                    LineMark(x: .value("Time", result.date), y: .value("Mbps", upload), series: .value("Direction", Self.upload))
                        .foregroundStyle(by: .value("Direction", Self.upload))
                }
            }
        }
        .chartForegroundStyleScale([Self.download: Color.blue, Self.upload: Color.orange])
        .chartLegend(compact ? .hidden : .visible)
        .chartXAxis(compact ? .hidden : .automatic)
        .chartYAxisLabel(compact ? "" : "Mbps")
    }
}
