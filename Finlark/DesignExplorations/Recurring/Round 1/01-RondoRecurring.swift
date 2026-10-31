//
//  01-RondoRecurring.swift
//  Finlark
//
//  FIN-9 Recurring, Round 1 "Rondo": the same pending cards as Home (HOM-005), in a slider, so an
//  item looks the same wherever it waits. Below, every template in one tile, soonest first, and the
//  paused ones apart. Tapping a card opens it to change before confirming.
//

#if DEBUG
import SwiftUI

struct RondoRecurring: View {
    @Bindable var store: RCStore

    var body: some View {
        RCScreen(store: store) { actions in
            let pending = store.pending
            if pending.isEmpty {
                RCCaughtUp(store: store)
            } else {
                RCSectionTitle(title: "Pending", count: pending.count)
                R2Slider(pending) { item in
                    R2Tile(padding: 14) {
                        VStack(alignment: .leading, spacing: 12) {
                            Button { actions.review(item) } label: {
                                RCPendingInfo(store: store, item: item)
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint(Text("Opens it to change the amount, date or note before confirming."))
                            Spacer(minLength: 0)
                            RCPendingButtons(store: store, item: item, actions: actions)
                        }
                    }
                }
                // The slider brings its own margins, so the cards line up with the tiles.
                .padding(.horizontal, -16)
            }
            RCTemplateList(store: store, title: "All recurring", templates: store.active)
            RCTemplateList(store: store, title: "Paused", symbol: "pause.fill", templates: store.paused)
        }
    }
}

#Preview("Rondo") {
    RCHost { RondoRecurring(store: $0) }
}

#Preview("Rondo · Caught up") {
    RCHost(store: .caughtUp) { RondoRecurring(store: $0) }
}

#Preview("Rondo · Dark") {
    RCHost { RondoRecurring(store: $0) }
        .preferredColorScheme(.dark)
}
#endif
