//
//  01-MistralPlan.swift
//  Finlark
//
//  FIN-9 Plan, Round 1 "Mistral": Home's plan tile, grown into a screen. The summary tile is Marsh's
//  (the pace sentence, the status, the three figures and the bar), then one glass tile holds every
//  planned category with plain rows, and a last tile lists unplanned spending.
//

#if DEBUG
import SwiftUI

struct MistralPlan: View {
    @Bindable var store: PLStore

    var body: some View {
        let report = store.report

        ScrollView {
            VStack(alignment: .leading, spacing: r2TileSpacing) {
                if report.hasPlan {
                    summary(report)
                    categories(report)
                } else {
                    PLInvite(store: store)
                }
                PLUnplannedTile(report: report, code: store.code)
                if report.hasPlan {
                    PLFootnote(report: report, code: store.code)
                        .padding(.horizontal, 4)
                        .padding(.top, 4)
                }
            }
            .padding()
        }
        .background { R2Backdrop() }
        .plChrome(store: store)
    }

    private func summary(_ report: PLReport) -> some View {
        R2Tile(padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    PLPaceSentence(report: report, code: store.code)
                        .font(.title3.weight(.semibold))
                    if let status = report.status {
                        PLStatusLabel(status: status)
                            .font(.subheadline.weight(.semibold))
                    }
                }
                PLFigures(report: report, code: store.code)
                PLBar.Total(report: report)
                    .padding(.vertical, 2)
                if report.isCurrent {
                    Text("\(report.daysLeft) days to go")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .monospacedDigit()
            .accessibilityElement(children: .combine)
        }
    }

    private func categories(_ report: PLReport) -> some View {
        R2Tile(padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                R2TileHeader(title: "Categories", symbol: "square.grid.2x2.fill")
                ForEach(report.entries) { entry in
                    PLEntryRow(entry: entry, code: store.code)
                    if entry.id != report.entries.last?.id {
                        Divider()
                    }
                }
            }
        }
    }
}

#Preview("Mistral") {
    PLHost { MistralPlan(store: $0) }
}

#Preview("Mistral · Last month") {
    PLHost(store: .lastMonth) { MistralPlan(store: $0) }
}

#Preview("Mistral · Early month") {
    PLHost(store: .earlyMonth) { MistralPlan(store: $0) }
}

#Preview("Mistral · No plan") {
    PLHost(store: .noPlan) { MistralPlan(store: $0) }
}
#endif
