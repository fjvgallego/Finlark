//
//  PeopleRound8Components.swift
//  Finlark
//
//  FIN-9 People, Round 8: Genmaicha with other takes on the open shares and on Settle All. The list,
//  the person's header, the settled shares, the reminder in the bar and the Undo toast stay as they
//  are. Every action keeps the system's blue Liquid Glass (`.glassProminent`), and a share is still
//  paid back in full or not at all (SPL-006, SPL-008). A partly paid share still shows what came back
//  (PPL-003).
//

#if DEBUG
import SwiftUI

// MARK: - Actions

/// What a variant's open shares and Settle All can do. Both record today's date and show Undo.
struct P8Actions {
    let markPaid: (PPShare) -> Void
    let settleAll: () -> Void
}

extension PPPerson {
    /// Settle All only shows for two or more open shares: with one, paying that share is the same.
    var showsSettleAll: Bool { openShares.count > 1 }

    /// Open shares, oldest first, for variants that read as a timeline.
    var openSharesOldestFirst: [PPShare] { openShares.sorted { $0.date < $1.date } }
}

// MARK: - Person screen

/// Genmaicha's person screen with the middle drawn by the variant: the open shares and Settle All,
/// and optionally a bar pinned above the tab bar. The header, settled shares, reminder and Undo toast
/// are shared (PPL-003, NTF-003).
struct P8PersonScreen<Content: View, Pinned: View>: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID
    /// Off when the variant draws the header itself.
    var showsHeader = true
    @ViewBuilder let content: (PPPerson, P8Actions) -> Content
    @ViewBuilder let pinned: (PPPerson, P8Actions) -> Pinned

    @State private var undo: P2Undo?

    var body: some View {
        if let person = store.person(id) {
            let actions = P8Actions(
                markPaid: { share in undo = store.markPaidWithUndo(share, of: person) },
                settleAll: { undo = store.settleAllWithUndo(person) }
            )

            ScrollView {
                VStack(spacing: r2TileSpacing) {
                    if showsHeader {
                        P2PersonHeader(person: person, code: store.code)
                    }
                    content(person, actions)
                    P2SettledTile(person: person, code: store.code)
                    P2NoSplitsNote(person: person)
                }
                .padding()
            }
            // The toast sits inside the pinned bar's inset, so it shows above the bar, not over it.
            .p2UndoToast($undo, store: store)
            .safeAreaInset(edge: .bottom) {
                pinned(person, actions)
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
        }
    }
}

extension P8PersonScreen where Pinned == EmptyView {
    init(
        store: PPStore,
        id: PPPerson.ID,
        showsHeader: Bool = true,
        @ViewBuilder content: @escaping (PPPerson, P8Actions) -> Content
    ) {
        self.init(store: store, id: id, showsHeader: showsHeader, content: content) { _, _ in EmptyView() }
    }
}

// MARK: - Settle All

/// Genmaicha's full-width Settle All with the total.
struct P8SettleAllButton: View {
    let person: PPPerson
    let code: String
    let action: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Button(action: action) {
            Label {
                // At accessibility sizes the total gets its own line instead of wrapping at the dot.
                if dynamicTypeSize.isAccessibilitySize {
                    VStack {
                        Text("Settle All")
                        Text(person.owed, format: .currency(code: code))
                    }
                    .monospacedDigit()
                } else {
                    Text("Settle All · \(person.owed, format: .currency(code: code))")
                        .monospacedDigit()
                }
            } icon: {
                Image(systemName: "checkmark.circle.fill")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glassProminent)
        .controlSize(.large)
    }
}

// MARK: - Share pieces

/// What's left on a share, large, with "left" under it.
struct P8Remaining: View {
    let share: PPShare
    let code: String
    var font: Font = .headline

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        // Trailing beside the share, leading once it moves under it at accessibility sizes.
        VStack(alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .trailing, spacing: 0) {
            Text(share.remaining, format: .currency(code: code))
                .font(font)
                .monospacedDigit()
            Text("left")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

/// Info leading and an amount trailing, or the amount under the info at accessibility sizes.
struct P8InfoAndAmount<Info: View, Amount: View>: View {
    @ViewBuilder let info: Info
    @ViewBuilder let amount: Amount

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 4) {
                info
                amount
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                info
                    .frame(maxWidth: .infinity, alignment: .leading)
                amount
            }
        }
    }
}

/// The category icon, left out at accessibility sizes so the text keeps the width.
struct P8CategoryIcon: View {
    let category: ExplorationCategory

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if !dynamicTypeSize.isAccessibilitySize {
            ExplorationCategoryIcon(category: category)
        }
    }
}
#endif
