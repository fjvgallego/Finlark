//
//  06-VivaceRecurring.swift
//  Finlark
//
//  FIN-9 Recurring, Round 2 "Vivace": the slider never runs dry. After the pending cards come the next
//  few coming up, without buttons, saying they'll be asked for on the day. Caught up, the slider shows
//  just those. Canon's header leads.
//

#if DEBUG
import SwiftUI

private enum VivacePage: Identifiable {
    case pending(RCPending)
    case upcoming(RCPending)

    var id: String {
        switch self {
        case .pending(let item): "pending|\(item.id)"
        case .upcoming(let item): "upcoming|\(item.id)"
        }
    }
}

struct VivaceRecurring: View {
    @Bindable var store: RCStore

    var body: some View {
        RCScreen(store: store) { actions in
            RC2MonthlyHeader(store: store)
            let pending = store.pending
            let upcoming = store.upcoming(days: 30).prefix(4)
            let pages = pending.map(VivacePage.pending) + upcoming.map(VivacePage.upcoming)
            if pending.isEmpty {
                RCSectionTitle(title: "Coming up")
            } else {
                RC2PendingTitle(store: store)
            }
            if !pages.isEmpty {
                RC2Slider(items: pages) { page in
                    switch page {
                    case .pending(let item):
                        RC2PendingCard(store: store, item: item, actions: actions)
                    case .upcoming(let item):
                        VivaceUpcomingCard(store: store, item: item)
                    }
                }
            }
            RCTemplateList(store: store, title: "All recurring", templates: store.active)
            RCTemplateList(store: store, title: "Paused", symbol: "pause.fill", templates: store.paused)
        }
    }
}

/// An occurrence that isn't due yet. It opens its template.
private struct VivaceUpcomingCard: View {
    let store: RCStore
    let item: RCPending

    var body: some View {
        if let template = store.template(item.templateID) {
            NavigationLink(value: RCRoute.template(template.id)) {
                R2Tile(padding: 14) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top, spacing: 12) {
                            P8CategoryIcon(category: template.category)
                            P8InfoAndAmount {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(verbatim: template.title)
                                        .font(.body.weight(.semibold))
                                    Text("\(RCFormat.relative(item.date)) · \(RCFormat.day(item.date))")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            } amount: {
                                RCFormat.amount(template, code: store.code)
                                    .font(.headline)
                                    .monospacedDigit()
                            }
                        }
                        Spacer(minLength: 0)
                        Label("You'll confirm it on the day", systemImage: "bell")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityElement(children: .combine)
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview("Vivace") {
    RCHost { VivaceRecurring(store: $0) }
}

#Preview("Vivace · Caught up") {
    RCHost(store: .caughtUp) { VivaceRecurring(store: $0) }
}

#Preview("Vivace · Dark") {
    RCHost { VivaceRecurring(store: $0) }
        .preferredColorScheme(.dark)
}
#endif
