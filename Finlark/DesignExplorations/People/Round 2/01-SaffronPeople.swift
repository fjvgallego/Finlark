//
//  01-SaffronPeople.swift
//  Finlark
//
//  FIN-9 People, Round 2 "Saffron": Iris with quick actions. Each person who owes you has two round
//  buttons on their row, Remind and Settle all, so the common jobs take one tap from the list. The
//  person is Dahlia's, and every open share has its own Paid in Full and Part buttons (SPL-006,
//  SPL-007), so Settle all is a shortcut, never the only way. Glass tiles, tinted custom buttons.
//

#if DEBUG
import SwiftUI

struct SaffronPeople: View {
    @Bindable var store: PPStore
    var surface: R2Surface = .glass

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: r2TileSpacing) {
                if !store.active.isEmpty {
                    P2OwedHeader(store: store)
                }
                if !store.owing.isEmpty {
                    R2Tile(padding: 18) {
                        VStack(alignment: .leading, spacing: 12) {
                            R2TileHeader(title: "Owe you", symbol: "arrow.down.circle.fill")
                            ForEach(store.owing) { person in
                                P2QuickRow(person: person, code: store.code) {
                                    PPReminderButton(store: store, person: person) {
                                        Label("Remind \(person.name)", systemImage: "bubble.left.and.text.bubble.right.fill")
                                    }
                                    PPSettleAllButton(store: store, person: person) {
                                        Label("Settle all with \(person.name)", systemImage: "checkmark")
                                    }
                                }
                                .buttonStyle(P2IconButtonStyle(kind: .tinted))
                                if person.id != store.owing.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                }
                P2SettledUpTile(store: store)
                P2ArchivedFootnote(store: store)
            }
            .padding()
        }
        .background { R2Backdrop() }
        .overlay {
            if store.people.isEmpty {
                P2EmptyState(store: store)
            }
        }
        .ppListChrome(store: store)
        .environment(\.r2Surface, surface)
    }
}

struct SaffronPerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID
    var surface: R2Surface = .glass

    @State private var payment: P2Payment?

    var body: some View {
        if let person = store.person(id) {
            ScrollView {
                VStack(spacing: r2TileSpacing) {
                    P2PersonHeader(person: person, code: store.code)
                    P2PersonActions(store: store, person: person, kind: .tinted)
                    if !person.openShares.isEmpty {
                        R2Tile(padding: 18) {
                            VStack(alignment: .leading, spacing: 14) {
                                R2TileHeader(title: "Open shares", symbol: "clock.fill")
                                ForEach(person.openShares) { share in
                                    VStack(alignment: .leading, spacing: 10) {
                                        PPShareRow(share: share, code: store.code)
                                        HStack(spacing: 8) {
                                            Button("Paid in Full", systemImage: "checkmark") {
                                                payment = P2Payment(personID: person.id, shareID: share.id, mode: .full)
                                            }
                                            .buttonStyle(P2ButtonStyle(kind: .filled))
                                            Button("Part…") {
                                                payment = P2Payment(personID: person.id, shareID: share.id, mode: .part)
                                            }
                                            .buttonStyle(P2ButtonStyle(kind: .outline))
                                        }
                                    }
                                    if share.id != person.openShares.last?.id {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }
                    P2SettledTile(person: person, code: store.code)
                    P2NoSplitsNote(person: person)
                }
                .padding()
            }
            .background { R2Backdrop() }
            .ppPersonChrome(store: store, person: person)
            .sheet(item: $payment) { P2RepaymentSheet(store: store, payment: $0) }
            .environment(\.r2Surface, surface)
        }
    }
}

#Preview("Saffron") {
    PPHost { SaffronPeople(store: $0) } person: { SaffronPerson(store: $0, id: $1) }
}

#Preview("Saffron · Marta") {
    PPHost(opening: "marta") { SaffronPeople(store: $0) } person: { SaffronPerson(store: $0, id: $1) }
}

#Preview("Saffron · No glass") {
    PPHost(opening: "luis") {
        SaffronPeople(store: $0, surface: .solid)
    } person: {
        SaffronPerson(store: $0, id: $1, surface: .solid)
    }
}

#Preview("Saffron · Settled up") {
    PPHost(store: .settledUp) { SaffronPeople(store: $0) } person: { SaffronPerson(store: $0, id: $1) }
}
#endif
