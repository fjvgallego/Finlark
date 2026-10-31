//
//  09-RomanoPeople.swift
//  Finlark
//
//  FIN-9 People, Round 8 "Romano": the open shares as a horizontal slider of cards, the next one
//  peeking in, each with its amount and Mark as Paid. Settle All sits under the slider for all of them.
//  At accessibility sizes the cards stack instead.
//

#if DEBUG
import SwiftUI

struct RomanoPerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID

    var body: some View {
        P8PersonScreen(store: store, id: id) { person, actions in
            if !person.openShares.isEmpty {
                VStack(spacing: r2TileSpacing) {
                    P8SectionTitle("Open shares")
                    R2Slider(person.openShares, margin: 0, peeksNextPage: person.openShares.count > 1) { share in
                        RomanoCard(share: share, code: store.code) { actions.markPaid(share) }
                    }
                    if person.showsSettleAll {
                        P8SettleAllButton(person: person, code: store.code, action: actions.settleAll)
                    }
                }
            }
        }
    }
}

private struct RomanoCard: View {
    let share: PPShare
    let code: String
    let markPaid: () -> Void

    var body: some View {
        R2Tile(padding: 18) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    P8CategoryIcon(category: share.category)
                    P5ShareTitle(share: share, code: code, showsPaid: false)
                }
                Spacer(minLength: 0)
                VStack(alignment: .leading, spacing: 4) {
                    Text(share.remaining, format: .currency(code: code))
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    if share.paid > 0 {
                        Text("left · \(share.paid, format: .currency(code: code)) of \(share.share, format: .currency(code: code)) paid")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("left")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .monospacedDigit()
                .accessibilityElement(children: .combine)
                Button(action: markPaid) {
                    Label("Mark as Paid", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .accessibilityLabel(Text("Mark \(share.ticket) as paid"))
            }
        }
    }
}

#Preview("Romano") {
    PPHost(opening: "marta") { GenmaichaPeople(store: $0) } person: { RomanoPerson(store: $0, id: $1) }
}

#Preview("Romano · Luis") {
    PPHost(opening: "luis") { GenmaichaPeople(store: $0) } person: { RomanoPerson(store: $0, id: $1) }
}

#Preview("Romano · Ana") {
    PPHost(opening: "ana") { GenmaichaPeople(store: $0) } person: { RomanoPerson(store: $0, id: $1) }
}

#Preview("Romano · Dark") {
    PPHost(opening: "luis") { GenmaichaPeople(store: $0) } person: { RomanoPerson(store: $0, id: $1) }
        .preferredColorScheme(.dark)
}
#endif
