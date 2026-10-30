//
//  02-SiroccoPlan.swift
//  Finlark
//
//  FIN-9 Plan, Round 1 "Sirocco": attention first. Three small tiles count the categories that are
//  Over, At risk and On track, then the categories come grouped the same way: the ones that need
//  attention in full, with what's pushing them, and the ones on track as short rows.
//

#if DEBUG
import SwiftUI

struct SiroccoPlan: View {
    @Bindable var store: PLStore

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let report = store.report

        ScrollView {
            VStack(alignment: .leading, spacing: r2TileSpacing) {
                if report.hasPlan {
                    counts(report)
                    attention(report)
                    calm(report)
                } else {
                    PLInvite(store: store)
                }
                PLUnplannedTile(report: report, code: store.code)
                if report.hasPlan {
                    PLFootnote(report: report, code: store.code)
                        .padding(.horizontal, 4)
                }
            }
            .padding()
        }
        .background { R2Backdrop() }
        .plChrome(store: store)
    }

    private func counts(_ report: PLReport) -> some View {
        let statuses: [PLStatus] = report.isCurrent ? [.over, .atRisk, .onTrack] : [.over, .withinPlan]
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: r2TileSpacing))
            : AnyLayout(HStackLayout(spacing: r2TileSpacing))

        return VStack(alignment: .leading, spacing: r2TileSpacing) {
            layout {
                ForEach(statuses, id: \.self) { status in
                    R2Tile(padding: 14) {
                        VStack(alignment: .leading, spacing: 6) {
                            Image(systemName: status.symbol)
                                .font(.title3)
                                .foregroundStyle(status.tint)
                                .accessibilityHidden(true)
                            Text(report.count(status), format: .number)
                                .font(.system(.title, design: .rounded, weight: .bold))
                            Text(status.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
            R2Tile(padding: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    PLPaceSentence(report: report, code: store.code)
                        .font(.headline)
                    PLBar.Total(report: report)
                    PLFigures(report: report, code: store.code)
                }
                .monospacedDigit()
                .accessibilityElement(children: .combine)
            }
        }
    }

    @ViewBuilder
    private func attention(_ report: PLReport) -> some View {
        let entries = report.entries.filter { ($0.status?.urgency ?? 2) < 2 }
        if !entries.isEmpty {
            R2Tile(padding: 18) {
                VStack(alignment: .leading, spacing: 14) {
                    R2TileHeader(title: "Needs attention", symbol: "exclamationmark.circle.fill")
                    ForEach(entries) { entry in
                        VStack(alignment: .leading, spacing: 8) {
                            PLEntryRow(entry: entry, code: store.code)
                            reason(entry)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        if entry.id != entries.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    /// What pushes a category past its plan: recurring still due, or the pace of everyday spending.
    @ViewBuilder
    private func reason(_ entry: PLEntry) -> some View {
        if entry.status == .over {
            Label("Already past its plan.", systemImage: "info.circle")
        } else if entry.recurringDue > 0, (entry.pace ?? 0) == 0 {
            Label(
                "\(entry.recurringDue, format: .currency(code: store.code)) of recurring expenses are still due.",
                systemImage: "arrow.triangle.2.circlepath"
            )
        } else if let pace = entry.pace {
            Label(
                "At this pace, about \(pace, format: .currency(code: store.code)) more by the end of the month.",
                systemImage: "speedometer"
            )
        }
    }

    @ViewBuilder
    private func calm(_ report: PLReport) -> some View {
        let entries = report.entries.filter { ($0.status?.urgency ?? 2) == 2 }
        if !entries.isEmpty {
            R2Tile(padding: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    if report.isCurrent {
                        R2TileHeader(title: "On track", symbol: "checkmark.circle.fill")
                    } else {
                        R2TileHeader(title: "Within plan", symbol: "checkmark.circle.fill")
                    }
                    ForEach(entries) { entry in
                        HStack(spacing: 12) {
                            ExplorationCategoryIcon(category: entry.category)
                            Text(entry.category.name)
                            Spacer(minLength: 8)
                            if let remaining = entry.remaining {
                                Text("\(remaining, format: .currency(code: store.code)) left")
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }
}

#Preview("Sirocco") {
    PLHost { SiroccoPlan(store: $0) }
}

#Preview("Sirocco · Last month") {
    PLHost(store: .lastMonth) { SiroccoPlan(store: $0) }
}

#Preview("Sirocco · No plan") {
    PLHost(store: .noPlan) { SiroccoPlan(store: $0) }
}
#endif
