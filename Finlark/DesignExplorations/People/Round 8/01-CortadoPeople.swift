//
//  01-CortadoPeople.swift
//  Finlark
//
//  FIN-9 People, Round 8 "Cortado": each open share on a glass card of its own, with its category,
//  what's left in large type and a labeled Mark as Paid button. Settle All follows the cards, after the
//  shares it settles.
//

#if DEBUG
import SwiftUI

struct CortadoPerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID

    var body: some View {
        P8PersonScreen(store: store, id: id) { person, actions in
            if !person.openShares.isEmpty {
                VStack(spacing: r2TileSpacing) {
                    P8SectionTitle("Open shares")
                    ForEach(person.openShares) { share in
                        CortadoCard(share: share, code: store.code) { actions.markPaid(share) }
                    }
                    if person.showsSettleAll {
                        P8SettleAllButton(person: person, code: store.code, action: actions.settleAll)
                            .padding(.top, 4)
                    }
                }
            }
        }
    }
}

private struct CortadoCard: View {
    let share: PPShare
    let code: String
    let markPaid: () -> Void

    var body: some View {
        R2Tile(padding: 16) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    P8CategoryIcon(category: share.category)
                    P8InfoAndAmount {
                        P5ShareTitle(share: share, code: code, showsPaid: false)
                    } amount: {
                        P8Remaining(share: share, code: code, font: .title3.weight(.bold))
                            .fontDesign(.rounded)
                    }
                }
                if share.paid > 0 {
                    VStack(alignment: .leading, spacing: 6) {
                        PPProgressBar(share: share, color: .accentColor)
                        Text("\(share.paid, format: .currency(code: code)) of \(share.share, format: .currency(code: code)) paid")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
                Button(action: markPaid) {
                    Label("Mark as Paid", systemImage: "checkmark")
                }
                .buttonStyle(.glassProminent)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .accessibilityLabel(Text("Mark \(share.ticket) as paid"))
            }
        }
    }
}

#Preview("Cortado") {
    PPHost(opening: "marta") { GenmaichaPeople(store: $0) } person: { CortadoPerson(store: $0, id: $1) }
}

#Preview("Cortado · Luis") {
    PPHost(opening: "luis") { GenmaichaPeople(store: $0) } person: { CortadoPerson(store: $0, id: $1) }
}

#Preview("Cortado · Ana") {
    PPHost(opening: "ana") { GenmaichaPeople(store: $0) } person: { CortadoPerson(store: $0, id: $1) }
}

#Preview("Cortado · Dark") {
    PPHost(opening: "luis") { GenmaichaPeople(store: $0) } person: { CortadoPerson(store: $0, id: $1) }
        .preferredColorScheme(.dark)
}
#endif
