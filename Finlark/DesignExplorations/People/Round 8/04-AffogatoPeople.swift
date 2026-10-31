//
//  04-AffogatoPeople.swift
//  Finlark
//
//  FIN-9 People, Round 8 "Affogato": the person's header and Settle All share one glass card, so the
//  total and the button that settles it sit together. The open shares follow with their category icons.
//

#if DEBUG
import SwiftUI

struct AffogatoPerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID

    var body: some View {
        P8PersonScreen(store: store, id: id, showsHeader: false) { person, actions in
            R2Tile(padding: 20) {
                VStack(spacing: 14) {
                    P2PersonHeader(person: person, code: store.code)
                    if person.showsSettleAll {
                        P8SettleAllButton(person: person, code: store.code, action: actions.settleAll)
                    }
                }
            }
            if !person.openShares.isEmpty {
                R2Tile(padding: 18) {
                    VStack(alignment: .leading, spacing: 14) {
                        R2TileHeader(title: "Open shares", symbol: "clock.fill")
                        ForEach(person.openShares) { share in
                            P5Row {
                                HStack(alignment: .top, spacing: 12) {
                                    P8CategoryIcon(category: share.category)
                                    VStack(alignment: .leading, spacing: 3) {
                                        P5ShareTitle(share: share, code: store.code)
                                        Text("\(share.remaining, format: .currency(code: store.code)) left")
                                            .font(.headline)
                                            .monospacedDigit()
                                            .padding(.top, 2)
                                    }
                                }
                            } controls: {
                                GenmaichaCheck(title: Text("Mark \(share.ticket) as paid")) { actions.markPaid(share) }
                            }
                            if share.id != person.openShares.last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview("Affogato") {
    PPHost(opening: "marta") { GenmaichaPeople(store: $0) } person: { AffogatoPerson(store: $0, id: $1) }
}

#Preview("Affogato · Luis") {
    PPHost(opening: "luis") { GenmaichaPeople(store: $0) } person: { AffogatoPerson(store: $0, id: $1) }
}

#Preview("Affogato · Ana") {
    PPHost(opening: "ana") { GenmaichaPeople(store: $0) } person: { AffogatoPerson(store: $0, id: $1) }
}

#Preview("Affogato · Dark") {
    PPHost(opening: "luis") { GenmaichaPeople(store: $0) } person: { AffogatoPerson(store: $0, id: $1) }
        .preferredColorScheme(.dark)
}
#endif
