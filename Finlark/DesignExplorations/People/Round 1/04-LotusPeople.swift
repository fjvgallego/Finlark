//
//  04-LotusPeople.swift
//  Finlark
//
//  FIN-9 People, Round 1 "Lotus": who makes up the total. One bar splits Owed to you by person, each
//  in their color, and the people list below doubles as its legend, with each person's part of the
//  total (PPL-002). A person opens to a ring of how much of their open shares they've paid back, and
//  every share gets a small ring of its own (PPL-003).
//

#if DEBUG
import Charts
import SwiftUI

struct LotusPeople: View {
    @Bindable var store: PPStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: r2TileSpacing) {
                if !store.active.isEmpty {
                    R2Tile(padding: 18) {
                        VStack(alignment: .leading, spacing: 14) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Owed to you")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                Text(store.owedToYou, format: .currency(code: store.code))
                                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                                    .monospacedDigit()
                            }
                            .accessibilityElement(children: .combine)
                            if store.owedToYou > 0 {
                                LotusBar(people: store.owing)
                                VStack(spacing: 0) {
                                    ForEach(store.owing) { person in
                                        link(person) {
                                            legendRow(person)
                                        }
                                        if person.id != store.owing.last?.id {
                                            Divider()
                                        }
                                    }
                                }
                            } else {
                                Text("Everyone's settled up.")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                if !store.settled.isEmpty {
                    R2Tile(padding: 18) {
                        VStack(alignment: .leading, spacing: 12) {
                            R2TileHeader(title: "Settled up", symbol: "checkmark.circle.fill")
                            ForEach(store.settled) { person in
                                link(person) {
                                    PPPersonRow(person: person, code: store.code, avatarSize: 30)
                                }
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

    private func link<Label: View>(_ person: PPPerson, @ViewBuilder label: () -> Label) -> some View {
        NavigationLink(value: PPRoute.person(person.id)) {
            HStack(spacing: 10) {
                label()
                R2Chevron()
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    /// The person's swatch, name and open shares, then what they owe and their part of the total.
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private func legendRow(_ person: PPPerson) -> some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout(spacing: 12))
        return layout {
            if !dynamicTypeSize.isAccessibilitySize {
                RoundedRectangle(cornerRadius: 3)
                    .fill(person.color)
                    .frame(width: 6, height: 32)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: person.name)
                    .font(.headline)
                PPText.summary(person)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if !dynamicTypeSize.isAccessibilitySize {
                Spacer(minLength: 8)
            }
            VStack(alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .trailing, spacing: 2) {
                Text(person.owed, format: .currency(code: store.code))
                    .font(.headline)
                Text(share(of: person), format: .percent.precision(.fractionLength(0)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .monospacedDigit()
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
    }

    /// For display only.
    private func share(of person: PPPerson) -> Double {
        store.owedToYou > 0 ? person.owed.plotValue / store.owedToYou.plotValue : 0
    }
}

/// One bar, split by who owes what. Decorative: the legend rows say it in words.
private struct LotusBar: View {
    let people: [PPPerson]

    @ScaledMetric private var height: CGFloat = 14

    var body: some View {
        Chart(people) { person in
            BarMark(x: .value("Owed", person.owed.plotValue), y: .value("Total", "owed"), height: .fixed(height))
                .foregroundStyle(person.color)
                .cornerRadius(height / 3)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

struct LotusPerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID

    var body: some View {
        if let person = store.person(id) {
            ScrollView {
                VStack(alignment: .leading, spacing: r2TileSpacing) {
                    if person.owes {
                        R2Tile(padding: 20) {
                            VStack(spacing: 16) {
                                LotusRing(progress: progress(person), color: person.color, size: 150) {
                                    VStack(spacing: 2) {
                                        Text(person.owed, format: .currency(code: store.code))
                                            .font(.system(.title2, design: .rounded, weight: .bold))
                                            .monospacedDigit()
                                            .minimumScaleFactor(0.6)
                                            .lineLimit(1)
                                        Text("left")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.horizontal, 16)
                                }
                                Text("\(paid(person), format: .currency(code: store.code)) paid back of \(shares(person), format: .currency(code: store.code))")
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                                    .multilineTextAlignment(.center)
                                PPActions(store: store, person: person)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    } else {
                        R2Tile(padding: 20) {
                            HStack(spacing: 14) {
                                AEAvatar(person: person.avatar, size: 52)
                                PPText.owes(person, code: store.code)
                                    .font(.title3.weight(.semibold))
                            }
                        }
                    }

                    if !person.openShares.isEmpty {
                        R2Tile(padding: 18) {
                            VStack(alignment: .leading, spacing: 14) {
                                R2TileHeader(title: "Open shares", symbol: "clock.fill")
                                ForEach(person.openShares) { share in
                                    HStack(alignment: .top, spacing: 12) {
                                        LotusRing(progress: share.progress, color: person.color, size: 36) {
                                            Image(systemName: share.category.symbol)
                                                .font(.caption)
                                                .foregroundStyle(share.category.color)
                                        }
                                        .accessibilityHidden(true)
                                        shareDetail(share)
                                    }
                                    .accessibilityElement(children: .combine)
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

    private func shareDetail(_ share: PPShare) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(verbatim: share.ticket)
                    .font(.headline)
                Spacer(minLength: 8)
                Text(share.remaining, format: .currency(code: store.code))
                    .font(.headline)
            }
            AEDateText(date: share.date)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            PPStatusLabel(share: share, code: store.code)
                .font(.subheadline)
        }
        .monospacedDigit()
    }

    private func shares(_ person: PPPerson) -> Decimal {
        person.openShares.reduce(0) { $0 + $1.share }
    }

    private func paid(_ person: PPPerson) -> Decimal {
        person.openShares.reduce(0) { $0 + $1.paid }
    }

    /// For drawing only.
    private func progress(_ person: PPPerson) -> Double {
        let total = shares(person)
        return total > 0 ? paid(person).plotValue / total.plotValue : 1
    }
}

/// A ring that fills as money comes back, with something in the middle. Decorative.
private struct LotusRing<Center: View>: View {
    let progress: Double
    let color: Color
    let size: CGFloat
    @ViewBuilder let center: Center

    @ScaledMetric private var scale: CGFloat = 1

    var body: some View {
        let side = size * min(scale, 1.4)
        let line = max(side * 0.09, 4)
        ZStack {
            Circle().stroke(.quaternary, lineWidth: line)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: line, lineCap: .round))
                .rotationEffect(.degrees(-90))
            center
        }
        .frame(width: side, height: side)
    }
}

#Preview("Lotus") {
    PPHost { LotusPeople(store: $0) } person: { LotusPerson(store: $0, id: $1) }
}

#Preview("Lotus · Luis") {
    PPHost(opening: "luis") { LotusPeople(store: $0) } person: { LotusPerson(store: $0, id: $1) }
}

#Preview("Lotus · Settled up") {
    PPHost(store: .settledUp) { LotusPeople(store: $0) } person: { LotusPerson(store: $0, id: $1) }
}
#endif
