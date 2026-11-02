//
//  RecurringRound2Components.swift
//  Finlark
//
//  FIN-9 Recurring, Round 2: the owner's picks from Round 1. A plain summary header, not on glass, as
//  in Canon (what recurring costs a month) and Passacaglia (what's waiting to be confirmed), and the
//  pending items in Rondo's paged slider. The variants differ in what the header says, how a pending
//  card looks, and how the templates below are grouped.
//

#if DEBUG
import SwiftUI

// MARK: - Headers

/// Canon's header: what goes out each month, large, and what comes in. Optionally a line with what's
/// waiting to be confirmed.
struct RC2MonthlyHeader: View {
    let store: RCStore
    var showsPending = false

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
            if showsPending, !store.pending.isEmpty {
                Label {
                    Text("\(store.pendingTotal, format: .currency(code: store.code).sign(strategy: .always())) waiting to be confirmed")
                        .monospacedDigit()
                } icon: {
                    Image(systemName: "clock.badge.exclamationmark.fill")
                        .foregroundStyle(.orange)
                }
                .font(.footnote.weight(.semibold))
                .padding(.top, 6)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Pending slider

/// "Pending 4" with the total trailing, over the slider.
struct RC2PendingTitle: View {
    let store: RCStore
    var title: LocalizedStringKey = "Pending"

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        // At accessibility sizes the total moves under the title, so the title keeps its line.
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline))
        layout {
            RCSectionTitle(title: title, count: store.pending.count)
            if !dynamicTypeSize.isAccessibilitySize {
                Spacer(minLength: 8)
            }
            Text(store.pendingTotal, format: .currency(code: store.code).sign(strategy: .always()))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .padding(.horizontal, 4)
                .accessibilityLabel(Text("Total \(store.pendingTotal.formatted(.currency(code: store.code)))"))
        }
    }
}

/// Rondo's paged slider, bleeding to the screen edges so the cards line up with the tiles.
struct RC2Slider<Item: Identifiable, Card: View>: View {
    let items: [Item]
    var peeksNextPage = false
    @ViewBuilder let card: (Item) -> Card

    var body: some View {
        R2Slider(items, peeksNextPage: peeksNextPage) { item in
            card(item)
        }
        .padding(.horizontal, -16)
    }
}

/// Rondo's card: the item, then wide Skip and Confirm. Tapping the item opens it to change first.
struct RC2PendingCard: View {
    let store: RCStore
    let item: RCPending
    let actions: RCActions

    var body: some View {
        R2Tile(padding: 14) {
            VStack(alignment: .leading, spacing: 12) {
                RC2ReviewButton(item: item, actions: actions) {
                    RCPendingInfo(store: store, item: item)
                }
                Spacer(minLength: 0)
                RCPendingButtons(store: store, item: item, actions: actions)
            }
        }
    }
}

/// Opens the confirm screen to change the amount, date or note first (REC-003).
struct RC2ReviewButton<Label: View>: View {
    let item: RCPending
    let actions: RCActions
    @ViewBuilder let label: Label

    var body: some View {
        Button { actions.review(item) } label: {
            label
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text("Opens it to change the amount, date or note before confirming."))
    }
}
#endif
