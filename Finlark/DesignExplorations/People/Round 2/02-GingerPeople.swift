//
//  02-GingerPeople.swift
//  Finlark
//
//  FIN-9 People, Round 2 "Ginger": quick actions kept out of the way. Rows stay clean, with a small
//  "more" button (and the same menu on touch and hold) for Remind and Settle all. On the person, each
//  open share has a tick: one tap marks it paid today, with Undo in a toast, and touch and hold
//  records part of it or picks another date (SPL-006, SPL-007). Glass tiles.
//

#if DEBUG
import SwiftUI

struct GingerPeople: View {
    @Bindable var store: PPStore
    var surface: R2Surface = .glass

    @State private var settling: PPPerson?

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
                                    Menu {
                                        actions(person)
                                    } label: {
                                        Label("Actions for \(person.name)", systemImage: "ellipsis")
                                    }
                                    .menuStyle(.button)
                                    .buttonStyle(P2IconButtonStyle(kind: .tinted, tint: .secondary))
                                }
                                .contextMenu { actions(person) }
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
        .alert(
            Text("Settle all with \(settling?.name ?? "")?"),
            isPresented: Binding { settling != nil } set: { if !$0 { settling = nil } },
            presenting: settling
        ) { person in
            Button("Cancel", role: .cancel) {}
            Button("Settle All") { store.settleAll(person.id) }
        } message: { person in
            PPSettleMessage(person: person, code: store.code)
        }
        .environment(\.r2Surface, surface)
    }

    @ViewBuilder
    private func actions(_ person: PPPerson) -> some View {
        PPReminderButton(store: store, person: person)
        Button("Settle All…", systemImage: "checkmark.circle") { settling = person }
    }
}

struct GingerPerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID
    var surface: R2Surface = .glass

    @State private var payment: P2Payment?
    @State private var undo: P2Undo?

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
                                    HStack(alignment: .top, spacing: 12) {
                                        Button {
                                            undo = store.markPaidWithUndo(share, of: person)
                                        } label: {
                                            Label("Mark \(share.ticket) as paid", systemImage: "circle")
                                                .labelStyle(.iconOnly)
                                                .font(.title2)
                                                .foregroundStyle(.tint)
                                                .frame(minWidth: 44, minHeight: 44)
                                                .contentShape(.rect)
                                        }
                                        .buttonStyle(.plain)
                                        PPShareRow(share: share, code: store.code, showsIcon: false)
                                    }
                                    .contextMenu {
                                        Button("Record Part…", systemImage: "circle.lefthalf.filled") {
                                            payment = P2Payment(personID: person.id, shareID: share.id, mode: .part)
                                        }
                                        Button("Paid on Another Date…", systemImage: "calendar") {
                                            payment = P2Payment(personID: person.id, shareID: share.id, mode: .full)
                                        }
                                    }
                                    .accessibilityActions {
                                        Button("Record Part") {
                                            payment = P2Payment(personID: person.id, shareID: share.id, mode: .part)
                                        }
                                    }
                                    if share.id != person.openShares.last?.id {
                                        Divider()
                                    }
                                }
                                Text("Tick a share when it's paid back. Touch and hold to record part of it.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
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
            .p2UndoToast($undo, store: store)
            .environment(\.r2Surface, surface)
        }
    }
}

#Preview("Ginger") {
    PPHost { GingerPeople(store: $0) } person: { GingerPerson(store: $0, id: $1) }
}

#Preview("Ginger · Luis") {
    PPHost(opening: "luis") { GingerPeople(store: $0) } person: { GingerPerson(store: $0, id: $1) }
}

#Preview("Ginger · No glass") {
    PPHost(opening: "marta") {
        GingerPeople(store: $0, surface: .solid)
    } person: {
        GingerPerson(store: $0, id: $1, surface: .solid)
    }
}
#endif
