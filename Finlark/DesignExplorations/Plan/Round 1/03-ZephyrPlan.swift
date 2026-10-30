//
//  03-ZephyrPlan.swift
//  Finlark
//
//  FIN-9 Plan, Round 1 "Zephyr": rings in a bento grid. A large ring for the whole plan opens the
//  screen, with what's left in its center, then each category gets a tile with its own ring: spent
//  solid, the projection faded ahead of it. Two columns, one at accessibility sizes.
//

#if DEBUG
import SwiftUI

struct ZephyrPlan: View {
    @Bindable var store: PLStore

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric private var ringSize: CGFloat = 52

    private var columns: [GridItem] {
        let count = dynamicTypeSize.isAccessibilitySize ? 1 : 2
        return Array(repeating: GridItem(.flexible(), spacing: r2TileSpacing), count: count)
    }

    var body: some View {
        let report = store.report

        ScrollView {
            VStack(alignment: .leading, spacing: r2TileSpacing) {
                if report.hasPlan {
                    hero(report)
                    LazyVGrid(columns: columns, spacing: r2TileSpacing) {
                        ForEach(report.entries) { entry in
                            tile(entry)
                        }
                    }
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

    private func hero(_ report: PLReport) -> some View {
        R2Tile(padding: 20) {
            VStack(spacing: 16) {
                ZephyrRing(
                    spent: report.spent,
                    projected: report.projected,
                    planned: report.planned,
                    tint: report.status?.tint ?? .accentColor,
                    lineWidth: 18
                ) {
                    VStack(spacing: 2) {
                        if report.spent > report.planned {
                            Text(report.spent - report.planned, format: .currency(code: store.code))
                                .font(.system(.title, design: .rounded, weight: .bold))
                            Text("over plan")
                        } else {
                            Text(report.remaining, format: .currency(code: store.code))
                                .font(.system(.title, design: .rounded, weight: .bold))
                            Text("left to spend")
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(28)
                }
                .frame(maxWidth: 220)

                if let status = report.status {
                    PLStatusLabel(status: status)
                        .font(.headline)
                }
                PLFigures(report: report, code: store.code)
            }
            .frame(maxWidth: .infinity)
            .monospacedDigit()
            .accessibilityElement(children: .combine)
        }
    }

    private func tile(_ entry: PLEntry) -> some View {
        R2Tile(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    ZephyrRing(
                        spent: entry.spent,
                        projected: entry.projected,
                        planned: entry.planned ?? 0,
                        tint: entry.status?.tint ?? .secondary,
                        lineWidth: 7
                    ) {
                        Image(systemName: entry.category.symbol)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(entry.category.color)
                    }
                    .frame(width: ringSize, height: ringSize)
                    Spacer(minLength: 4)
                    if let status = entry.status {
                        PLStatusBadge(status: status)
                    }
                }
                Text(entry.category.name)
                    .font(.headline)
                    .lineLimit(2)
                PLEntryDetail(entry: entry, code: store.code)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .monospacedDigit()
            .accessibilityElement(children: .combine)
        }
    }
}

/// Spent as a solid arc and the projection as a faded one, both against the planned amount. Past the
/// plan, the ring closes.
private struct ZephyrRing<Center: View>: View {
    let spent: Decimal
    let projected: Decimal?
    let planned: Decimal
    let tint: Color
    let lineWidth: CGFloat
    @ViewBuilder var center: Center

    var body: some View {
        ZStack {
            Circle().stroke(.quaternary, lineWidth: lineWidth)
            if let projected {
                arc(projected).stroke(tint.opacity(0.35), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            }
            arc(spent).stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            center
        }
        .padding(lineWidth / 2)
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }

    private func arc(_ value: Decimal) -> some Shape {
        let fraction = planned > 0 ? min(value.plotValue / planned.plotValue, 1) : 0
        return Circle().trim(from: 0, to: fraction).rotation(.degrees(-90))
    }
}

#Preview("Zephyr") {
    PLHost { ZephyrPlan(store: $0) }
}

#Preview("Zephyr · Last month") {
    PLHost(store: .lastMonth) { ZephyrPlan(store: $0) }
}

#Preview("Zephyr · No plan") {
    PLHost(store: .noPlan) { ZephyrPlan(store: $0) }
}
#endif
