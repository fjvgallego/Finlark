//
//  10-PassacagliaRecurring.swift
//  Finlark
//
//  FIN-9 Recurring, Round 1 "Passacaglia": built like People's Financier screen. A plain header, not on
//  glass, says how much is waiting to be confirmed. The pending rows have the amount trailing and two
//  wide buttons under each, Skip in plain glass and Confirm in blue glass. Every template follows.
//

#if DEBUG
import SwiftUI

struct PassacagliaRecurring: View {
    @Bindable var store: RCStore

    var body: some View {
        RCScreen(store: store) { actions in
            PassacagliaHeader(store: store)
            let pending = store.pending
            if !pending.isEmpty {
                R2Tile(padding: 18) {
                    VStack(alignment: .leading, spacing: 14) {
                        R2TileHeader(title: "Pending", symbol: "clock.badge.exclamationmark.fill")
                        ForEach(pending) { item in
                            VStack(alignment: .leading, spacing: 12) {
                                Button { actions.review(item) } label: {
                                    RCPendingInfo(store: store, item: item)
                                }
                                .buttonStyle(.plain)
                                .accessibilityHint(Text("Opens it to change the amount, date or note before confirming."))
                                RCPendingButtons(store: store, item: item, actions: actions)
                            }
                            if item.id != pending.last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }
            RCTemplateList(store: store, title: "All recurring", templates: store.active)
            RCTemplateList(store: store, title: "Paused", symbol: "pause.fill", templates: store.paused)
        }
    }
}

/// What's waiting, or that nothing is, plain.
private struct PassacagliaHeader: View {
    let store: RCStore

    var body: some View {
        let pending = store.pending
        VStack(spacing: 4) {
            if pending.isEmpty {
                Image(systemName: "checkmark.seal.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.green)
                    .padding(.bottom, 4)
                Text("All caught up")
                    .font(.title2.weight(.bold))
                if let next = store.upcoming(days: 366).first, let template = store.template(next.templateID) {
                    Text("Next: \(template.title) on \(next.date, format: .dateTime.weekday(.wide).day().month())")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text(store.pendingTotal, format: .currency(code: store.code).sign(strategy: .always()))
                    .font(.largeTitle.weight(.bold))
                    .monospacedDigit()
                Text("^[\(pending.count) item](inflect: true) waiting for you to confirm")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Not in your balance until you do.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Passacaglia") {
    RCHost { PassacagliaRecurring(store: $0) }
}

#Preview("Passacaglia · Caught up") {
    RCHost(store: .caughtUp) { PassacagliaRecurring(store: $0) }
}

#Preview("Passacaglia · Dark") {
    RCHost { PassacagliaRecurring(store: $0) }
        .preferredColorScheme(.dark)
}
#endif
