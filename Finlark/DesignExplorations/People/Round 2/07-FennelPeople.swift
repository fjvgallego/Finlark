//
//  07-FennelPeople.swift
//  Finlark
//
//  FIN-9 People, Round 2 "Fennel": pick what was paid. No glass. On the person, open shares are a
//  checklist: tick the ones a friend paid back and one button records them all, so "I'll send you
//  the dinner, not the cinema" is two taps (SPL-006). Select All covers Settle all, Undo follows, and
//  touch and hold records part of a share (SPL-007). The list keeps a Remind pill on each row.
//

#if DEBUG
import SwiftUI

struct FennelPeople: View {
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
                                P2QuickRow(person: person, code: store.code) {
                                    PPReminderButton(store: store, person: person) {
                                        Text("Remind")
                                    }
                                    .buttonStyle(P2ButtonStyle(kind: .tinted))
                                    .accessibilityLabel(Text("Remind \(person.name)"))
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
        .environment(\.r2Surface, surface)
    }
}

struct FennelPerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID
    var surface: R2Surface = .solid

    @State private var selection: Set<PPShare.ID> = []
    @State private var payment: P2Payment?
    @State private var undo: P2Undo?

    var body: some View {
        if let person = store.person(id) {
            let picked = person.openShares.filter { selection.contains($0.id) }
            let total = picked.reduce(Decimal(0)) { $0 + $1.remaining }

            ScrollView {
                VStack(spacing: r2TileSpacing) {
                    P2PersonHeader(person: person, code: store.code)
                    if person.owes {
                        HStack(spacing: r2TileSpacing) {
                            PPReminderButton(store: store, person: person) {
                                Label("Remind", systemImage: "bubble.left.and.text.bubble.right.fill")
                            }
                        }
                        .buttonStyle(P2SquareButtonStyle(kind: .tinted))
                    }
                    if !person.openShares.isEmpty {
                        R2Tile(padding: 18) {
                            VStack(alignment: .leading, spacing: 12) {
                                R2TileHeader(title: "Open shares", symbol: "checklist") {
                                    Button {
                                        if picked.count == person.openShares.count {
                                            selection = []
                                        } else {
                                            selection = Set(person.openShares.map(\.id))
                                        }
                                    } label: {
                                        if picked.count == person.openShares.count {
                                            Text("Select None")
                                        } else {
                                            Text("Select All")
                                        }
                                    }
                                    .buttonStyle(P2ButtonStyle(kind: .tinted))
                                }
                                ForEach(person.openShares) { share in
                                    checkRow(share, of: person)
                                    if share.id != person.openShares.last?.id {
                                        Divider()
                                    }
                                }
                                Text("Tick what was paid back. Touch and hold a share to record part of it.")
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
            .safeAreaInset(edge: .bottom) {
                if !picked.isEmpty {
                    Button {
                        record(picked, of: person)
                    } label: {
                        Text("Mark ^[\(picked.count) share](inflect: true) Paid · \(total, format: .currency(code: store.code))")
                            .monospacedDigit()
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(P2ButtonStyle(kind: .filled, shape: .rounded, isLarge: true))
                    .padding()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.snappy, value: picked.isEmpty)
            .background { R2Backdrop() }
            .ppPersonChrome(store: store, person: person)
            .sheet(item: $payment) { P2RepaymentSheet(store: store, payment: $0) }
            .p2UndoToast($undo, store: store)
            .environment(\.r2Surface, surface)
        }
    }

    private func checkRow(_ share: PPShare, of person: PPPerson) -> some View {
        let isOn = selection.contains(share.id)

        return Button {
            if isOn { selection.remove(share.id) } else { selection.insert(share.id) }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isOn ? AnyShapeStyle(.tint) : AnyShapeStyle(.tertiary))
                    .accessibilityHidden(true)
                PPShareRow(share: share, code: store.code, showsIcon: false)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
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
    }

    /// A repayment for what's left on each picked share, dated today, undone together.
    private func record(_ shares: [PPShare], of person: PPPerson) {
        let total = shares.reduce(Decimal(0)) { $0 + $1.remaining }
        let ids = shares.compactMap { store.markPaid($0.id, of: person.id)?.id }
        selection = []
        undo = P2Undo(
            message: String(localized: "Recorded \(total.formatted(.currency(code: store.code))) from \(person.name)"),
            personID: person.id,
            repaymentIDs: ids
        )
    }
}

#Preview("Fennel") {
    PPHost { FennelPeople(store: $0) } person: { FennelPerson(store: $0, id: $1) }
}

#Preview("Fennel · Marta") {
    PPHost(opening: "marta") { FennelPeople(store: $0) } person: { FennelPerson(store: $0, id: $1) }
}

#Preview("Fennel · Glass") {
    PPHost(opening: "luis") {
        FennelPeople(store: $0, surface: .glass)
    } person: {
        FennelPerson(store: $0, id: $1, surface: .glass)
    }
}
#endif
