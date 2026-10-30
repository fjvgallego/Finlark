//
//  04-CardamomPeople.swift
//  Finlark
//
//  FIN-9 People, Round 2 "Cardamom": tinted glass. Buttons are indigo-tinted glass pills instead of the
//  system's, and each owing row carries small Remind and Settle all pills under the name. On the
//  person, a share opens its own sheet: share, paid so far, each repayment, and Mark as Paid or Record
//  Part (PPL-003, SPL-006, SPL-007). Glass tiles.
//

#if DEBUG
import SwiftUI

private let cardamomTint = Color.indigo

struct CardamomPeople: View {
    @Bindable var store: PPStore
    var surface: R2Surface = .glass

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
                                        .buttonStyle(ExplorationBrandGlassButtonStyle(tint: cardamomTint, isPrimary: false))
                                        PPSettleAllButton(store: store, person: person) {
                                            Label("Settle All", systemImage: "checkmark")
                                        }
                                        .buttonStyle(ExplorationBrandGlassButtonStyle(tint: cardamomTint, isPrimary: true))
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
        .tint(cardamomTint)
        .environment(\.r2Surface, surface)
    }
}

struct CardamomPerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID
    var surface: R2Surface = .glass

    @State private var selected: P2Payment?
    @State private var undo: P2Undo?

    var body: some View {
        if let person = store.person(id) {
            ScrollView {
                VStack(spacing: r2TileSpacing) {
                    P2PersonHeader(person: person, code: store.code)
                    if person.owes {
                        HStack(spacing: r2TileSpacing) {
                            PPReminderButton(store: store, person: person) {
                                Label("Remind", systemImage: "bubble.left.and.text.bubble.right.fill")
                                    .labelStyle(P2StackedLabelStyle())
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                            }
                            .buttonStyle(ExplorationBrandGlassButtonStyle(tint: cardamomTint, isPrimary: false))
                            if person.openShares.count > 1 {
                                PPSettleAllButton(store: store, person: person) {
                                    Label("Settle All", systemImage: "checkmark.circle.fill")
                                        .labelStyle(P2StackedLabelStyle())
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 6)
                                }
                                .buttonStyle(ExplorationBrandGlassButtonStyle(tint: cardamomTint, isPrimary: false))
                            }
                        }
                    }
                    if !person.openShares.isEmpty {
                        R2Tile(padding: 18) {
                            VStack(alignment: .leading, spacing: 14) {
                                R2TileHeader(title: "Open shares", symbol: "clock.fill")
                                ForEach(person.openShares) { share in
                                    Button {
                                        selected = P2Payment(personID: person.id, shareID: share.id)
                                    } label: {
                                        HStack(spacing: 10) {
                                            PPShareRow(share: share, code: store.code)
                                            R2Chevron()
                                        }
                                        .contentShape(.rect)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityHint(Text("Shows the share and how to record a repayment"))
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
            .sheet(item: $selected) { selection in
                CardamomShareSheet(store: store, selection: selection, undo: $undo)
            }
            .p2UndoToast($undo, store: store)
            .tint(cardamomTint)
            .environment(\.r2Surface, surface)
        }
    }
}

/// One share up close: its figures and repayments, with Mark as Paid (today, one tap) and Record Part.
private struct CardamomShareSheet: View {
    let store: PPStore
    let selection: P2Payment
    @Binding var undo: P2Undo?

    @State private var part: P2Payment?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            if let person = store.person(selection.personID),
               let share = store.share(selection.shareID, of: selection.personID) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack(spacing: 12) {
                            ExplorationCategoryIcon(category: share.category)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(verbatim: share.ticket)
                                    .font(.title3.weight(.bold))
                                Text("\(share.date, format: .dateTime.weekday().day().month()) · total \(share.total, format: .currency(code: store.code))")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .accessibilityElement(children: .combine)

                        HStack(spacing: 24) {
                            TDFigure(title: "Share", value: share.share, code: store.code)
                            TDFigure(title: "Paid", value: share.paid, code: store.code)
                            TDFigure(title: "Left", value: share.remaining, code: store.code)
                        }
                        PPProgressBar(share: share, color: cardamomTint)

                        if !share.repayments.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Repayments")
                                    .font(.headline)
                                ForEach(share.repayments) { repayment in
                                    HStack {
                                        AEDateText(date: repayment.date)
                                        Spacer(minLength: 8)
                                        Text(repayment.amount, format: .currency(code: store.code))
                                            .monospacedDigit()
                                    }
                                    .font(.subheadline)
                                    .accessibilityElement(children: .combine)
                                }
                            }
                        }
                    }
                    .padding()
                }
                .safeAreaInset(edge: .bottom) {
                    if share.isOpen {
                        HStack(spacing: 10) {
                            Button {
                                part = P2Payment(personID: person.id, shareID: share.id, mode: .part)
                            } label: {
                                Text("Record Part")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(ExplorationBrandGlassButtonStyle(tint: cardamomTint, isPrimary: false))
                            Button {
                                undo = store.markPaidWithUndo(share, of: person)
                                dismiss()
                            } label: {
                                Text("Mark as Paid")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(ExplorationBrandGlassButtonStyle(tint: cardamomTint, isPrimary: true))
                        }
                        .padding()
                    }
                }
                .navigationTitle(Text(verbatim: person.name))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done", systemImage: "checkmark", role: .confirm) { dismiss() }
                    }
                }
                .sheet(item: $part) { P2RepaymentSheet(store: store, payment: $0) }
            }
        }
        .presentationDetents([.medium, .large])
        .environment(\.explorationIconStyle, .soft)
    }
}

#Preview("Cardamom") {
    PPHost { CardamomPeople(store: $0) } person: { CardamomPerson(store: $0, id: $1) }
}

#Preview("Cardamom · Luis") {
    PPHost(opening: "luis") { CardamomPeople(store: $0) } person: { CardamomPerson(store: $0, id: $1) }
}

#Preview("Cardamom · No glass") {
    PPHost(opening: "marta") {
        CardamomPeople(store: $0, surface: .solid)
    } person: {
        CardamomPerson(store: $0, id: $1, surface: .solid)
    }
}

#Preview("Cardamom · Share sheet") {
    let store = PPStore.sample
    let luis = store.person("luis")!
    return CardamomShareSheet(
        store: store,
        selection: P2Payment(personID: luis.id, shareID: luis.openShares[1].id),
        undo: .constant(nil)
    )
}
#endif
