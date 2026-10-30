//
//  PeopleRound5Components.swift
//  Finlark
//
//  FIN-9 People, Round 5: the owner's notes on Round 4. Recording part of a share must not hide behind a
//  touch and hold, so every share row shows two controls, one for paid in full (SPL-006) and one for
//  part (SPL-007), and neither sits at the leading edge, where a check reads like a to-do list. Anise's
//  glass layout and the Undo toast stay. The list stays Round 3's `P3People`.
//

#if DEBUG
import SwiftUI

// MARK: - Actions

/// What a share row's controls can do.
struct P5ShareActions {
    /// Records what's left, today, with Undo (SPL-006).
    let markPaid: () -> Void
    /// Opens the repayment sheet on Part of it, where the date can change too (SPL-007).
    let recordPart: () -> Void
    /// Records this amount today, with Undo, for controls that pick the amount in place (SPL-007).
    let record: (Decimal) -> Void
}

extension PPStore {
    /// Records part of a share today and returns what Undo needs.
    func recordWithUndo(_ amount: Decimal, on share: PPShare, of person: PPPerson) -> P2Undo? {
        guard let repayment = record(amount, on: share.id, of: person.id) else { return nil }
        let formatted = amount.formatted(.currency(code: code))
        return P2Undo(
            message: String(localized: "Recorded \(formatted) for \(share.ticket)"),
            personID: person.id,
            repaymentIDs: [repayment.id]
        )
    }
}

// MARK: - Person screen

/// Where Settle All goes.
enum P5SettlePlacement {
    /// Under the person's header.
    case underHeader
    /// At the foot of the Open shares tile, after the shares it settles.
    case tileFooter
}

/// Anise's person screen with the share row and Settle All drawn by the variant (PPL-003, SPL-006…008).
/// The repayment sheet and the Undo toast are shared.
struct P5PersonScreen<Row: View, Settle: View>: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID
    var settlePlacement: P5SettlePlacement = .underHeader
    var surface: R2Surface = .glass
    /// Each share on its own card instead of rows with dividers.
    var usesShareCards = false
    @ViewBuilder let row: (PPShare, P5ShareActions) -> Row
    @ViewBuilder let settle: (PPPerson, @escaping () -> Void) -> Settle

    @State private var payment: P2Payment?
    @State private var undo: P2Undo?

    var body: some View {
        if let person = store.person(id) {
            let showsSettle = person.openShares.count > 1
            let settleAll = { undo = store.settleAllWithUndo(person) }

            ScrollView {
                VStack(spacing: r2TileSpacing) {
                    P2PersonHeader(person: person, code: store.code)
                    if showsSettle, settlePlacement == .underHeader {
                        settle(person, settleAll)
                    }
                    if !person.openShares.isEmpty {
                        if usesShareCards {
                            VStack(alignment: .leading, spacing: r2TileSpacing) {
                                Text("Open shares")
                                    .font(.headline)
                                    .padding(.horizontal, 4)
                                    .padding(.top, 4)
                                    .accessibilityAddTraits(.isHeader)
                                ForEach(person.openShares) { share in
                                    row(share, actions(share, of: person))
                                }
                                if showsSettle, settlePlacement == .tileFooter {
                                    settle(person, settleAll)
                                }
                            }
                        } else {
                            R2Tile(padding: 18) {
                                VStack(alignment: .leading, spacing: 14) {
                                    R2TileHeader(title: "Open shares", symbol: "clock.fill")
                                    ForEach(person.openShares) { share in
                                        row(share, actions(share, of: person))
                                        if share.id != person.openShares.last?.id {
                                            Divider()
                                        }
                                    }
                                    if showsSettle, settlePlacement == .tileFooter {
                                        Divider()
                                        settle(person, settleAll)
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

    private func actions(_ share: PPShare, of person: PPPerson) -> P5ShareActions {
        P5ShareActions(
            markPaid: { undo = store.markPaidWithUndo(share, of: person) },
            recordPart: { payment = P2Payment(personID: person.id, shareID: share.id, mode: .part) },
            record: { amount in undo = store.recordWithUndo(amount, on: share, of: person) }
        )
    }
}

// MARK: - Share text

/// The ticket and the date, with the status words for VoiceOver, since rows no longer print "Pending".
struct P5ShareTitle: View {
    let share: PPShare
    let code: String
    var showsPaid = true

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(verbatim: share.ticket)
                .font(.headline)
            Text(share.date, format: .dateTime.weekday().day().month())
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if showsPaid, share.paid > 0 {
                Text("\(share.paid, format: .currency(code: code)) of \(share.share, format: .currency(code: code)) paid")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(share.statusText(code: code))
    }
}

/// A row with the share leading and its controls trailing, or the controls under it at accessibility
/// sizes.
struct P5Row<Info: View, Controls: View>: View {
    @ViewBuilder let info: Info
    @ViewBuilder let controls: Controls

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 10) {
                info
                controls
            }
        } else {
            HStack(alignment: .center, spacing: 12) {
                info
                    .frame(maxWidth: .infinity, alignment: .leading)
                // The controls keep their size; the share's text wraps instead.
                controls
                    .fixedSize()
            }
        }
    }
}

// MARK: - Slide to settle

/// Settle All as a track you slide across, so settling several shares at once is deliberate without a
/// confirmation. A solid accent track with white text keeps contrast in both appearances. VoiceOver
/// gets a plain button.
struct P5SlideToSettle: View {
    let title: Text
    let action: () -> Void

    @State private var offset: CGFloat = 0
    @ScaledMetric private var height: CGFloat = 56
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            let knob = height - 8
            let travel = max(proxy.size.width - knob - 8, 1)

            ZStack(alignment: .leading) {
                Capsule().fill(Color.accentColor.gradient)
                title
                    .font(.headline)
                    .fontDesign(.rounded)
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .opacity(1 - Double(offset / travel))
                    .frame(maxWidth: .infinity)
                    .padding(.leading, knob)
                Circle()
                    .fill(.white)
                    .overlay {
                        Image(systemName: "chevron.right.2")
                            .font(.headline)
                            .foregroundStyle(Color.accentColor)
                    }
                    .frame(width: knob, height: knob)
                    .padding(4)
                    .offset(x: offset)
                    .gesture(
                        DragGesture()
                            .onChanged { offset = min(max($0.translation.width, 0), travel) }
                            .onEnded { _ in
                                if offset > travel * 0.85 {
                                    action()
                                }
                                withAnimation(reduceMotion ? nil : .snappy) { offset = 0 }
                            }
                    )
            }
        }
        .frame(height: height)
        .accessibilityRepresentation {
            Button(action: action) { title }
        }
    }
}
#endif
