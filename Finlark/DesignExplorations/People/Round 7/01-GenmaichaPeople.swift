//
//  01-GenmaichaPeople.swift
//  Finlark
//
//  FIN-9 People, Round 7 "Genmaicha": the candidate for the final People design. Sencha's layout with
//  the owner's last calls: no partial repayments from a share, so each share has one control, a check
//  that records all that's left (SPL-006); Settle All for two or more shares (SPL-008); Undo in a toast
//  after both; and the share reminder (NTF-003) kept in the bar. Every button uses the system's blue
//  Liquid Glass, `.glassProminent`, on the list and on the person alike.
//

#if DEBUG
import SwiftUI

// MARK: - List

/// Iris's header and Settled up tile, and a glass check on each row that owes: one tap settles all
/// that person owes, with Undo (PPL-002, SPL-008).
struct GenmaichaPeople: View {
    @Bindable var store: PPStore

    @State private var undo: P2Undo?

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
                                    GenmaichaCheck(title: Text("Settle all with \(person.name)")) {
                                        undo = store.settleAllWithUndo(person)
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
                GenmaichaEmptyState(store: store)
            }
        }
        .ppListChrome(store: store)
        .p2UndoToast($undo, store: store)
    }
}

// MARK: - Person

/// Dahlia's header, Settle All, the open shares each with a check, then the settled ones (PPL-003).
/// A partly paid share still shows what came back, since PPL-003 lists "paid so far".
struct GenmaichaPerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID

    var body: some View {
        P5PersonScreen(store: store, id: id) { share, actions in
            P5Row {
                VStack(alignment: .leading, spacing: 3) {
                    P5ShareTitle(share: share, code: store.code)
                    Text("\(share.remaining, format: .currency(code: store.code)) left")
                        .font(.headline)
                        .monospacedDigit()
                        .padding(.top, 2)
                }
            } controls: {
                GenmaichaCheck(title: Text("Mark \(share.ticket) as paid"), action: actions.markPaid)
            }
        } settle: { person, settleAll in
            Button(action: settleAll) {
                Label {
                    Text("Settle All · \(person.owed, format: .currency(code: store.code))")
                        .monospacedDigit()
                } icon: {
                    Image(systemName: "checkmark.circle.fill")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
        }
    }
}

// MARK: - Pieces

/// A round check in the system's blue Liquid Glass.
private struct GenmaichaCheck: View {
    /// What VoiceOver reads, like "Mark Cinema as paid".
    let title: Text
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label {
                title
            } icon: {
                Image(systemName: "checkmark")
                    .fontWeight(.semibold)
            }
            .labelStyle(.iconOnly)
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.circle)
    }
}

/// No people yet, with Add Person in the same blue glass.
private struct GenmaichaEmptyState: View {
    let store: PPStore

    @State private var isAdding = false

    var body: some View {
        ContentUnavailableView {
            Label("No People Yet", systemImage: "person.2")
        } description: {
            Text("Add the friends you split expenses with, or add them while you split. They don't need Finlark.")
        } actions: {
            Button("Add Person", systemImage: "plus") { isAdding = true }
                .buttonStyle(.glassProminent)
        }
        .sheet(isPresented: $isAdding) {
            PPAddSheet(store: store)
        }
    }
}

#Preview("Genmaicha") {
    PPHost { GenmaichaPeople(store: $0) } person: { GenmaichaPerson(store: $0, id: $1) }
}

#Preview("Genmaicha · Marta") {
    PPHost(opening: "marta") { GenmaichaPeople(store: $0) } person: { GenmaichaPerson(store: $0, id: $1) }
}

#Preview("Genmaicha · Luis") {
    PPHost(opening: "luis") { GenmaichaPeople(store: $0) } person: { GenmaichaPerson(store: $0, id: $1) }
}

#Preview("Genmaicha · Settled up") {
    PPHost(store: .settledUp) { GenmaichaPeople(store: $0) } person: { GenmaichaPerson(store: $0, id: $1) }
}

#Preview("Genmaicha · Empty") {
    PPHost(store: .empty) { GenmaichaPeople(store: $0) } person: { GenmaichaPerson(store: $0, id: $1) }
}

#Preview("Genmaicha · Dark") {
    PPHost(opening: "luis") { GenmaichaPeople(store: $0) } person: { GenmaichaPerson(store: $0, id: $1) }
        .preferredColorScheme(.dark)
}
#endif
