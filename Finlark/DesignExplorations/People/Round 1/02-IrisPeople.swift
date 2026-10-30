//
//  02-IrisPeople.swift
//  Finlark
//
//  FIN-9 People, Round 1 "Iris": Marsh's tiles. A hero tile holds Owed to you with the faces behind it,
//  then a tile of people who owe you and one of people who are settled up (PPL-002). A person opens to
//  the same tiles: what they owe with both actions, open shares with a bar for what's been paid back,
//  and the settled history (PPL-003).
//

#if DEBUG
import SwiftUI

struct IrisPeople: View {
    @Bindable var store: PPStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: r2TileSpacing) {
                if !store.active.isEmpty {
                    hero
                }
                if !store.owing.isEmpty {
                    group("Owe you", symbol: "arrow.down.circle.fill", people: store.owing)
                }
                if !store.settled.isEmpty {
                    group("Settled up", symbol: "checkmark.circle.fill", people: store.settled)
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

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var hero: some View {
        R2Tile(padding: 20) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Owed to you")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(store.owedToYou, format: .currency(code: store.code))
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .monospacedDigit()
                    if store.owedToYou > 0 {
                        PPText.owing(store)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Everyone's settled up.")
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityElement(children: .combine)
                Spacer(minLength: 8)
                if !dynamicTypeSize.isAccessibilitySize {
                    PPAvatarStack(people: store.owing)
                }
            }
        }
    }

    private func group(_ title: LocalizedStringKey, symbol: String, people: [PPPerson]) -> some View {
        R2Tile(padding: 18) {
            VStack(alignment: .leading, spacing: 12) {
                R2TileHeader(title: title, symbol: symbol)
                ForEach(people) { person in
                    NavigationLink(value: PPRoute.person(person.id)) {
                        HStack(spacing: 10) {
                            PPPersonRow(person: person, code: store.code)
                            R2Chevron()
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    if person.id != people.last?.id {
                        Divider()
                    }
                }
            }
        }
    }
}

struct IrisPerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID

    var body: some View {
        if let person = store.person(id) {
            ScrollView {
                VStack(alignment: .leading, spacing: r2TileSpacing) {
                    R2Tile(padding: 20) {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(spacing: 14) {
                                AEAvatar(person: person.avatar, size: 52)
                                VStack(alignment: .leading, spacing: 2) {
                                    if person.owes {
                                        Text("Owes you")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                        Text(person.owed, format: .currency(code: store.code))
                                            .font(.system(.title, design: .rounded, weight: .bold))
                                            .monospacedDigit()
                                    } else {
                                        PPText.owes(person, code: store.code)
                                            .font(.title3.weight(.semibold))
                                    }
                                }
                            }
                            .accessibilityElement(children: .combine)
                            PPActions(store: store, person: person)
                        }
                    }

                    if !person.openShares.isEmpty {
                        R2Tile(padding: 18) {
                            VStack(alignment: .leading, spacing: 14) {
                                R2TileHeader(title: "Open shares", symbol: "clock.fill")
                                ForEach(person.openShares) { share in
                                    PPShareRow(share: share, code: store.code, showsBar: true)
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

                    if person.shares.isEmpty {
                        Text("\(person.name) shows up here once you split an expense with them.")
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)
                    } else if person.owes {
                        Label("Settle all records a repayment for each open share, dated today.", systemImage: "info.circle")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)
                    }
                }
                .padding()
            }
            .background { R2Backdrop() }
            .ppPersonChrome(store: store, person: person)
        }
    }
}

#Preview("Iris") {
    PPHost { IrisPeople(store: $0) } person: { IrisPerson(store: $0, id: $1) }
}

#Preview("Iris · Luis") {
    PPHost(opening: "luis") { IrisPeople(store: $0) } person: { IrisPerson(store: $0, id: $1) }
}

#Preview("Iris · Settled up") {
    PPHost(store: .settledUp) { IrisPeople(store: $0) } person: { IrisPerson(store: $0, id: $1) }
}

#Preview("Iris · Empty") {
    PPHost(store: .empty) { IrisPeople(store: $0) } person: { IrisPerson(store: $0, id: $1) }
}
#endif
