//
//  06-FoehnPlan.swift
//  Finlark
//
//  FIN-9 Plan, Round 1 "Foehn": chart first. A Swift Charts bar per category shows spent and the
//  projection faded ahead of it, as a share of that category's plan, with one line where every plan
//  ends, so categories of any size compare at a glance. Touching a bar picks its category, and the tile under the chart shows it in
//  full. The summary sits in a compact strip above.
//

#if DEBUG
import Charts
import SwiftUI

struct FoehnPlan: View {
    @Bindable var store: PLStore

    @State private var selectedID: String?

    private var code: String { store.code }

    var body: some View {
        let report = store.report

        ScrollView {
            VStack(alignment: .leading, spacing: r2TileSpacing) {
                if report.hasPlan {
                    strip(report)
                    R2Tile(padding: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            R2TileHeader(title: "Categories", symbol: "chart.bar.xaxis")
                            FoehnChart(entries: report.entries, code: code, selectedID: $selectedID)
                            legend(report)
                        }
                    }
                    detail(report)
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
        .background { R2Backdrop() }
        .plChrome(store: store)
        .onChange(of: store.month) { selectedID = nil }
    }

    private func strip(_ report: PLReport) -> some View {
        R2Tile(padding: 16) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    PLPaceSentence(report: report, code: code)
                        .font(.headline)
                    Spacer(minLength: 8)
                    if let status = report.status {
                        PLStatusBadge(status: status)
                            .font(.title3)
                    }
                }
                PLFigures(report: report, code: code)
            }
            .monospacedDigit()
            .accessibilityElement(children: .combine)
        }
    }

    private func legend(_ report: PLReport) -> some View {
        let tint = Color.secondary
        return HStack(spacing: 14) {
            Label { Text("Spent") } icon: { Capsule().fill(tint).frame(width: 14, height: 6) }
            if report.isCurrent {
                Label { Text("Projected") } icon: { Capsule().fill(tint.opacity(0.35)).frame(width: 14, height: 6) }
            }
            Label { Text("Planned") } icon: { Capsule().fill(.primary).frame(width: 2, height: 12) }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .accessibilityHidden(true)
    }

    /// The touched category in full, or a hint to touch one.
    @ViewBuilder
    private func detail(_ report: PLReport) -> some View {
        R2Tile(padding: 18) {
            if let entry = report.entries.first(where: { $0.id == selectedID }) {
                VStack(alignment: .leading, spacing: 12) {
                    PLEntryRow(entry: entry, code: code)
                    if let planned = entry.planned {
                        PLFigures(
                            spent: entry.spent,
                            projected: entry.projected,
                            planned: planned,
                            tint: entry.status?.tint ?? .secondary,
                            code: code
                        )
                    }
                }
            } else {
                Label("Touch a bar to see that category in full.", systemImage: "hand.point.up.left")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// Horizontal bars as a share of each plan: spent solid, projection faded, the plan as one rule. VoiceOver reads each
/// bar from the chart's own accessibility labels.
private struct FoehnChart: View {
    let entries: [PLEntry]
    let code: String
    @Binding var selectedID: String?

    @ScaledMetric(relativeTo: .body) private var rowHeight: CGFloat = 38
    @State private var rawSelection: String?

    /// Each category's spending as a share of its own plan, so a €40 plan and a €750 one compare.
    private func share(_ value: Decimal, of entry: PLEntry) -> Double {
        guard let planned = entry.planned, planned > 0 else { return 0 }
        return value.plotValue / planned.plotValue
    }

    private var maxShare: Double {
        entries.map { share($0.projectedOrSpent, of: $0) }.max() ?? 1
    }

    var body: some View {
        Chart {
            ForEach(entries) { entry in
                let name = String(localized: entry.category.name)
                let tint = entry.status?.tint ?? .secondary
                let dimmed = selectedID != nil && selectedID != entry.id

                if let projected = entry.projected {
                    BarMark(x: .value("Projected", share(projected, of: entry)), y: .value("Category", name), height: .fixed(rowHeight * 0.4), stacking: .unstacked)
                        .foregroundStyle(tint.opacity(dimmed ? 0.12 : 0.3))
                        .clipShape(Capsule())
                        .accessibilityHidden(true)
                }
                BarMark(x: .value("Spent", share(entry.spent, of: entry)), y: .value("Category", name), height: .fixed(rowHeight * 0.4), stacking: .unstacked)
                    .foregroundStyle(tint.opacity(dimmed ? 0.35 : 1))
                    .clipShape(Capsule())
                    .accessibilityLabel(Text(entry.category.name))
                    .accessibilityValue(accessibilityValue(entry))
            }
            RuleMark(x: .value("Planned", 1.0))
                .foregroundStyle(Color.primary)
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                .accessibilityHidden(true)
        }
        .chartXScale(domain: 0...max(maxShare, 1.1))
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisValueLabel()
                    .font(.subheadline)
            }
        }
        .chartYSelection(value: $rawSelection)
        .onChange(of: rawSelection) { _, name in
            guard let name else { return }
            selectedID = entries.first { String(localized: $0.category.name) == name }?.id
        }
        .frame(height: rowHeight * CGFloat(entries.count))
    }

    private func accessibilityValue(_ entry: PLEntry) -> Text {
        let status = entry.status.map { Text($0.title) } ?? Text(verbatim: "")
        return Text("\(status), spent \(entry.spent, format: .currency(code: code)) of \(entry.planned ?? 0, format: .currency(code: code))")
    }
}

#Preview("Foehn") {
    PLHost { FoehnPlan(store: $0) }
}

#Preview("Foehn · Last month") {
    PLHost(store: .lastMonth) { FoehnPlan(store: $0) }
}

#Preview("Foehn · No plan") {
    PLHost(store: .noPlan) { FoehnPlan(store: $0) }
}
#endif
