//
//  07-PeonyPeople.swift
//  Finlark
//
//  FIN-9 People, Round 1 "Peony": built for a long list. A native list with search by name and a
//  segmented filter for who owes you, everyone, or the archived people (PPL-002, PPL-004), with Owed to
//  you as the list's header. A person is a list with a segmented switch between their open shares and
//  their settled history (PPL-003).
//

#if DEBUG
import SwiftUI

struct PeonyPeople: View {
    private enum Filter: Hashable {
        case owing
        case everyone
        case archived
    }

    @Bindable var store: PPStore

    @State private var filter: Filter = .owing
    @State private var searchText = ""

    private var people: [PPPerson] {
        let base: [PPPerson] = switch filter {
        case .owing: store.owing
        case .everyone: store.active
        case .archived: store.archived
        }
        guard !searchText.isEmpty else { return base }
        return base.filter { $0.name.localizedStandardContains(searchText) }
    }

    var body: some View {
        List {
            if !store.people.isEmpty {
                Section {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Owed to you")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(store.owedToYou, format: .currency(code: store.code))
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .monospacedDigit()
                    }
                    .accessibilityElement(children: .combine)
                    Picker("Show", selection: $filter) {
                        Text("Owe You").tag(Filter.owing)
                        Text("Everyone").tag(Filter.everyone)
                        if !store.archived.isEmpty {
                            Text("Archived").tag(Filter.archived)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.top, 6)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            Section {
                ForEach(people) { person in
                    NavigationLink(value: PPRoute.person(person.id)) {
                        PPPersonRow(person: person, code: store.code)
                    }
                }
            }
        }
        .overlay {
            if store.people.isEmpty {
                PPEmptyState(store: store)
            } else if people.isEmpty {
                if !searchText.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else if filter == .owing {
                    ContentUnavailableView {
                        Label("Everyone's Settled Up", systemImage: "checkmark.circle")
                    } description: {
                        Text("Nobody owes you anything right now.")
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: Text("Search people"))
        .ppListChrome(store: store)
    }
}

struct PeonyPerson: View {
    private enum Panel: Hashable {
        case open
        case settled
    }

    @Bindable var store: PPStore
    let id: PPPerson.ID

    @State private var panel: Panel?

    var body: some View {
        if let person = store.person(id) {
            let panel = panel ?? (person.owes ? .open : .settled)

            List {
                Section {
                    HStack(spacing: 14) {
                        AEAvatar(person: person.avatar, size: 52)
                        VStack(alignment: .leading, spacing: 2) {
                            PPText.owes(person, code: store.code)
                                .font(.title3.weight(.semibold))
                                .monospacedDigit()
                            if person.totalRepaid > 0 {
                                Text("\(person.totalRepaid, format: .currency(code: store.code)) paid back so far")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                        }
                    }
                    .accessibilityElement(children: .combine)
                    if person.owes {
                        PPReminderButton(store: store, person: person)
                        PPSettleAllButton(store: store, person: person)
                    }
                }

                if !person.shares.isEmpty {
                    Section {
                        switch panel {
                        case .open:
                            ForEach(person.openShares) { share in
                                PPShareRow(share: share, code: store.code)
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
                    } header: {
                        Picker("Show", selection: Binding { panel } set: { self.panel = $0 }) {
                            Text("Open · \(person.openShares.count)").tag(Panel.open)
                            Text("Settled · \(person.settledShares.count)").tag(Panel.settled)
                        }
                        .pickerStyle(.segmented)
                        .textCase(nil)
                        .padding(.bottom, 8)
                    }
                } else {
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

#Preview("Peony") {
    PPHost { PeonyPeople(store: $0) } person: { PeonyPerson(store: $0, id: $1) }
}

#Preview("Peony · Marta") {
    PPHost(opening: "marta") { PeonyPeople(store: $0) } person: { PeonyPerson(store: $0, id: $1) }
}

#Preview("Peony · Settled up") {
    PPHost(store: .settledUp) { PeonyPeople(store: $0) } person: { PeonyPerson(store: $0, id: $1) }
}
#endif
