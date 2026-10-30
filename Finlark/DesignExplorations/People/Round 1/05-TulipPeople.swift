//
//  05-TulipPeople.swift
//  Finlark
//
//  FIN-9 People, Round 1 "Tulip": settle without leaving the list. Each person who owes you opens in
//  place to show their open shares with Remind and Settle all, the way Home's owed bar does (HOM-004),
//  and "All details" pushes the person (PPL-002, PPL-003). On the person, each share opens in place
//  too, to show the repayments that make up "paid so far".
//

#if DEBUG
import SwiftUI

struct TulipPeople: View {
    @Bindable var store: PPStore

    @State private var expanded: Set<PPPerson.ID>
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// `expanded` opens those people from the start.
    init(store: PPStore, expanded: Set<PPPerson.ID> = []) {
        self.store = store
        _expanded = State(initialValue: expanded)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: r2TileSpacing) {
                if !store.active.isEmpty {
                    R2Tile(padding: 18) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("Owed to you")
                                .font(.headline)
                            Spacer(minLength: 8)
                            Text(store.owedToYou, format: .currency(code: store.code))
                                .font(.system(.title2, design: .rounded, weight: .bold))
                                .monospacedDigit()
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                ForEach(store.owing) { person in
                    R2Tile(padding: 16) {
                        row(person)
                    }
                }
                if !store.settled.isEmpty {
                    R2Tile(padding: 18) {
                        VStack(alignment: .leading, spacing: 12) {
                            R2TileHeader(title: "Settled up", symbol: "checkmark.circle.fill")
                            ForEach(store.settled) { person in
                                NavigationLink(value: PPRoute.person(person.id)) {
                                    HStack(spacing: 10) {
                                        PPPersonRow(person: person, code: store.code, avatarSize: 30)
                                        R2Chevron()
                                    }
                                    .contentShape(.rect)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
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

    private func row(_ person: PPPerson) -> some View {
        let isExpanded = expanded.contains(person.id)

        return VStack(alignment: .leading, spacing: 14) {
            Button {
                withAnimation(reduceMotion ? nil : .snappy) {
                    if isExpanded { expanded.remove(person.id) } else { expanded.insert(person.id) }
                }
            } label: {
                HStack(spacing: 10) {
                    PPPersonRow(person: person, code: store.code)
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .accessibilityHidden(true)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityHint(Text("Shows their open shares"))
            .accessibilityAddTraits(isExpanded ? .isSelected : [])

            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(person.openShares) { share in
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(verbatim: share.ticket)
                                PPStatusLabel(share: share, code: store.code)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 8)
                            Text(share.remaining, format: .currency(code: store.code))
                                .fontWeight(.medium)
                        }
                        .font(.subheadline)
                        .monospacedDigit()
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding(14)
                .background(.fill.quaternary, in: .rect(cornerRadius: 16, style: .continuous))
                .transition(.opacity)

                PPActions(store: store, person: person)
                    .transition(.opacity)

                NavigationLink(value: PPRoute.person(person.id)) {
                    Label("All Details", systemImage: "chevron.right")
                        .labelStyle(TulipTrailingIconLabelStyle())
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.tint)
                .transition(.opacity)
            }
        }
    }
}

struct TulipPerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID

    @State private var expanded: Set<PPShare.ID> = []
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if let person = store.person(id) {
            ScrollView {
                VStack(alignment: .leading, spacing: r2TileSpacing) {
                    R2Tile(padding: 20) {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(spacing: 14) {
                                AEAvatar(person: person.avatar, size: 48)
                                PPText.owes(person, code: store.code)
                                    .font(.title3.weight(.semibold))
                                    .monospacedDigit()
                            }
                            .accessibilityElement(children: .combine)
                            PPActions(store: store, person: person)
                        }
                    }

                    if !person.openShares.isEmpty {
                        R2Tile(padding: 18) {
                            VStack(alignment: .leading, spacing: 12) {
                                R2TileHeader(title: "Open shares", symbol: "clock.fill")
                                ForEach(person.openShares) { share in
                                    shareRow(share)
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
                                    shareRow(share)
                                    if share.id != person.settledShares.last?.id {
                                        Divider()
                                    }
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

    /// The share, and when it has repayments, a tap shows them: share, each repayment, and what's left.
    @ViewBuilder
    private func shareRow(_ share: PPShare) -> some View {
        let isExpanded = expanded.contains(share.id)

        if share.repayments.isEmpty {
            PPShareRow(share: share, code: store.code)
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Button {
                    withAnimation(reduceMotion ? nil : .snappy) {
                        if isExpanded { expanded.remove(share.id) } else { expanded.insert(share.id) }
                    }
                } label: {
                    HStack(spacing: 10) {
                        if share.isOpen {
                            PPShareRow(share: share, code: store.code)
                        } else {
                            PPSettledRow(share: share, code: store.code)
                        }
                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                            .accessibilityHidden(true)
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityHint(Text("Shows the repayments"))
                .accessibilityAddTraits(isExpanded ? .isSelected : [])

                if isExpanded {
                    repayments(share)
                        .transition(.opacity)
                }
            }
        }
    }

    private func repayments(_ share: PPShare) -> some View {
        VStack(spacing: 8) {
            line(Text("Share"), share.share)
            ForEach(share.repayments) { repayment in
                line(Text("Paid back \(PPText.day(repayment.date))"), -repayment.amount)
                    .foregroundStyle(.green)
            }
            Divider()
            line(Text("Left"), share.remaining)
                .fontWeight(.semibold)
        }
        .font(.subheadline)
        .monospacedDigit()
        .padding(14)
        .background(.fill.quaternary, in: .rect(cornerRadius: 16, style: .continuous))
    }

    private func line(_ title: Text, _ value: Decimal) -> some View {
        HStack {
            title
            Spacer(minLength: 8)
            Text(value, format: .currency(code: store.code))
        }
        .accessibilityElement(children: .combine)
    }
}

private struct TulipTrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.title
            configuration.icon
                .font(.caption.weight(.bold))
        }
    }
}

#Preview("Tulip") {
    PPHost { TulipPeople(store: $0, expanded: ["marta"]) } person: { TulipPerson(store: $0, id: $1) }
}

#Preview("Tulip · Ana") {
    PPHost(opening: "ana") { TulipPeople(store: $0) } person: { TulipPerson(store: $0, id: $1) }
}

#Preview("Tulip · Settled up") {
    PPHost(store: .settledUp) { TulipPeople(store: $0) } person: { TulipPerson(store: $0, id: $1) }
}
#endif
