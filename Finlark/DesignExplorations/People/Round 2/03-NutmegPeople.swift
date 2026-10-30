//
//  03-NutmegPeople.swift
//  Finlark
//
//  FIN-9 People, Round 2 "Nutmeg": a card per person. Everyone who owes you gets their own tile with
//  Remind and Settle all as full-width buttons, so the actions read as words, not icons. The person is
//  Dahlia's with filled squares, and each open share is a card too, with a bar for what's been paid
//  back and its own Paid in Full and Part buttons (SPL-006, SPL-007). Glass tiles.
//

#if DEBUG
import SwiftUI

struct NutmegPeople: View {
    @Bindable var store: PPStore
    var surface: R2Surface = .glass

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: r2TileSpacing) {
                if !store.active.isEmpty {
                    P2OwedHeader(store: store)
                }
                ForEach(store.owing) { person in
                    R2Tile(padding: 16) {
                        VStack(spacing: 14) {
                            P2PersonLink(person: person, code: store.code, avatarSize: 44)
                            ViewThatFits(in: .horizontal) {
                                HStack(spacing: 10) { actions(person) }
                                VStack(spacing: 10) { actions(person) }
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

    @ViewBuilder
    private func actions(_ person: PPPerson) -> some View {
        PPReminderButton(store: store, person: person) {
            Label("Remind", systemImage: "bubble.left.and.text.bubble.right")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(P2ButtonStyle(kind: .outline, shape: .rounded))
        PPSettleAllButton(store: store, person: person) {
            Label("Settle All", systemImage: "checkmark.circle.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(P2ButtonStyle(kind: .filled, shape: .rounded))
    }
}

struct NutmegPerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID
    var surface: R2Surface = .glass

    @State private var payment: P2Payment?

    var body: some View {
        if let person = store.person(id) {
            ScrollView {
                VStack(alignment: .leading, spacing: r2TileSpacing) {
                    P2PersonHeader(person: person, code: store.code)
                    P2PersonActions(store: store, person: person, kind: .filled)
                    if !person.openShares.isEmpty {
                        Text("Open shares")
                            .font(.headline)
                            .padding(.top, 8)
                            .padding(.horizontal, 4)
                            .accessibilityAddTraits(.isHeader)
                    }
                    ForEach(person.openShares) { share in
                        R2Tile(padding: 16) {
                            VStack(alignment: .leading, spacing: 12) {
                                PPShareRow(share: share, code: store.code, showsBar: true)
                                ViewThatFits(in: .horizontal) {
                                    HStack(spacing: 10) { buttons(share, of: person) }
                                    VStack(spacing: 10) { buttons(share, of: person) }
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

    @ViewBuilder
    private func buttons(_ share: PPShare, of person: PPPerson) -> some View {
        Button {
            payment = P2Payment(personID: person.id, shareID: share.id, mode: .part)
        } label: {
            Text("Part…")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(P2ButtonStyle(kind: .tinted, shape: .rounded))
        Button {
            payment = P2Payment(personID: person.id, shareID: share.id, mode: .full)
        } label: {
            Label("Paid in Full", systemImage: "checkmark")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(P2ButtonStyle(kind: .filled, shape: .rounded))
    }
}

#Preview("Nutmeg") {
    PPHost { NutmegPeople(store: $0) } person: { NutmegPerson(store: $0, id: $1) }
}

#Preview("Nutmeg · Luis") {
    PPHost(opening: "luis") { NutmegPeople(store: $0) } person: { NutmegPerson(store: $0, id: $1) }
}

#Preview("Nutmeg · No glass") {
    PPHost(opening: "marta") {
        NutmegPeople(store: $0, surface: .solid)
    } person: {
        NutmegPerson(store: $0, id: $1, surface: .solid)
    }
}
#endif
