//
//  02-CanonRecurring.swift
//  Finlark
//
//  FIN-9 Recurring, Round 1 "Canon": a plain header with what recurring costs a month, then compact
//  pending rows with a round Skip and People's round check, then the next 30 days by date, and every
//  template last.
//

#if DEBUG
import SwiftUI

struct CanonRecurring: View {
    @Bindable var store: RCStore

    var body: some View {
        RCScreen(store: store) { actions in
            CanonHeader(store: store)
            let pending = store.pending
            if !pending.isEmpty {
                R2Tile(padding: 18) {
                    VStack(alignment: .leading, spacing: 14) {
                        R2TileHeader(title: "Pending", symbol: "clock.badge.exclamationmark.fill")
                        ForEach(pending) { item in
                            P5Row {
                                Button { actions.review(item) } label: {
                                    RCPendingInfo(store: store, item: item)
                                }
                                .buttonStyle(.plain)
                                .accessibilityHint(Text("Opens it to change the amount, date or note before confirming."))
                            } controls: {
                                RCQuickControls(store: store, item: item, actions: actions)
                            }
                            if item.id != pending.last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }
            CanonUpcoming(store: store)
            RCTemplateList(store: store, title: "All recurring", templates: store.active)
            RCTemplateList(store: store, title: "Paused", symbol: "pause.fill", templates: store.paused)
        }
    }
}

/// What goes out and comes in each month, plain, not on glass.
private struct CanonHeader: View {
    let store: RCStore

    var body: some View {
        VStack(spacing: 4) {
            Text(store.monthlyTotal(.expense), format: .currency(code: store.code))
                .font(.largeTitle.weight(.bold))
                .monospacedDigit()
            Text("goes out each month")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("\(store.monthlyTotal(.income), format: .currency(code: store.code)) comes in")
                .font(.subheadline.weight(.medium))
                .monospacedDigit()
                .padding(.top, 4)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }
}

/// The next 30 days, a date column leading each row.
private struct CanonUpcoming: View {
    let store: RCStore

    @ScaledMetric private var dateWidth: CGFloat = 40

    var body: some View {
        let items = store.upcoming(days: 30)
        if !items.isEmpty {
            R2Tile(padding: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    R2TileHeader(title: "Next 30 days", symbol: "calendar")
                    ForEach(items) { item in
                        if let template = store.template(item.templateID) {
                            HStack(spacing: 12) {
                                VStack(spacing: 0) {
                                    Text(item.date, format: .dateTime.day())
                                        .font(.title3.weight(.semibold))
                                        .monospacedDigit()
                                    Text(item.date, format: .dateTime.month(.abbreviated))
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                        .textCase(.uppercase)
                                }
                                .frame(minWidth: dateWidth)
                                P8InfoAndAmount {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(verbatim: template.title)
                                        RCFormat.relative(item.date)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                } amount: {
                                    RCFormat.amount(template, code: store.code)
                                        .monospacedDigit()
                                }
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                }
            }
        }
    }
}

#Preview("Canon") {
    RCHost { CanonRecurring(store: $0) }
}

#Preview("Canon · Caught up") {
    RCHost(store: .caughtUp) { CanonRecurring(store: $0) }
}

#Preview("Canon · Dark") {
    RCHost { CanonRecurring(store: $0) }
        .preferredColorScheme(.dark)
}
#endif
