//
//  01-AdagioRecurring.swift
//  Finlark
//
//  FIN-9 Recurring, Round 2 "Adagio": the two picks as they were. Canon's header with what goes out
//  and comes in each month, then Rondo's slider of pending cards with wide Skip and Confirm, then every
//  template soonest first, and the paused ones apart.
//

#if DEBUG
import SwiftUI

struct AdagioRecurring: View {
    @Bindable var store: RCStore

    var body: some View {
        RCScreen(store: store) { actions in
            RC2MonthlyHeader(store: store)
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

#Preview("Adagio") {
    RCHost { AdagioRecurring(store: $0) }
}

#Preview("Adagio · Caught up") {
    RCHost(store: .caughtUp) { AdagioRecurring(store: $0) }
}

#Preview("Adagio · Dark") {
    RCHost { AdagioRecurring(store: $0) }
        .preferredColorScheme(.dark)
}
#endif
