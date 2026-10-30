//
//  10-CloverPeople.swift
//  Finlark
//
//  FIN-9 People, Round 1 "Clover": quick and dense. Three small figures lead (Owed to you, people,
//  oldest debt), and the rows are a native list you can swipe: right to Settle all, left to edit
//  (PPL-002, PPL-004, SPL-008). A person is a compact table with a column for each of PPL-003's figures
//  (share, paid so far, left), stacked at accessibility sizes.
//

#if DEBUG
import SwiftUI

struct CloverPeople: View {
    @Bindable var store: PPStore

    @State private var editing: PPPerson?
    @State private var settling: PPPerson?

    var body: some View {
        List {
            if !store.active.isEmpty {
                Section {
                    figures
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                }
            }

            if !store.owing.isEmpty {
                Section {
                    ForEach(store.owing) { person in
                        row(person)
                    }
                } header: {
                    Text("Owe you")
                } footer: {
                    Text("Swipe right to settle all, left to edit.")
                }
            }

            if !store.settled.isEmpty {
                Section("Settled up") {
                    ForEach(store.settled) { person in
                        row(person)
                    }
                }
            }

            if !store.archived.isEmpty {
                Section {
                    NavigationLink(value: PPRoute.archived) {
                        LabeledContent {
                            Text(store.archived.count, format: .number)
                        } label: {
                            Label("Archived", systemImage: "archivebox")
                        }
                    }
                }
            }
        }
        .overlay {
            if store.people.isEmpty {
                PPEmptyState(store: store)
            }
        }
        .ppListChrome(store: store)
        .sheet(item: $editing) { person in
            PPPersonEditor(store: store, person: person)
        }
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
    }

    private var figures: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: r2TileSpacing) { figureTiles }
            VStack(spacing: r2TileSpacing) { figureTiles }
        }
    }

    @ViewBuilder
    private var figureTiles: some View {
        CloverFigure(title: "Owed to you") {
            Text(store.owedToYou, format: .currency(code: store.code))
        }
        CloverFigure(title: "People") {
            Text(store.owing.count, format: .number)
        }
        CloverFigure(title: "Oldest") {
            if let age = store.owing.compactMap(\.oldestOpen).map(\.age).max() {
                Text("^[\(age) day](inflect: true)")
            } else {
                Text(verbatim: "—")
            }
        }
    }

    private func row(_ person: PPPerson) -> some View {
        NavigationLink(value: PPRoute.person(person.id)) {
            PPPersonRow(person: person, code: store.code, avatarSize: 30)
        }
        .swipeActions(edge: .leading) {
            if person.owes {
                Button("Settle All", systemImage: "checkmark.circle.fill") { settling = person }
                    .tint(.green)
            }
        }
        .swipeActions(edge: .trailing) {
            Button("Edit", systemImage: "pencil") { editing = person }
        }
        .accessibilityActions {
            if person.owes {
                Button("Settle All") { settling = person }
            }
            Button("Edit") { editing = person }
        }
    }
}

private struct CloverFigure<Value: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder let value: Value

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            value
                .font(.headline)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: .rect(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

struct CloverPerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if let person = store.person(id) {
            List {
                Section {
                    if person.owes {
                        LabeledContent {
                            Text(person.owed, format: .currency(code: store.code))
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.primary)
                                .monospacedDigit()
                        } label: {
                            HStack(spacing: 12) {
                                AEAvatar(person: person.avatar, size: 36)
                                Text("Owes you")
                            }
                        }
                    } else {
                        HStack(spacing: 12) {
                            AEAvatar(person: person.avatar, size: 36)
                            PPText.owes(person, code: store.code)
                        }
                    }
                    if person.owes {
                        PPSettleAllButton(store: store, person: person)
                        PPReminderButton(store: store, person: person)
                    }
                }

                if !person.openShares.isEmpty {
                    Section {
                        if dynamicTypeSize.isAccessibilitySize {
                            ForEach(person.openShares) { share in
                                stacked(share)
                            }
                        } else {
                            table(person.openShares)
                        }
                    } header: {
                        Text("Open shares")
                    } footer: {
                        Text("Amounts in \(Locale.current.localizedString(forCurrencyCode: store.code) ?? store.code)")
                    }
                }

                if !person.settledShares.isEmpty {
                    Section("Settled") {
                        ForEach(person.settledShares) { share in
                            PPSettledRow(share: share, code: store.code)
                        }
                    }
                }
            }
            .ppPersonChrome(store: store, person: person)
        }
    }

    private func table(_ shares: [PPShare]) -> some View {
        Grid(alignment: .trailing, horizontalSpacing: 10, verticalSpacing: 10) {
            GridRow {
                Text("Ticket")
                    .gridColumnAlignment(.leading)
                Text("Share")
                Text("Paid")
                Text("Left")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .accessibilityHidden(true)

            ForEach(shares) { share in
                Divider()
                GridRow {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(verbatim: share.ticket)
                            .lineLimit(2)
                        Text(share.date, format: .dateTime.day().month())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    amount(share.share)
                    amount(share.paid)
                        .foregroundStyle(.secondary)
                    amount(share.remaining)
                        .fontWeight(.semibold)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("\(share.ticket), \(PPText.day(share.date))"))
                .accessibilityValue(Text("Share \(share.share, format: .currency(code: store.code)), paid \(share.paid, format: .currency(code: store.code)), \(share.remaining, format: .currency(code: store.code)) left"))
            }
        }
        .font(.subheadline)
        .monospacedDigit()
    }

    private func amount(_ value: Decimal) -> some View {
        Text(value, format: .number.precision(.fractionLength(AEMoney.fractionDigits(for: store.code))))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }

    private func stacked(_ share: PPShare) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(verbatim: share.ticket)
                .font(.headline)
            AEDateText(date: share.date)
                .foregroundStyle(.secondary)
            Text("Share \(share.share, format: .currency(code: store.code))")
            Text("Paid \(share.paid, format: .currency(code: store.code))")
            Text("Left \(share.remaining, format: .currency(code: store.code))")
                .fontWeight(.semibold)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("Clover") {
    PPHost { CloverPeople(store: $0) } person: { CloverPerson(store: $0, id: $1) }
}

#Preview("Clover · Luis") {
    PPHost(opening: "luis") { CloverPeople(store: $0) } person: { CloverPerson(store: $0, id: $1) }
}

#Preview("Clover · Settled up") {
    PPHost(store: .settledUp) { CloverPeople(store: $0) } person: { CloverPerson(store: $0, id: $1) }
}
#endif
