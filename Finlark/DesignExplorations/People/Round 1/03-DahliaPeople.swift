//
//  03-DahliaPeople.swift
//  Finlark
//
//  FIN-9 People, Round 1 "Dahlia": faces first. People who owe you are cards in a grid, big avatar
//  and amount, and people who are settled up are a small row of faces under them (PPL-002). A person
//  opens like a contact card: the avatar centered, what they owe, and two square action buttons under
//  it, as Contacts puts Message and Call (PPL-003).
//

#if DEBUG
import SwiftUI

struct DahliaPeople: View {
    @Bindable var store: PPStore

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var columns: [GridItem] {
        let count = dynamicTypeSize.isAccessibilitySize ? 1 : 2
        return Array(repeating: GridItem(.flexible(), spacing: r2TileSpacing), count: count)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: r2TileSpacing) {
                if !store.active.isEmpty {
                    summary
                        .padding(.horizontal, 4)
                }
                if !store.owing.isEmpty {
                    LazyVGrid(columns: columns, spacing: r2TileSpacing) {
                        ForEach(store.owing) { person in
                            card(person)
                        }
                    }
                }
                if !store.settled.isEmpty {
                    settledTile
                }
                if !store.archived.isEmpty {
                    R2Tile(padding: 16) {
                        PPArchivedLink(store: store)
                    }
                }
            }
            .padding()
        }
        .background { R2Backdrop() }
        .overlay {
            if store.people.isEmpty {
                PPEmptyState(store: store)
            }
        }
        .ppListChrome(store: store)
    }

    @ViewBuilder
    private var summary: some View {
        if store.owedToYou > 0 {
            Text("^[\(store.owing.count) person](inflect: true) owe you \(store.owedToYou, format: .currency(code: store.code))")
                .font(.title3.weight(.semibold))
                .monospacedDigit()
        } else {
            Text("Everyone's settled up.")
                .font(.title3.weight(.semibold))
        }
    }

    private func card(_ person: PPPerson) -> some View {
        NavigationLink(value: PPRoute.person(person.id)) {
            R2Tile(padding: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    AEAvatar(person: person.avatar, size: 48)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(verbatim: person.name)
                            .font(.headline)
                        PPText.summary(person)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Text(person.owed, format: .currency(code: store.code))
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }

    private var settledTile: some View {
        R2Tile(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                R2TileHeader(title: "Settled up", symbol: "checkmark.circle.fill")
                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: 16) {
                        ForEach(store.settled) { person in
                            NavigationLink(value: PPRoute.person(person.id)) {
                                VStack(spacing: 6) {
                                    AEAvatar(person: person.avatar, size: 44)
                                    Text(verbatim: person.name)
                                        .font(.caption.weight(.medium))
                                        .lineLimit(1)
                                }
                                .frame(minWidth: 56)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(Text("\(person.name), \(PPText.summary(person))"))
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
    }
}

struct DahliaPerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID

    var body: some View {
        if let person = store.person(id) {
            ScrollView {
                VStack(spacing: r2TileSpacing) {
                    VStack(spacing: 8) {
                        AEAvatar(person: person.avatar, size: 88)
                        Text(verbatim: person.name)
                            .font(.title.weight(.bold))
                        PPText.owes(person, code: store.code)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .accessibilityElement(children: .combine)

                    if person.owes {
                        HStack(spacing: r2TileSpacing) {
                            PPReminderButton(store: store, person: person) {
                                DahliaActionLabel(title: "Remind", symbol: "bubble.left.and.text.bubble.right.fill")
                            }
                            PPSettleAllButton(store: store, person: person) {
                                DahliaActionLabel(title: "Settle All", symbol: "checkmark.circle.fill")
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    if !person.openShares.isEmpty {
                        R2Tile(padding: 18) {
                            VStack(alignment: .leading, spacing: 14) {
                                R2TileHeader(title: "Open shares", symbol: "clock.fill")
                                ForEach(person.openShares) { share in
                                    PPShareRow(share: share, code: store.code)
                                    if share.id != person.openShares.last?.id {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }

                    if !person.settledShares.isEmpty {
                        R2Tile(padding: 18) {
                            VStack(alignment: .leading, spacing: 12) {
                                R2TileHeader(title: "Settled", symbol: "checkmark.circle.fill")
                                ForEach(person.settledShares) { share in
                                    PPSettledRow(share: share, code: store.code)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .background { R2Backdrop() }
            .ppPersonChrome(store: store, person: person)
        }
    }
}

/// A square glass button with the icon over the title, like Contacts' Message and Call.
private struct DahliaActionLabel: View {
    let title: LocalizedStringKey
    let symbol: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(.tint)
            Text(title)
                .font(.subheadline.weight(.semibold))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20, style: .continuous))
    }
}

#Preview("Dahlia") {
    PPHost { DahliaPeople(store: $0) } person: { DahliaPerson(store: $0, id: $1) }
}

#Preview("Dahlia · Marta") {
    PPHost(opening: "marta") { DahliaPeople(store: $0) } person: { DahliaPerson(store: $0, id: $1) }
}

#Preview("Dahlia · Settled up") {
    PPHost(store: .settledUp) { DahliaPeople(store: $0) } person: { DahliaPerson(store: $0, id: $1) }
}
#endif
