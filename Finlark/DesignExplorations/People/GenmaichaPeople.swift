//
//  GenmaichaPeople.swift
//  Finlark
//
//  FIN-9 People "Genmaicha": the People list. A check on each row that owes settles all that person
//  owes (SPL-008), with Undo in a toast. Every button uses the system's blue Liquid Glass,
//  `.glassProminent`. The person screen is Financier.
//

#if DEBUG
import SwiftUI

// MARK: - List

/// The owed header and Settled up tile, and a glass check on each row that owes: one tap settles all
/// that person owes, with Undo (PPL-002, SPL-008).
struct GenmaichaPeople: View {
    @Bindable var store: PPStore

    @State private var undo: PPUndo?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: hmTileSpacing) {
                if !store.active.isEmpty {
                    PPOwedHeader(store: store)
                }
                if !store.owing.isEmpty {
                    HMTile(padding: 18) {
                        VStack(alignment: .leading, spacing: 12) {
                            HMTileHeader(title: "Owe you", symbol: "arrow.down.circle.fill")
                            ForEach(store.owing) { person in
                                PPQuickRow(person: person, code: store.code) {
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
                PPSettledUpTile(store: store)
                PPArchivedFootnote(store: store)
            }
            .padding()
        }
        .background { HMBackdrop() }
        .overlay {
            if store.people.isEmpty {
                GenmaichaEmptyState(store: store)
            }
        }
        .ppListChrome(store: store)
        .ppUndoToast($undo, store: store)
    }
}

// MARK: - Pieces

/// A round check in the system's blue Liquid Glass.
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
