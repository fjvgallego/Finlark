//
//  PeopleRound9Components.swift
//  Finlark
//
//  FIN-9 People, Round 9: the owner's picks from Round 8. The header stays plain, not on glass, and
//  Settle All sits either under it or pinned above the tab bar (SPL-008). The shares are Affogato's
//  rows with what's left trailing, and under each row two wide buttons: Add Repayment, which opens the
//  repayment sheet on part of it (SPL-007), and Mark as Paid, which records all that's left with Undo
//  (SPL-006). The list stays Genmaicha's. Every button is the system's blue Liquid Glass.
//

#if DEBUG
import SwiftUI

// MARK: - Options

/// Where Settle All goes.
enum P9SettlePlacement {
    /// Under the name and what they owe.
    case underHeader
    /// Above the tab bar, always in reach.
    case pinned
}

/// How Settle All looks.
enum P9SettleLook {
    /// A full-width bar with the total.
    case fullWidth
    /// A centered pill, since the header already says the total.
    case pill
    /// A glass bar with the total and share count leading and the button trailing. For `.pinned`.
    case summaryBar
}

/// How the two buttons under a share relate.
enum P9ButtonPair {
    /// Add Repayment in plain glass, Mark as Paid in blue glass: the full repayment leads.
    case secondaryAndPrimary
    /// Both in blue glass, as equals.
    case bothPrimary
}

// MARK: - Person screen

/// The person screen every Round 9 variant shares, set up by the options (PPL-003, SPL-006…008).
struct P9PersonScreen: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID
    var settlePlacement: P9SettlePlacement = .underHeader
    var settleLook: P9SettleLook = .fullWidth
    var buttonPair: P9ButtonPair = .secondaryAndPrimary
    /// A bar under a partly paid share's text, showing how much came back.
    var showsProgress = false

    @State private var payment: P2Payment?
    @State private var undo: P2Undo?

    var body: some View {
        if let person = store.person(id) {
            let settleAll = { undo = store.settleAllWithUndo(person) }

            ScrollView {
                VStack(spacing: r2TileSpacing) {
                    P2PersonHeader(person: person, code: store.code)
                    if person.showsSettleAll, settlePlacement == .underHeader {
                        settle(person, action: settleAll)
                    }
                    if !person.openShares.isEmpty {
                        R2Tile(padding: 18) {
                            VStack(alignment: .leading, spacing: 14) {
                                R2TileHeader(title: "Open shares", symbol: "clock.fill")
                                ForEach(person.openShares) { share in
                                    P9ShareRow(
                                        share: share,
                                        code: store.code,
                                        buttonPair: buttonPair,
                                        showsProgress: showsProgress,
                                        addRepayment: { payment = P2Payment(personID: person.id, shareID: share.id, mode: .part) },
                                        markPaid: { undo = store.markPaidWithUndo(share, of: person) }
                                    )
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
            // Inside the pinned bar's inset, so the toast shows above the bar, not over it.
            .p2UndoToast($undo, store: store)
            .safeAreaInset(edge: .bottom) {
                if person.showsSettleAll, settlePlacement == .pinned {
                    settle(person, action: settleAll)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
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
            .sheet(item: $payment) { P2RepaymentSheet(store: store, payment: $0, usesSystemGlass: true) }
        }
    }

    @ViewBuilder
    private func settle(_ person: PPPerson, action: @escaping () -> Void) -> some View {
        switch settleLook {
        case .fullWidth:
            P8SettleAllButton(person: person, code: store.code, action: action)
        case .pill:
            Button(action: action) {
                Label("Settle All", systemImage: "checkmark.circle.fill")
                    .padding(.horizontal, 8)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .accessibilityLabel(Text("Settle all, \(person.owed.formatted(.currency(code: store.code)))"))
        case .summaryBar:
            P9SummaryBar(person: person, code: store.code, action: action)
        }
    }
}

// MARK: - Share row

/// Affogato's row with what's left trailing, and the two buttons under it, side by side, or stacked
/// at accessibility sizes.
struct P9ShareRow: View {
    let share: PPShare
    let code: String
    let buttonPair: P9ButtonPair
    var showsProgress = false
    let addRepayment: () -> Void
    let markPaid: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                P8CategoryIcon(category: share.category)
                VStack(alignment: .leading, spacing: 8) {
                    P8InfoAndAmount {
                        P5ShareTitle(share: share, code: code)
                    } amount: {
                        P8Remaining(share: share, code: code)
                    }
                    if showsProgress, share.paid > 0 {
                        PPProgressBar(share: share, color: .accentColor)
                    }
                }
            }

            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(spacing: 8))
                : AnyLayout(HStackLayout(spacing: 10))
            layout {
                Group {
                    switch buttonPair {
                    case .secondaryAndPrimary:
                        addButton.buttonStyle(.glass)
                    case .bothPrimary:
                        addButton.buttonStyle(.glassProminent)
                    }
                }
                Button(action: markPaid) {
                    Label("Mark as Paid", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .accessibilityLabel(Text("Mark \(share.ticket) as paid"))
            }
            .lineLimit(1)
            .minimumScaleFactor(0.85)
        }
    }

    private var addButton: some View {
        Button(action: addRepayment) {
            Label("Add Repayment", systemImage: "plus")
                .frame(maxWidth: .infinity)
        }
        .accessibilityLabel(Text("Add repayment for \(share.ticket)"))
    }
}

// MARK: - Settle All bar

/// A pinned glass bar: what's open on the leading side, Settle All trailing, or under it at
/// accessibility sizes.
struct P9SummaryBar: View {
    let person: PPPerson
    let code: String
    let action: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10))
            : AnyLayout(HStackLayout(spacing: 12))
        layout {
            VStack(alignment: .leading, spacing: 0) {
                Text(person.owed, format: .currency(code: code))
                    .font(.headline)
                    .monospacedDigit()
                Text("^[\(person.openShares.count) open share](inflect: true)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            if !dynamicTypeSize.isAccessibilitySize {
                Spacer(minLength: 8)
            }
            Button(action: action) {
                Label("Settle All", systemImage: "checkmark.circle.fill")
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .accessibilityLabel(Text("Settle all, \(person.owed.formatted(.currency(code: code)))"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 20)
        .padding(.trailing, 8)
        .padding(.vertical, 8)
        .glassEffect(.regular, in: .rect(cornerRadius: 28))
    }
}
#endif
