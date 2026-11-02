//
//  TramontanaPlan.swift
//  Finlark
//
//  FIN-9 Plan "Tramontana": the month as a line. A chart follows spending day by day up to
//  today, a dashed line carries on to the projection at month end, and a rule marks the planned total,
//  so whether the month lands under or over the plan is a shape (PLN-003). The categories follow.
//

#if DEBUG
import Charts
import SwiftUI

struct TramontanaPlan: View {
    @Bindable var store: PLStore

    private var code: String { store.code }

    var body: some View {
        let report = store.report

        ScrollView {
            VStack(alignment: .leading, spacing: hmTileSpacing) {
                if report.hasPlan {
                    HMTile(padding: 18) {
                        VStack(alignment: .leading, spacing: 14) {
                            VStack(alignment: .leading, spacing: 6) {
                                PLPaceSentence(report: report, code: code)
                                    .font(.title3.weight(.semibold))
                                if let status = report.status {
                                    PLStatusLabel(status: status)
                                        .font(.subheadline.weight(.semibold))
                                }
                            }
                            .accessibilityElement(children: .combine)
                            TramontanaChart(report: report, code: code)
                            PLFigures(report: report, code: code)
                        }
                        .monospacedDigit()
                    }
                    HMTile(padding: 18) {
                        VStack(alignment: .leading, spacing: 14) {
                            HMTileHeader(title: "Categories", symbol: "square.grid.2x2.fill")
                            ForEach(report.entries) { entry in
                                PLEntryRow(entry: entry, code: code)
                                if entry.id != report.entries.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                } else {
                    PLInvite(store: store)
                }
                PLUnplannedTile(report: report, code: code)
                if report.hasPlan {
                    PLFootnote(report: report, code: code)
                        .padding(.horizontal, 4)
                }
            }
            .padding()
        }
        .background { HMBackdrop() }
        .plChrome(store: store)
    }
}

/// Spending so far, the projection to month end and the planned total.
private struct TramontanaChart: View {
    let report: PLReport
    let code: String

    @ScaledMetric(relativeTo: .body) private var height: CGFloat = 180

    private struct Point: Identifiable {
        let day: Int
        let value: Double
        var id: Int { day }
    }

    /// A mock day-by-day path that ends at what was spent. Rent and bills land early in the month.
    /// Doubles for drawing only (NFR-005).
    private var points: [Point] {
        let weights: [Double] = [9, 1, 2, 1, 0, 3, 2, 1, 0, 2, 3, 1, 2, 0, 1, 4, 2, 3, 1, 2, 0, 2, 1, 3, 1, 0, 2, 1, 3, 2, 1]
        let days = report.dayOfMonth
        let used = weights.prefix(days)
        let sum = used.reduce(0, +)
        let total = report.spent.plotValue
        var running = 0.0
        return [Point(day: 0, value: 0)] + used.enumerated().map { index, weight in
            running += sum > 0 ? total * weight / sum : 0
            return Point(day: index + 1, value: running)
        }
    }

    var body: some View {
        let tint = report.status?.tint ?? .accentColor

        Chart {
            ForEach(points) { point in
                AreaMark(x: .value("Day", point.day), y: .value("Spent", point.value))
                    .foregroundStyle(tint.opacity(0.15).gradient)
                    .interpolationMethod(.monotone)
                LineMark(x: .value("Day", point.day), y: .value("Spent", point.value), series: .value("Line", "Spent"))
                    .foregroundStyle(tint)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                    .interpolationMethod(.monotone)
            }

            if let projected = report.projected {
                ForEach([
                    Point(day: report.dayOfMonth, value: report.spent.plotValue),
                    Point(day: report.daysInMonth, value: projected.plotValue),
                ]) { point in
                    LineMark(x: .value("Day", point.day), y: .value("Spent", point.value), series: .value("Line", "Projected"))
                        .foregroundStyle(tint.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [5, 5]))
                }
                PointMark(x: .value("Day", report.daysInMonth), y: .value("Spent", projected.plotValue))
                    .foregroundStyle(tint)
                RuleMark(x: .value("Day", report.dayOfMonth))
                    .foregroundStyle(Color.secondary.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 1))
            }

            RuleMark(y: .value("Planned", report.planned.plotValue))
                .foregroundStyle(Color.primary)
                .lineStyle(StrokeStyle(lineWidth: 2))
        }
        .chartXScale(domain: 0...report.daysInMonth)
        .chartXAxis {
            AxisMarks(preset: .aligned, values: axisDays) { value in
                AxisValueLabel {
                    if let day = value.as(Int.self) {
                        if report.isCurrent, day == report.dayOfMonth {
                            Text("Today")
                        } else {
                            Text(day, format: .number)
                        }
                    }
                }
            }
        }
        .chartYAxis(.hidden)
        .frame(height: height)
        .accessibilityElement()
        .accessibilityLabel(Text("Spending through the month"))
        .accessibilityValue(accessibilityValue)
    }

    /// The first and last day, and today in the current month.
    private var axisDays: [Int] {
        guard report.isCurrent else { return [1, report.daysInMonth] }
        // Early in the month "1" would crowd "Today".
        return report.dayOfMonth < 5 ? [report.dayOfMonth, report.daysInMonth] : [1, report.dayOfMonth, report.daysInMonth]
    }

    private var accessibilityValue: Text {
        if let projected = report.projected {
            Text("\(report.spent, format: .currency(code: code)) spent by day \(report.dayOfMonth), heading for \(projected, format: .currency(code: code)), with \(report.planned, format: .currency(code: code)) planned")
        } else {
            Text("\(report.spent, format: .currency(code: code)) spent, with \(report.planned, format: .currency(code: code)) planned")
        }
    }
}

#Preview("Tramontana") {
    PLHost { TramontanaPlan(store: $0) }
}

#Preview("Tramontana · Last month") {
    PLHost(store: .lastMonth) { TramontanaPlan(store: $0) }
}

#Preview("Tramontana · Early month") {
    PLHost(store: .earlyMonth) { TramontanaPlan(store: $0) }
}

#Preview("Tramontana · No plan") {
    PLHost(store: .noPlan) { TramontanaPlan(store: $0) }
}
#endif
