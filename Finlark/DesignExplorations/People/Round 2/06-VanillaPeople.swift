//
//  06-VanillaPeople.swift
//  Finlark
//
//  FIN-9 People, Round 2 "Vanilla": quiet and light. No glass, outlined buttons, and almost no color.
//  The list shows no buttons at all: touch and hold a person for Remind and Settle all, so the quick
//  actions are there when wanted and invisible otherwise. On the person, custom tabs switch between
//  open and settled shares, and each open share has a Mark Paid button (SPL-006, SPL-007).
//

#if DEBUG
import SwiftUI

struct VanillaPeople: View {
    @Bindable var store: PPStore
    var surface: R2Surface = .solid

    @State private var settling: PPPerson?

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
                                P2PersonLink(person: person, code: store.code)
                                    .contextMenu {
                                        PPReminderButton(store: store, person: person)
                                        Button("Settle All…", systemImage: "checkmark.circle") { settling = person }
                                    }
                                    .accessibilityActions {
                                        Button("Settle All") { settling = person }
                                    }
                                if person.id != store.owing.last?.id {
                                    Divider()
                                }
                            }
                            Text("Touch and hold someone to remind them or settle up.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
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
                P2EmptyState(store: store, kind: .outline)
            }
        }
        .ppListChrome(store: store)
        .alert(
            Text("Settle all with \(settling?.name ?? "")?"),
            isPresented: Binding { settling != nil } set: { if !$0 { settling = nil } },
            presenting: settling
        ) { person in
            Button("Cancel", role: .cancel) {}
            Button("Settle All") { store.settleAll(person.id) }
        } message: { person in
            PPSettleMessage(person: person, code: store.code)
        }
        .environment(\.r2Surface, surface)
    }
}

struct VanillaPerson: View {
    private enum Panel: Hashable {
        case open
        case settled
    }

    @Bindable var store: PPStore
    let id: PPPerson.ID
    var surface: R2Surface = .solid

    @State private var panel: Panel?
    @State private var payment: P2Payment?
    @Namespace private var namespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if let person = store.person(id) {
            let panel = panel ?? (person.owes ? .open : .settled)

            ScrollView {
                VStack(spacing: r2TileSpacing) {
                    P2PersonHeader(person: person, code: store.code)
                    P2PersonActions(store: store, person: person, kind: .outline, tint: .primary)
                    if !person.shares.isEmpty {
                        tabs(person, selection: panel)
                        R2Tile(padding: 18) {
                            VStack(alignment: .leading, spacing: 14) {
                                switch panel {
                                case .open:
                                    ForEach(person.openShares) { share in
                                        VStack(alignment: .trailing, spacing: 10) {
                                            PPShareRow(share: share, code: store.code)
                                            HStack(spacing: 8) {
                                                Button("Part…") {
                                                    payment = P2Payment(personID: person.id, shareID: share.id, mode: .part)
                                                }
                                                .buttonStyle(P2ButtonStyle(kind: .outline, tint: .secondary))
                                                Button("Mark Paid", systemImage: "checkmark") {
                                                    payment = P2Payment(personID: person.id, shareID: share.id, mode: .full)
                                                }
                                                .buttonStyle(P2ButtonStyle(kind: .outline, tint: .primary))
                                            }
                                        }
                                        if share.id != person.openShares.last?.id {
                                            Divider()
                                        }
                                    }
                                    if person.openShares.isEmpty {
                                        Text("Nothing open.")
                                            .foregroundStyle(.secondary)
                                    }
                                case .settled:
                                    ForEach(person.settledShares) { share in
                                        PPSettledRow(share: share, code: store.code)
                                    }
                                    if person.settledShares.isEmpty {
                                        Text("Nothing settled yet.")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    P2NoSplitsNote(person: person)
                }
                .padding()
            }
            .background { R2Backdrop() }
            .ppPersonChrome(store: store, person: person)
            .sheet(item: $payment) { P2RepaymentSheet(store: store, payment: $0, kind: .ink) }
            .environment(\.r2Surface, surface)
        }
    }

    /// Two text tabs with an underline that slides between them.
    private func tabs(_ person: PPPerson, selection: Panel) -> some View {
        HStack(spacing: 24) {
            tab(Text("Open · \(person.openShares.count)"), panel: .open, selection: selection)
            tab(Text("Settled · \(person.settledShares.count)"), panel: .settled, selection: selection)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 4)
        .padding(.top, 8)
    }

    private func tab(_ title: Text, panel: Panel, selection: Panel) -> some View {
        let isSelected = panel == selection

        return Button {
            withAnimation(reduceMotion ? nil : .snappy) { self.panel = panel }
        } label: {
            VStack(spacing: 6) {
                title
                    .font(.headline)
                    .foregroundStyle(isSelected ? .primary : .secondary)
                ZStack {
                    Capsule().fill(.clear).frame(height: 3)
                    if isSelected {
                        Capsule()
                            .fill(Color.primary)
                            .frame(height: 3)
                            .matchedGeometryEffect(id: "underline", in: namespace)
                    }
                }
            }
            .fixedSize()
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}

#Preview("Vanilla") {
    PPHost { VanillaPeople(store: $0) } person: { VanillaPerson(store: $0, id: $1) }
}

#Preview("Vanilla · Marta") {
    PPHost(opening: "marta") { VanillaPeople(store: $0) } person: { VanillaPerson(store: $0, id: $1) }
}

#Preview("Vanilla · Glass") {
    PPHost(opening: "luis") {
        VanillaPeople(store: $0, surface: .glass)
    } person: {
        VanillaPerson(store: $0, id: $1, surface: .glass)
    }
}
#endif
