//
//  05-PaprikaPeople.swift
//  Finlark
//
//  FIN-9 People, Round 2 "Paprika": no glass, ink buttons. Solid cards on the grouped background, and
//  buttons in the text color, inverted, so they read as the app's own. Each owing row has a second line
//  with Remind and Settle pills. On the person, every open share has a Pay button that asks how: paid
//  in full today (with Undo), part of it, or on another date (SPL-006, SPL-007).
//

#if DEBUG
import SwiftUI

struct PaprikaPeople: View {
    @Bindable var store: PPStore
    var surface: R2Surface = .solid

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
                                VStack(alignment: .leading, spacing: 10) {
                                    P2PersonLink(person: person, code: store.code)
                                    P2PillLine {
                                        PPReminderButton(store: store, person: person) {
                                            Label("Remind", systemImage: "bubble.left.and.text.bubble.right")
                                        }
                                        .buttonStyle(P2ButtonStyle(kind: .outline, tint: .primary))
                                        PPSettleAllButton(store: store, person: person) {
                                            Label("Settle", systemImage: "checkmark")
                                        }
                                        .buttonStyle(P2ButtonStyle(kind: .ink))
                                        .accessibilityLabel(Text("Settle all with \(person.name)"))
                                    }
                                }
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
                P2EmptyState(store: store, kind: .ink)
            }
        }
        .ppListChrome(store: store)
        .environment(\.r2Surface, surface)
    }
}

struct PaprikaPerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID
    var surface: R2Surface = .solid

    @State private var asking: PPShare?
    @State private var payment: P2Payment?
    @State private var undo: P2Undo?

    var body: some View {
        if let person = store.person(id) {
            ScrollView {
                VStack(spacing: r2TileSpacing) {
                    P2PersonHeader(person: person, code: store.code)
                    P2PersonActions(store: store, person: person, kind: .ink)
                    if !person.openShares.isEmpty {
                        R2Tile(padding: 18) {
                            VStack(alignment: .leading, spacing: 14) {
                                R2TileHeader(title: "Open shares", symbol: "clock.fill")
                                ForEach(person.openShares) { share in
                                    VStack(alignment: .trailing, spacing: 10) {
                                        PPShareRow(share: share, code: store.code)
                                        Button("Pay…", systemImage: "arrow.uturn.backward") { asking = share }
                                            .buttonStyle(P2ButtonStyle(kind: .ink))
                                            .accessibilityLabel(Text("Record a repayment for \(share.ticket)"))
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
            .confirmationDialog(
                Text(verbatim: asking?.ticket ?? ""),
                isPresented: Binding { asking != nil } set: { if !$0 { asking = nil } },
                titleVisibility: .visible,
                presenting: asking
            ) { share in
                Button("Paid in Full Today · \(share.remaining.formatted(.currency(code: store.code)))") {
                    undo = store.markPaidWithUndo(share, of: person)
                }
                Button("Record Part…") {
                    payment = P2Payment(personID: person.id, shareID: share.id, mode: .part)
                }
                Button("Paid on Another Date…") {
                    payment = P2Payment(personID: person.id, shareID: share.id, mode: .full)
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(item: $payment) { P2RepaymentSheet(store: store, payment: $0, kind: .ink) }
            .p2UndoToast($undo, store: store)
            .environment(\.r2Surface, surface)
        }
    }
}

#Preview("Paprika") {
    PPHost { PaprikaPeople(store: $0) } person: { PaprikaPerson(store: $0, id: $1) }
}

#Preview("Paprika · Marta") {
    PPHost(opening: "marta") { PaprikaPeople(store: $0) } person: { PaprikaPerson(store: $0, id: $1) }
}

#Preview("Paprika · Glass") {
    PPHost(opening: "luis") {
        PaprikaPeople(store: $0, surface: .glass)
    } person: {
        PaprikaPerson(store: $0, id: $1, surface: .glass)
    }
}

#Preview("Paprika · Empty") {
    PPHost(store: .empty) { PaprikaPeople(store: $0) } person: { PaprikaPerson(store: $0, id: $1) }
}
#endif
