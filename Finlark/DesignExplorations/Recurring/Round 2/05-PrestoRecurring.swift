//
//  05-PrestoRecurring.swift
//  Finlark
//
//  FIN-9 Recurring, Round 2 "Presto": Canon's header with a bar under it that splits the monthly cost
//  by category, and a legend naming each one with its amount, so the bar's colors aren't the only way
//  to read it. Rondo's slider and the templates follow.
//

#if DEBUG
import SwiftUI

struct PrestoRecurring: View {
    @Bindable var store: RCStore

    var body: some View {
        RCScreen(store: store) { actions in
            VStack(spacing: 12) {
                RC2MonthlyHeader(store: store)
                PrestoBreakdown(store: store)
            }
            .padding(.bottom, 8)
            let pending = store.pending
            if pending.isEmpty {
                RCCaughtUp(store: store)
            } else {
                RC2PendingTitle(store: store)
                RC2Slider(items: pending) { item in
                    RC2PendingCard(store: store, item: item, actions: actions)
                }
            }
            RCTemplateList(store: store, title: "All recurring", templates: store.active)
            RCTemplateList(store: store, title: "Paused", symbol: "pause.fill", templates: store.paused)
        }
    }
}

private struct PrestoSlice: Identifiable {
    let category: ExplorationCategory
    let amount: Decimal

    var id: String { category.id }
}

/// The monthly cost by category: a bar, then a two-column legend. The bar is decorative; the legend
/// says the same in words.
private struct PrestoBreakdown: View {
    let store: RCStore

    @ScaledMetric private var barHeight: CGFloat = 10
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var slices: [PrestoSlice] {
        let byCategory = Dictionary(grouping: store.active.filter { $0.type == .expense }, by: \.category.id)
        return byCategory.compactMap { _, templates in
            templates.first.map { PrestoSlice(category: $0.category, amount: templates.reduce(0) { $0 + $1.monthlyAmount }) }
        }
        .sorted { $0.amount > $1.amount }
    }

    var body: some View {
        let slices = slices
        let total = slices.reduce(Decimal(0)) { $0 + $1.amount }.plotValue
        VStack(spacing: 12) {
            GeometryReader { proxy in
                let spacing: CGFloat = 2
                let width = proxy.size.width - spacing * CGFloat(max(slices.count - 1, 0))
                HStack(spacing: spacing) {
                    ForEach(slices) { slice in
                        Capsule()
                            .fill(slice.category.color)
                            .frame(width: total > 0 ? max(width * slice.amount.plotValue / total, 4) : 0)
                    }
                }
            }
            .frame(height: barHeight)
            .accessibilityHidden(true)

            let columns = Array(repeating: GridItem(.flexible(), spacing: 16, alignment: .leading), count: dynamicTypeSize.isAccessibilitySize ? 1 : 2)
            LazyVGrid(columns: columns, alignment: .leading, spacing: 6) {
                ForEach(slices) { slice in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(slice.category.color)
                            .frame(width: 8, height: 8)
                            .accessibilityHidden(true)
                        Text(slice.category.name)
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        Text(slice.amount, format: .currency(code: store.code))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    .font(.caption)
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .padding(.horizontal, 4)
    }
}

#Preview("Presto") {
    RCHost { PrestoRecurring(store: $0) }
}

#Preview("Presto · Caught up") {
    RCHost(store: .caughtUp) { PrestoRecurring(store: $0) }
}

#Preview("Presto · Dark") {
    RCHost { PrestoRecurring(store: $0) }
        .preferredColorScheme(.dark)
}
#endif
