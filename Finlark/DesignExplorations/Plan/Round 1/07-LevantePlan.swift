//
//  07-LevantePlan.swift
//  Finlark
//
//  FIN-9 Plan, Round 1 "Levante": months side by side. Swipe right to go back a month, or tap one in
//  the strip of months under the bar; each month in the strip carries its status, so you see how
//  the last few went without opening them (PLN-002). Each page is the month's summary and its
//  categories in one tile each.
//

#if DEBUG
import SwiftUI

struct LevantePlan: View {
    @Bindable var store: PLStore

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Oldest first, so the current month is the last page and going back is a swipe right.
    private var months: [Date] { store.months.reversed() }

    var body: some View {
        TabView(selection: $store.month.animation(reduceMotion ? nil : .snappy)) {
            ForEach(months, id: \.self) { month in
                page(store.report(for: month))
                    .tag(month)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .safeAreaInset(edge: .top, spacing: 0) {
            strip
        }
        .background { R2Backdrop() }
        .plChrome(store: store)
    }

    // MARK: Months

    private var strip: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                GlassEffectContainer(spacing: 8) {
                    HStack(spacing: 8) {
                        ForEach(months, id: \.self) { month in
                            chip(month, report: store.report(for: month))
                                .id(month)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
            }
            .scrollIndicators(.hidden)
            .onAppear { proxy.scrollTo(store.month, anchor: .trailing) }
            .onChange(of: store.month) { _, month in
                withAnimation(reduceMotion ? nil : .snappy) { proxy.scrollTo(month, anchor: .center) }
            }
        }
    }

    private func chip(_ month: Date, report: PLReport) -> some View {
        let isSelected = month == store.month
        return Button {
            store.month = month
        } label: {
            HStack(spacing: 6) {
                if let status = report.status {
                    Image(systemName: status.symbol)
                        .foregroundStyle(status.tint)
                        .accessibilityLabel(Text(status.title))
                } else {
                    Image(systemName: "minus.circle")
                        .foregroundStyle(.secondary)
                        .accessibilityLabel(Text("No plan"))
                }
                PLFormat.shortMonth(month)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .font(.subheadline)
            .padding(.horizontal, 6)
        }
        .buttonStyle(.glass)
        .tint(isSelected ? .accentColor : nil)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: Page

    private func page(_ report: PLReport) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: r2TileSpacing) {
                if report.hasPlan {
                    summary(report)
                    categories(report)
                } else if report.isCurrent {
                    PLInvite(store: store)
                } else {
                    R2Tile(padding: 18) {
                        Label("No plan this month. All spending was unplanned.", systemImage: "minus.circle")
                            .foregroundStyle(.secondary)
                    }
                }
                PLUnplannedTile(report: report, code: store.code)
                if report.hasPlan {
                    PLFootnote(report: report, code: store.code)
                        .padding(.horizontal, 4)
                }
            }
            .padding()
        }
    }

    private func summary(_ report: PLReport) -> some View {
        R2Tile(padding: 18) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    PLFormat.month(report.month)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Spacer()
                    if report.isCurrent {
                        Text("\(report.daysLeft) days to go")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Label("Final", systemImage: "lock.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                PLPaceSentence(report: report, code: store.code)
                    .font(.title3.weight(.semibold))
                if let status = report.status {
                    PLStatusLabel(status: status)
                        .font(.subheadline.weight(.semibold))
                }
                PLBar.Total(report: report)
                PLFigures(report: report, code: store.code)
            }
            .monospacedDigit()
            .accessibilityElement(children: .combine)
        }
    }

    private func categories(_ report: PLReport) -> some View {
        R2Tile(padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
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

#Preview("Levante") {
    PLHost { LevantePlan(store: $0) }
}

#Preview("Levante · Last month") {
    PLHost(store: .lastMonth) { LevantePlan(store: $0) }
}

#Preview("Levante · No plan") {
    PLHost(store: .noPlan) { LevantePlan(store: $0) }
}
#endif
