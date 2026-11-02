//
//  01-GenmaichaPeople.swift
//  Finlark
//
//  FIN-9 People, Round 7 "Genmaicha": the candidate for the final People design. Sencha's layout with
//  the owner's last calls: no partial repayments from a share, so each share has one control, a check
//  that records all that's left (SPL-006); Settle All for two or more shares (SPL-008); Undo in a toast
//  after both; and the share reminder (NTF-003) kept in the bar. Every button uses the system's blue
//  Liquid Glass, `.glassProminent`. The person screen is Financier.
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

// MARK: - Pieces

/// A round check in the system's blue Liquid Glass. Round 8 reuses it.
struct GenmaichaCheck: View {
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
    PPHost { GenmaichaPeople(store: $0) } person: { FinancierPerson(store: $0, id: $1) }
}

#Preview("Genmaicha · Settled up") {
    PPHost(store: .settledUp) { GenmaichaPeople(store: $0) } person: { FinancierPerson(store: $0, id: $1) }
}

#Preview("Genmaicha · Empty") {
    PPHost(store: .empty) { GenmaichaPeople(store: $0) } person: { FinancierPerson(store: $0, id: $1) }
}

#Preview("Genmaicha · Dark") {
    PPHost(opening: "luis") { GenmaichaPeople(store: $0) } person: { FinancierPerson(store: $0, id: $1) }
        .preferredColorScheme(.dark)
}
#endif
