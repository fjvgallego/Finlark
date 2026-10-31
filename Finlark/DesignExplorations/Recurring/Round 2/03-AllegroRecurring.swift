//
//  03-AllegroRecurring.swift
//  Finlark
//
//  FIN-9 Recurring, Round 2 "Allegro": both summaries in one header, the monthly cost large and what's
//  waiting to be confirmed on a line under it. The pending cards narrow so the next one peeks in,
//  hinting that they scroll. The templates are split into expenses and income, each with its monthly
//  total.
//

#if DEBUG
import SwiftUI

struct AllegroRecurring: View {
    @Bindable var store: RCStore

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        RCScreen(store: store) { actions in
            RC2MonthlyHeader(store: store, showsPending: true)
            let pending = store.pending
            if pending.isEmpty {
                RCCaughtUp(store: store)
            } else {
                RC2PendingTitle(store: store)
                RC2Slider(items: pending, peeksNextPage: true) { item in
                    RC2PendingCard(store: store, item: item, actions: actions)
                }
            }
            group(.expense, title: "Expenses", symbol: "arrow.up.right")
            group(.income, title: "Income", symbol: "arrow.down.left")
            RCTemplateList(store: store, title: "Paused", symbol: "pause.fill", templates: store.paused)
        }
    }

    @ViewBuilder
    private func group(_ type: ExplorationTransactionType, title: LocalizedStringKey, symbol: String) -> some View {
        let templates = store.active.filter { $0.type == type }
        if !templates.isEmpty {
            R2Tile(padding: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    // At accessibility sizes the total moves under the heading, so the heading keeps its line.
                    R2TileHeader(title: title, symbol: symbol) {
                        if !dynamicTypeSize.isAccessibilitySize {
                            monthly(type)
                        }
                    }
                    if dynamicTypeSize.isAccessibilitySize {
                        monthly(type)
                    }
                    ForEach(templates) { template in
                        NavigationLink(value: RCRoute.template(template.id)) {
                            RCTemplateRow(store: store, template: template)
                        }
                        .buttonStyle(.plain)
                        if template.id != templates.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private func monthly(_ type: ExplorationTransactionType) -> some View {
        Text("\(store.monthlyTotal(type), format: .currency(code: store.code)) a month")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .monospacedDigit()
    }
}

#Preview("Allegro") {
    RCHost { AllegroRecurring(store: $0) }
}

#Preview("Allegro · Caught up") {
    RCHost(store: .caughtUp) { AllegroRecurring(store: $0) }
}

#Preview("Allegro · Dark") {
    RCHost { AllegroRecurring(store: $0) }
        .preferredColorScheme(.dark)
}
#endif
