//
//  01-ModeratoRecurring.swift
//  Finlark
//
//  FIN-9 Recurring, Round 3 "Moderato": Adagio, the owner's pick, with what's pending first. The paged
//  slider of pending cards leads, or a caught-up tile when nothing waits; what goes out and comes in each
//  month follows, plain, not on glass; then every template, soonest first, and the paused ones apart.
//

#if DEBUG
import SwiftUI

struct ModeratoRecurring: View {
    @Bindable var store: RCStore

    var body: some View {
        RCScreen(store: store) { actions in
            let pending = store.pending
            if pending.isEmpty {
                RCCaughtUp(store: store)
            } else {
                RC2PendingTitle(store: store)
                RC2Slider(items: pending) { item in
                    RC2PendingCard(store: store, item: item, actions: actions)
                }
            }
            RC2MonthlyHeader(store: store)
            RCTemplateList(store: store, title: "All recurring", templates: store.active)
            RCTemplateList(store: store, title: "Paused", symbol: "pause.fill", templates: store.paused)
        }
    }
}

#Preview("Moderato") {
    RCHost { ModeratoRecurring(store: $0) }
}

#Preview("Moderato · Caught up") {
    RCHost(store: .caughtUp) { ModeratoRecurring(store: $0) }
}

#Preview("Moderato · Dark") {
    RCHost { ModeratoRecurring(store: $0) }
        .preferredColorScheme(.dark)
}
#endif
