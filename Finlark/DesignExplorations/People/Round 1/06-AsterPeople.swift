//
//  06-AsterPeople.swift
//  Finlark
//
//  FIN-9 People, Round 1 "Aster": how long it's been. People who owe you still come first (PPL-002),
//  but among them the longest-waiting debt leads, and every row says how many days it's been open, so
//  the awkward reminders don't get forgotten. A person reads as a timeline: each split and each
//  repayment in the order they happened, newest first (PPL-003).
//

#if DEBUG
import SwiftUI

struct AsterPeople: View {
    @Bindable var store: PPStore

    /// Open debts first, the oldest open share leading.
    private var owing: [PPPerson] {
        store.owing.sorted { ($0.oldestOpen?.date ?? .now) < ($1.oldestOpen?.date ?? .now) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: r2TileSpacing) {
                if !store.active.isEmpty {
                    R2Tile(padding: 18) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Owed to you")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text(store.owedToYou, format: .currency(code: store.code))
                                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                                .monospacedDigit()
                            if let oldest = owing.first, let share = oldest.oldestOpen {
                                Text("Oldest: \(oldest.name), \(share.ticket), ^[\(share.age) day](inflect: true) ago")
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Everyone's settled up.")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                if !owing.isEmpty {
                    R2Tile(padding: 18) {
                        VStack(alignment: .leading, spacing: 12) {
                            R2TileHeader(title: "Waiting longest", symbol: "hourglass")
                            ForEach(owing) { person in
                                link(person) { row(person) }
                                if person.id != owing.last?.id {
                                    Divider()
                                }
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

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private func row(_ person: PPPerson) -> some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 6))
            : AnyLayout(HStackLayout(spacing: 12))
        return layout {
            if !dynamicTypeSize.isAccessibilitySize {
                AEAvatar(person: person.avatar, size: 36)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: person.name)
                    .font(.headline)
                if let oldest = person.oldestOpen {
                    AsterAgeBadge(share: oldest)
                }
            }
            if !dynamicTypeSize.isAccessibilitySize {
                Spacer(minLength: 8)
            }
            Text(person.owed, format: .currency(code: store.code))
                .font(.headline)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }
}

/// "12 days", warmer the longer it waits. The words carry it; the color only adds to them.
private struct AsterAgeBadge: View {
    let share: PPShare

    private var tint: Color {
        switch share.age {
        case ..<7: .secondary
        case ..<30: .orange
        default: .red
        }
    }

    var body: some View {
        Label {
            PPText.age(share)
        } icon: {
            Image(systemName: "clock")
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(tint.opacity(0.12), in: .capsule)
    }
}

struct AsterPerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID

    @ScaledMetric private var dotSize: CGFloat = 36
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// A title and an amount on one line, or stacked at accessibility sizes.
    private var lineLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline))
    }

    /// A split or a repayment, on one timeline.
    private struct Event: Identifiable {
        enum Kind {
            case split(PPShare)
            case repayment(PPRepayment, PPShare)
        }

        let id: UUID
        let date: Date
        let kind: Kind
    }

    private func events(_ person: PPPerson) -> [Event] {
        person.shares.flatMap { share in
            [Event(id: share.id, date: share.date, kind: .split(share))]
                + share.repayments.map { Event(id: $0.id, date: $0.date, kind: .repayment($0, share)) }
        }
        .sorted { $0.date > $1.date }
    }

    var body: some View {
        if let person = store.person(id) {
            ScrollView {
                VStack(alignment: .leading, spacing: r2TileSpacing) {
                    R2Tile(padding: 20) {
                        VStack(alignment: .leading, spacing: 14) {
                            VStack(alignment: .leading, spacing: 4) {
                                PPText.owes(person, code: store.code)
                                    .font(.title2.weight(.bold))
                                    .monospacedDigit()
                                if let oldest = person.oldestOpen {
                                    Text("Open since \(oldest.date, format: .dateTime.day().month())")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .accessibilityElement(children: .combine)
                            PPActions(store: store, person: person)
                        }
                    }

                    let events = events(person)
                    if !events.isEmpty {
                        R2Tile(padding: 18) {
                            VStack(alignment: .leading, spacing: 0) {
                                R2TileHeader(title: "Timeline", symbol: "list.bullet")
                                    .padding(.bottom, 14)
                                ForEach(events) { event in
                                    timelineRow(event, isLast: event.id == events.last?.id)
                                }
                            }
                        }
                    } else {
                        Text("\(person.name) shows up here once you split an expense with them.")
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

    private func timelineRow(_ event: Event, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                dot(event)
                if !isLast {
                    Rectangle()
                        .fill(.quaternary)
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                switch event.kind {
                case .split(let share):
                    lineLayout {
                        Text(verbatim: share.ticket)
                            .font(.headline)
                        if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: 8) }
                        Text(share.share, format: .currency(code: store.code))
                            .font(.headline)
                    }
                    Text("Split \(PPText.day(share.date)) · total \(share.total, format: .currency(code: store.code))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    PPStatusLabel(share: share, code: store.code)
                        .font(.subheadline)
                case .repayment(let repayment, let share):
                    lineLayout {
                        Text("Paid back")
                            .font(.headline)
                        if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: 8) }
                        Text(repayment.amount, format: .currency(code: store.code))
                            .font(.headline)
                            .foregroundStyle(.green)
                    }
                    Text("\(share.ticket) · \(PPText.day(repayment.date))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .monospacedDigit()
            .padding(.bottom, isLast ? 0 : 18)
            .accessibilityElement(children: .combine)
        }
    }

    @ViewBuilder
    private func dot(_ event: Event) -> some View {
        switch event.kind {
        case .split(let share):
            ExplorationCategoryIcon(category: share.category)
        case .repayment:
            Image(systemName: "arrow.uturn.backward")
                .font(.footnote.weight(.bold))
                .foregroundStyle(.green)
                .frame(width: dotSize, height: dotSize)
                .background(Color.green.opacity(0.15), in: .circle)
        }
    }
}

#Preview("Aster") {
    PPHost { AsterPeople(store: $0) } person: { AsterPerson(store: $0, id: $1) }
}

#Preview("Aster · Marta") {
    PPHost(opening: "marta") { AsterPeople(store: $0) } person: { AsterPerson(store: $0, id: $1) }
}

#Preview("Aster · Settled up") {
    PPHost(store: .settledUp) { AsterPeople(store: $0) } person: { AsterPerson(store: $0, id: $1) }
}
#endif
