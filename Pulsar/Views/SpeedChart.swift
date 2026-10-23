import Charts
import SwiftUI

/// Download and upload over time; failed runs are left out.
struct SpeedChart: View {
    let results: [SpeedTestResult]
    var compact = false

    var body: some View {
        Chart {
            ForEach(results.filter(\.succeeded), id: \.date) { result in
                if let download = result.downloadMbps {
                    LineMark(x: .value("Time", result.date), y: .value("Mbps", download), series: .value("Direction", "Download"))
                        .foregroundStyle(by: .value("Direction", "Download"))
                }
                if let upload = result.uploadMbps {
                    LineMark(x: .value("Time", result.date), y: .value("Mbps", upload), series: .value("Direction", "Upload"))
                        .foregroundStyle(by: .value("Direction", "Upload"))
                }
            }
        }
        .chartForegroundStyleScale(["Download": Color.blue, "Upload": Color.orange])
        .chartLegend(compact ? .hidden : .visible)
        .chartXAxis(compact ? .hidden : .automatic)
        .chartYAxisLabel(compact ? "" : "Mbps")
    }
}
