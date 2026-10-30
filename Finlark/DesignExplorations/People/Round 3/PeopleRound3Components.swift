//
//  PeopleRound3Components.swift
//  Finlark
//
//  FIN-9 People, Round 3: Ginger with Saffron's round check button, which the owner picked from Round 2.
//  The list is settled, so the variants share it: Iris's header, a check on each row that completes the
//  repayment, and Undo in a toast instead of a confirmation. Remind is gone from the list and the main
//  actions; the share reminder (NTF-003) stays as a toolbar icon on the person until the owner decides
//  whether it stays in v1. The variants differ only in how a single share is paid on the person.
//

#if DEBUG
import SwiftUI

// MARK: - Actions

extension PPStore {
    /// Settle all for a person today (SPL-008) and returns what Undo needs.
    func settleAllWithUndo(_ person: PPPerson) -> P2Undo? {
        let total = person.owed.formatted(.currency(code: code))
        let repayments = settleAll(person.id)
        guard !repayments.isEmpty else { return nil }
        return P2Undo(
            message: String(localized: "Settled \(total) with \(person.name)"),
            personID: person.id,
            repaymentIDs: repayments.map(\.id)
        )
    }
}

/// Saffron's round check. One tap records the repayment; the toast that follows can undo it.
struct P3CheckButton: View {
    /// What VoiceOver reads, like "Mark Cinema as paid".
    let title: Text
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label {
                title
            } icon: {
                Image(systemName: "checkmark")
            }
        }
        .buttonStyle(P2IconButtonStyle(kind: .tinted))
    }
}

/// A row with the check trailing it, or under it at accessibility sizes.
struct P3CheckLine<Content: View, Check: View>: View {
    @ViewBuilder let content: Content
    @ViewBuilder let check: Check

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 10) {
                content
                check
            }
        } else {
            HStack(alignment: .center, spacing: 12) {
                content
                check
            }
        }
    }
}

// MARK: - List

/// Ginger's list with Saffron's check on each row that owes: one tap settles everything that person
/// owes, with Undo (PPL-002, SPL-008).
struct P3People: View {
    @Bindable var store: PPStore
    var surface: R2Surface = .glass

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
                                    P3CheckButton(title: Text("Settle all with \(person.name)")) {
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
                P2EmptyState(store: store)
            }
        }
        .ppListChrome(store: store)
        .p2UndoToast($undo, store: store)
        .environment(\.r2Surface, surface)
    }
}

// MARK: - Person

/// What a variant's share row can do: mark the share paid today (with Undo), or open the repayment
/// sheet for part of it or another date.
struct P3ShareActions {
    let markPaid: () -> Void
    let recordPart: () -> Void
    let pickDate: () -> Void
}

/// Dahlia's person screen without Remind: the header, Settle All when there's more than one open share,
/// the open shares as the variant draws them, then the settled ones (PPL-003). The reminder (NTF-003)
/// is a share icon in the bar.
struct P3PersonScreen<ShareRow: View>: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID
    var surface: R2Surface = .glass
    var hint: LocalizedStringKey = "Check a share when it's paid back. Touch and hold to record part of it."
    @ViewBuilder let shareRow: (PPShare, P3ShareActions) -> ShareRow

    @State private var payment: P2Payment?
    @State private var undo: P2Undo?

    var body: some View {
        if let person = store.person(id) {
            ScrollView {
                VStack(spacing: r2TileSpacing) {
                    P2PersonHeader(person: person, code: store.code)
                    if person.openShares.count > 1 {
                        Button {
                            undo = store.settleAllWithUndo(person)
                        } label: {
                            Label {
                                Text("Settle All · \(person.owed, format: .currency(code: store.code))")
                                    .monospacedDigit()
                            } icon: {
                                Image(systemName: "checkmark.circle.fill")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(P2ButtonStyle(kind: .tinted, shape: .rounded, isLarge: true))
                    }
                    if !person.openShares.isEmpty {
                        R2Tile(padding: 18) {
                            VStack(alignment: .leading, spacing: 14) {
                                R2TileHeader(title: "Open shares", symbol: "clock.fill")
                                ForEach(person.openShares) { share in
                                    let actions = actions(share, of: person)
                                    shareRow(share, actions)
                                        .contextMenu {
                                            Button("Record Part…", systemImage: "circle.lefthalf.filled", action: actions.recordPart)
                                            Button("Paid on Another Date…", systemImage: "calendar", action: actions.pickDate)
                                        }
                                        .accessibilityActions {
                                            Button("Record Part", action: actions.recordPart)
                                            Button("Paid on Another Date", action: actions.pickDate)
                                        }
                                    if share.id != person.openShares.last?.id {
                                        Divider()
                                    }
                                }
                                Text(hint)
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
            .toolbar {
                if person.owes {
                    ToolbarItem(placement: .topBarTrailing) {
                        PPReminderButton(store: store, person: person) {
                            Label("Share Reminder", systemImage: "square.and.arrow.up")
                        }
                    }
                }
            }
            .sheet(item: $payment) { P2RepaymentSheet(store: store, payment: $0) }
            .p2UndoToast($undo, store: store)
            .environment(\.r2Surface, surface)
        }
    }

    private func actions(_ share: PPShare, of person: PPPerson) -> P3ShareActions {
        P3ShareActions(
            markPaid: { undo = store.markPaidWithUndo(share, of: person) },
            recordPart: { payment = P2Payment(personID: person.id, shareID: share.id, mode: .part) },
            pickDate: { payment = P2Payment(personID: person.id, shareID: share.id, mode: .full) }
        )
    }
}
#endif
