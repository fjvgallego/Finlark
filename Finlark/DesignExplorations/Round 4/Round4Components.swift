//
//  Round4Components.swift
//  Finlark
//
//  FIN-9 Round 4: pieces for the Ember variants. Ember's separate "Spending by category" tile is gone,
//  so HOM-002's chart shrinks into the month summary. The rest of Round 4 varies how each section
//  presents its information. Builds on the Round 2 and Round 3 components.
//

#if DEBUG
import SwiftUI
import Charts

/// A compact spending-by-category chart (HOM-002): one thin bar split by category, with a legend that
/// names each color and its amount. Fits inside the month summary instead of taking its own section.
struct R4SpendingStrip: View {
    let snapshot: ExplorationHomeSnapshot
    var limit = 3

    @ScaledMetric(relativeTo: .caption) private var barHeight: CGFloat = 10
    @ScaledMetric(relativeTo: .caption) private var swatchSize: CGFloat = 8

    private var items: [ExplorationCategorySpending] { snapshot.r3TopSpending(limit: limit) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Chart(items) { item in
                BarMark(x: .value("Amount", item.amount.plotValue))
                    .foregroundStyle(item.category.color)
            }
            .chartXScale(domain: 0...max(snapshot.monthSpending.plotValue, 1))
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: barHeight)
            .clipShape(.capsule)
            .accessibilityHidden(true) // The legend reads out every category.

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 14) { legend }
                Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 4) {
                    ForEach(Array(stride(from: 0, to: items.count, by: 2)), id: \.self) { start in
                        GridRow {
                            legendItem(items[start])
                            if start + 1 < items.count {
                                legendItem(items[start + 1])
                            }
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 4) { legend }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Spending by category"))
    }

    @ViewBuilder
    private var legend: some View {
        ForEach(items) { item in
            legendItem(item)
        }
    }

    private func legendItem(_ item: ExplorationCategorySpending) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(item.category.color)
                .frame(width: swatchSize, height: swatchSize)
                .accessibilityHidden(true)
            Text(item.category.name)
                .foregroundStyle(.secondary)
            Text(item.amount, format: .currency(code: snapshot.currencyCode))
                .fontWeight(.medium)
                .monospacedDigit()
        }
        .font(.caption)
        .accessibilityElement(children: .combine)
    }
}

/// Pending recurring items (HOM-005) as a vertical list inside one tile, instead of a slider.
struct R4PendingList: View {
    let model: ExplorationHomeModel

    var body: some View {
        if !model.pendingItems.isEmpty {
            VStack(alignment: .leading, spacing: r2TileSpacing) {
                R3SectionHeader(title: "Pending", count: model.pendingItems.count)
                R2Tile(padding: 16) {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(model.pendingItems) { item in
                            ExplorationPendingRow(
                                item: item,
                                currencyCode: model.snapshot.currencyCode,
                                onConfirm: { model.confirm(item) },
                                onSkip: { model.skip(item) }
                            )
                            if item.id != model.pendingItems.last?.id {
                                Divider()
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

/// Recent transactions (HOM-006) as a vertical list inside one tile, instead of cards.
struct R4RecentList: View {
    let snapshot: ExplorationHomeSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: r2TileSpacing) {
            R3SectionHeader(title: "Recent") {
                R2Link(destination: .history) { Text("History") }
                    .font(.subheadline.weight(.semibold))
            }
            R2Tile(padding: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(snapshot.recentTransactions) { transaction in
                        ExplorationTransactionRow(transaction: transaction, currencyCode: snapshot.currencyCode)
                        if transaction.id != snapshot.recentTransactions.last?.id {
                            Divider()
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}
#endif
