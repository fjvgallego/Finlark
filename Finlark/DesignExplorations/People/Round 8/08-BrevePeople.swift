//
//  08-BrevePeople.swift
//  Finlark
//
//  FIN-9 People, Round 8 "Breve": the amount is the button. Each share's trailing control is a blue
//  glass capsule with a check and what's left, and the tile ends on the same kind of capsule for
//  everything, so Settle All reads as one more amount to tick off.
//

#if DEBUG
import SwiftUI

struct BrevePerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID

    var body: some View {
        P8PersonScreen(store: store, id: id) { person, actions in
            if !person.openShares.isEmpty {
                R2Tile(padding: 18) {
                    VStack(alignment: .leading, spacing: 14) {
                        R2TileHeader(title: "Open shares", symbol: "clock.fill")
                        ForEach(person.openShares) { share in
                            P5Row {
                                P5ShareTitle(share: share, code: store.code)
                            } controls: {
                                BreveAmountButton(amount: share.remaining, code: store.code) { actions.markPaid(share) }
                                    .accessibilityLabel(Text("Mark \(share.ticket) as paid, \(share.remaining.formatted(.currency(code: store.code)))"))
                            }
                            Divider()
                        }
                        if person.showsSettleAll {
                            P5Row {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("All open shares")
                                        .font(.headline)
                                    Text("^[\(person.openShares.count) share](inflect: true)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .accessibilityHidden(true)
                            } controls: {
                                BreveAmountButton(amount: person.owed, code: store.code, isLarge: true, action: actions.settleAll)
                                    .accessibilityLabel(Text("Settle all, \(person.owed.formatted(.currency(code: store.code)))"))
                            }
                        }
                        Text("Tap an amount once it's paid back.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

/// A check and an amount in a blue glass capsule.
private struct BreveAmountButton: View {
    let amount: Decimal
    let code: String
    var isLarge = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label {
                Text(amount, format: .currency(code: code))
                    .monospacedDigit()
            } icon: {
                Image(systemName: isLarge ? "checkmark.circle.fill" : "checkmark")
            }
            .fontWeight(.semibold)
        }
        .buttonStyle(.glassProminent)
        .controlSize(isLarge ? .large : .regular)
    }
}

#Preview("Breve") {
    PPHost(opening: "marta") { GenmaichaPeople(store: $0) } person: { BrevePerson(store: $0, id: $1) }
}

#Preview("Breve · Luis") {
    PPHost(opening: "luis") { GenmaichaPeople(store: $0) } person: { BrevePerson(store: $0, id: $1) }
}

#Preview("Breve · Ana") {
    PPHost(opening: "ana") { GenmaichaPeople(store: $0) } person: { BrevePerson(store: $0, id: $1) }
}

#Preview("Breve · Dark") {
    PPHost(opening: "luis") { GenmaichaPeople(store: $0) } person: { BrevePerson(store: $0, id: $1) }
        .preferredColorScheme(.dark)
}
#endif
