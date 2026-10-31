//
//  02-AndanteRecurring.swift
//  Finlark
//
//  FIN-9 Recurring, Round 2 "Andante": Passacaglia's header leads, since it's about what to do now:
//  what's waiting and how much, or that you're caught up and what's next. The slider follows straight
//  under it, without a title. What recurring costs a month moves to the templates tile's heading.
//

#if DEBUG
import SwiftUI

struct AndanteRecurring: View {
    @Bindable var store: RCStore

    var body: some View {
        RCScreen(store: store) { actions in
            RC2PendingHeader(store: store)
            let pending = store.pending
            if !pending.isEmpty {
                RC2Slider(items: pending) { item in
                    RC2PendingCard(store: store, item: item, actions: actions)
                }
            }
            AndanteTemplates(store: store)
            RCTemplateList(store: store, title: "Paused", symbol: "pause.fill", templates: store.paused)
        }
    }
}

/// Every active template, with the monthly figures in the heading, or under it at accessibility sizes.
private struct AndanteTemplates: View {
    let store: RCStore

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let templates = store.active
        if !templates.isEmpty {
            R2Tile(padding: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    R2TileHeader(title: "All recurring", symbol: "repeat") {
                        if !dynamicTypeSize.isAccessibilitySize {
                            monthly
                        }
                    }
                    if dynamicTypeSize.isAccessibilitySize {
                        monthly
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

    private var monthly: some View {
        Text("\(store.monthlyTotal(.expense), format: .currency(code: store.code)) out a month")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .monospacedDigit()
    }
}

#Preview("Andante") {
    RCHost { AndanteRecurring(store: $0) }
}

#Preview("Andante · Caught up") {
    RCHost(store: .caughtUp) { AndanteRecurring(store: $0) }
}

#Preview("Andante · Dark") {
    RCHost { AndanteRecurring(store: $0) }
        .preferredColorScheme(.dark)
}
#endif
