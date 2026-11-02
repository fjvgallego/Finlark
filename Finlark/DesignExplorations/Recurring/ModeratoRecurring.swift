//
//  ModeratoRecurring.swift
//  Finlark
//
//  FIN-9 Recurring "Moderato": what's pending first. The paged slider of pending cards leads, or a
//  caught-up tile when nothing waits; what goes out and comes in each month follows, plain, not on
//  glass; then every template, soonest first, and the paused ones apart.
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
                RCPendingTitle(store: store)
                RCSlider(items: pending) { item in
                    RCPendingCard(store: store, item: item, actions: actions)
                }
            }
            RCMonthlyHeader(store: store)
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
