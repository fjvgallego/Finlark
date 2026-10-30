//
//  01-PoppyPeople.swift
//  Finlark
//
//  FIN-9 People, Round 1 "Poppy": the native baseline. A grouped list leads with Owed to you, then the
//  people who owe you, most first, and the people who are settled up (PPL-002). A person is a list too:
//  what they owe with Settle all and Share reminder, their open shares, then their settled history
//  (PPL-003). Nothing custom, so it shows what the system gives for free.
//

#if DEBUG
import SwiftUI

struct PoppyPeople: View {
    @Bindable var store: PPStore

    var body: some View {
        List {
            if !store.active.isEmpty {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
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
                    .padding(.vertical, 4)
                    .accessibilityElement(children: .combine)
                }
            }

            if !store.owing.isEmpty {
                Section("Owe you") {
                    ForEach(store.owing) { person in
                        NavigationLink(value: PPRoute.person(person.id)) {
                            PPPersonRow(person: person, code: store.code)
                        }
                    }
                }
            }

            if !store.settled.isEmpty {
                Section("Settled up") {
                    ForEach(store.settled) { person in
                        NavigationLink(value: PPRoute.person(person.id)) {
                            PPPersonRow(person: person, code: store.code)
                        }
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
    }
}

struct PoppyPerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID

    var body: some View {
        if let person = store.person(id) {
            List {
                Section {
                    VStack(spacing: 10) {
                        AEAvatar(person: person.avatar, size: 64)
                        if person.owes {
                            Text(person.owed, format: .currency(code: store.code))
                                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                                .monospacedDigit()
                        }
                        PPText.owes(person, code: store.code)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .accessibilityElement(children: .combine)
                }
                .listRowBackground(Color.clear)

                if person.owes {
                    Section {
                        PPActions(store: store, person: person)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                if !person.openShares.isEmpty {
                    Section("Open shares") {
                        ForEach(person.openShares) { share in
                            PPShareRow(share: share, code: store.code)
                        }
                    }
                }

                if !person.settledShares.isEmpty {
                    Section("Settled") {
                        ForEach(person.settledShares) { share in
                            PPSettledRow(share: share, code: store.code)
                        }
                    }
                }

                if person.shares.isEmpty {
                    Section {
                        Text("\(person.name) shows up here once you split an expense with them.")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .ppPersonChrome(store: store, person: person)
        }
    }
}

#Preview("Poppy") {
    PPHost { PoppyPeople(store: $0) } person: { PoppyPerson(store: $0, id: $1) }
}

#Preview("Poppy · Marta") {
    PPHost(opening: "marta") { PoppyPeople(store: $0) } person: { PoppyPerson(store: $0, id: $1) }
}

#Preview("Poppy · Settled up") {
    PPHost(store: .settledUp) { PoppyPeople(store: $0) } person: { PoppyPerson(store: $0, id: $1) }
}

#Preview("Poppy · Empty") {
    PPHost(store: .empty) { PoppyPeople(store: $0) } person: { PoppyPerson(store: $0, id: $1) }
}
#endif
