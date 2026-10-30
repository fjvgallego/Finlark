//
//  09-OrchidPeople.swift
//  Finlark
//
//  FIN-9 People, Round 1 "Orchid": one person at a time. The people who owe you are cards you swipe
//  through, most owed first, and the card in view shows its open shares and actions under it, so the
//  list and the person share one screen (PPL-002, PPL-003). A person reads as a receipt: one line per
//  open share, a dashed rule and the total, with the actions pinned at the bottom.
//

#if DEBUG
import SwiftUI

struct OrchidPeople: View {
    @Bindable var store: PPStore

    @State private var selectedID: PPPerson.ID?

    private var selected: PPPerson? {
        store.owing.first { $0.id == selectedID } ?? store.owing.first
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: r2TileSpacing) {
                if !store.active.isEmpty {
                    Group {
                        if store.owedToYou > 0 {
                            Text("\(store.owedToYou, format: .currency(code: store.code)) owed to you")
                        } else {
                            Text("Everyone's settled up.")
                        }
                    }
                    .font(.title3.weight(.semibold))
                    .monospacedDigit()
                    .padding(.horizontal, 20)
                }

                if !store.owing.isEmpty {
                    carousel
                }

                if let selected {
                    R2Tile(padding: 18) {
                        VStack(alignment: .leading, spacing: 14) {
                            ForEach(selected.openShares) { share in
                                PPShareRow(share: share, code: store.code)
                                Divider()
                            }
                            PPActions(store: store, person: selected)
                        }
                    }
                    .padding(.horizontal)
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
                    .padding(.horizontal)
                }
                if !store.archived.isEmpty {
                    R2Tile(padding: 16) {
                        PPArchivedLink(store: store)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background { R2Backdrop() }
        .overlay {
            if store.people.isEmpty {
                PPEmptyState(store: store)
            }
        }
        .ppListChrome(store: store)
    }

    private var carousel: some View {
        VStack(spacing: 10) {
            ScrollView(.horizontal) {
                LazyHStack(spacing: r2TileSpacing) {
                    ForEach(store.owing) { person in
                        card(person)
                            .containerRelativeFrame(.horizontal)
                            .id(person.id)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $selectedID)
            .scrollIndicators(.hidden)
            .contentMargins(.horizontal, 16, for: .scrollContent)

            if store.owing.count > 1 {
                HStack(spacing: 6) {
                    ForEach(store.owing) { person in
                        Circle()
                            .fill(person.id == selected?.id ? AnyShapeStyle(.primary) : AnyShapeStyle(.tertiary))
                            .frame(width: 7, height: 7)
                    }
                }
                .frame(maxWidth: .infinity)
                .accessibilityHidden(true)
            }
        }
    }

    private func card(_ person: PPPerson) -> some View {
        R2Tile(padding: 20) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    AEAvatar(person: person.avatar, size: 44)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(verbatim: person.name)
                            .font(.headline)
                        PPText.summary(person)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 8)
                    NavigationLink(value: PPRoute.person(person.id)) {
                        Label("Details", systemImage: "chevron.right")
                            .labelStyle(.iconOnly)
                            .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                    .accessibilityLabel(Text("\(person.name)'s details"))
                }
                Text(person.owed, format: .currency(code: store.code))
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .contain)
    }
}

struct OrchidPerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID

    var body: some View {
        if let person = store.person(id) {
            ScrollView {
                VStack(alignment: .leading, spacing: r2TileSpacing) {
                    if person.owes {
                        receipt(title: Text("\(person.name) owes you"), shares: person.openShares) { share in
                            share.remaining
                        } detail: { share in
                            if share.paid > 0 {
                                Text("\(share.share, format: .currency(code: store.code)) share, \(share.paid, format: .currency(code: store.code)) paid")
                            } else {
                                AEDateText(date: share.date)
                            }
                        } total: {
                            HStack {
                                Text("Total")
                                Spacer(minLength: 8)
                                Text(person.owed, format: .currency(code: store.code))
                            }
                            .font(.title3.weight(.bold))
                            .accessibilityElement(children: .combine)
                        }
                    } else {
                        R2Tile(padding: 18) {
                            HStack(spacing: 14) {
                                AEAvatar(person: person.avatar, size: 48)
                                PPText.owes(person, code: store.code)
                                    .font(.title3.weight(.semibold))
                            }
                        }
                    }

                    if !person.settledShares.isEmpty {
                        receipt(title: Text("Settled"), shares: person.settledShares) { share in
                            share.share
                        } detail: { share in
                            if let date = share.settledOn {
                                Text("Paid back \(PPText.day(date))")
                            }
                        } total: {
                            HStack {
                                Text("Paid back in all")
                                Spacer(minLength: 8)
                                Text(person.totalRepaid, format: .currency(code: store.code))
                            }
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .accessibilityElement(children: .combine)
                        }
                    }
                }
                .padding()
            }
            .background { R2Backdrop() }
            .safeAreaInset(edge: .bottom) {
                PPActions(store: store, person: person)
                    .padding()
            }
            .ppPersonChrome(store: store, person: person)
        }
    }

    private func receipt<Detail: View, Total: View>(
        title: Text,
        shares: [PPShare],
        amount: @escaping (PPShare) -> Decimal,
        @ViewBuilder detail: @escaping (PPShare) -> Detail,
        @ViewBuilder total: () -> Total
    ) -> some View {
        R2Tile(padding: 20) {
            VStack(alignment: .leading, spacing: 14) {
                title
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                ForEach(shares) { share in
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(verbatim: share.ticket)
                            detail(share)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 8)
                        Text(amount(share), format: .currency(code: store.code))
                    }
                    .accessibilityElement(children: .combine)
                }
                Line()
                    .stroke(.secondary, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .frame(height: 1)
                    .accessibilityHidden(true)
                total()
            }
            .fontDesign(.monospaced)
        }
    }

    private struct Line: Shape {
        func path(in rect: CGRect) -> Path {
            Path { path in
                path.move(to: CGPoint(x: rect.minX, y: rect.midY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            }
        }
    }
}

#Preview("Orchid") {
    PPHost { OrchidPeople(store: $0) } person: { OrchidPerson(store: $0, id: $1) }
}

#Preview("Orchid · Luis") {
    PPHost(opening: "luis") { OrchidPeople(store: $0) } person: { OrchidPerson(store: $0, id: $1) }
}

#Preview("Orchid · Settled up") {
    PPHost(store: .settledUp) { OrchidPeople(store: $0) } person: { OrchidPerson(store: $0, id: $1) }
}
#endif
