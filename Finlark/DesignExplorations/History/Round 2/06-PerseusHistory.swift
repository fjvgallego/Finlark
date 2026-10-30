//
//  06-PerseusHistory.swift
//  Finlark
//
//  FIN-9 History, Round 2 "Perseus": the difference leads. One month at a time; the summary card opens
//  with what's left of the month's income, large, then income and spending with a bar showing how much
//  of the income was spent. Plain rows below.
//

#if DEBUG
import SwiftUI

struct PerseusHistory: View {
    @Bindable var store: HYStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if !store.records.isEmpty {
                    VStack(alignment: .leading, spacing: r2TileSpacing) {
                        HY2FilterChips(store: store)
                        if !store.results.isEmpty {
                            PerseusSummary(store: store)
                                .padding(.horizontal)
                        }
                    }
                }

                if !store.records.isEmpty, store.results.isEmpty {
                    HYEmptyView(store: store)
                        .padding(.top, 24)
                }

                ForEach(store.days) { day in
                    HY2PlainDay(day: day, code: store.code)
                        .padding(.horizontal, 20)
                }
            }
            .padding(.vertical)
        }
        .background { R2Backdrop() }
        .overlay {
            if store.records.isEmpty {
                HYEmptyView(store: store)
            }
        }
        .hy2Chrome(store: store)
    }
}

private struct PerseusSummary: View {
    let store: HYStore

    @ScaledMetric(relativeTo: .caption) private var barHeight: CGFloat = 8

    private var totals: HYTotals { store.totals }

    /// The difference leads; with a type filter on, that type's total does.
    private var headline: (title: Text, value: Decimal, signed: Bool) {
        switch store.type {
        case .all: (Text("Difference"), totals.difference, true)
        case .expense: (Text("Spending"), totals.spending, false)
        case .income: (Text("Income"), totals.income, false)
        }
    }

    /// The share of income spent, for drawing.
    private var spent: Double {
        guard totals.income > 0 else { return totals.spending > 0 ? 1 : 0 }
        return min(totals.spending.plotValue / totals.income.plotValue, 1)
    }

    var body: some View {
        R2Tile(padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    headline.title
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Text(headline.value, format: .currency(code: store.code).sign(strategy: headline.signed ? .always() : .automatic))
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .accessibilityElement(children: .combine)

                // Spent against income only means something when both are in view.
                if store.type == .all {
                    VStack(alignment: .leading, spacing: 6) {
                        GeometryReader { proxy in
                            Capsule()
                                .fill(.fill.tertiary)
                                .overlay(alignment: .leading) {
                                    Capsule()
                                        .fill(.tint)
                                        .frame(width: proxy.size.width * spent)
                                }
                        }
                        .frame(height: barHeight)
                        .accessibilityHidden(true)

                        HYTotalsRow(totals: totals, code: store.code, font: .headline)
                    }
                }

                if store.isNarrowed {
                    HYNarrowedNote(store: store)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview("Perseus") {
    HYHost { PerseusHistory(store: $0) }
}

#Preview("Perseus · Filtered") {
    HYHost(store: .filtered()) { PerseusHistory(store: $0) }
}

#Preview("Perseus · Empty") {
    HYHost(store: .empty) { PerseusHistory(store: $0) }
}
#endif
