//
//  05-RefrainRecurring.swift
//  Finlark
//
//  FIN-9 Recurring, Round 1 "Refrain": this month as a calendar. Each day with something due carries a
//  small symbol: pending, coming up, confirmed or skipped, by shape as well as color. Tapping a day lists
//  what falls on it, with Skip and Confirm for what's pending. Every pending item, whatever its month,
//  follows, then the templates. At accessibility sizes the calendar gives way to the lists.
//

#if DEBUG
import SwiftUI

/// What became of an occurrence, for the calendar.
private enum RefrainStatus: Int, Comparable {
    case pending
    case upcoming
    case confirmed
    case skipped

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }

    var symbol: String {
        switch self {
        case .pending: "exclamationmark.circle.fill"
        case .upcoming: "circle"
        case .confirmed: "checkmark.circle.fill"
        case .skipped: "forward.end.circle"
        }
    }

    var tint: Color {
        switch self {
        case .pending: .orange
        case .upcoming: .secondary
        case .confirmed: .green
        case .skipped: .secondary
        }
    }

    var title: LocalizedStringKey {
        switch self {
        case .pending: "Pending"
        case .upcoming: "Coming up"
        case .confirmed: "Confirmed"
        case .skipped: "Skipped"
        }
    }
}

private struct RefrainOccurrence: Identifiable {
    let template: RCTemplate
    let date: Date
    let status: RefrainStatus

    var id: String { "\(template.id)|\(date.timeIntervalSinceReferenceDate)" }
    var pending: RCPending { RCPending(templateID: template.id, date: date) }
}

private extension RCStore {
    /// Everything that falls in this month, and what became of it.
    var refrainMonth: [RefrainOccurrence] {
        let calendar = Calendar.current
        guard let month = calendar.dateInterval(of: .month, for: Self.today) else { return [] }
        let last = month.end.addingTimeInterval(-1)
        let waiting = Set(pending)
        return templates.flatMap { template in
            template.occurrences(from: month.start, through: last).compactMap { date -> RefrainOccurrence? in
                let item = RCPending(templateID: template.id, date: date)
                if let outcome = outcomes.first(where: { $0.templateID == template.id && $0.occurrence == date }) {
                    return RefrainOccurrence(template: template, date: date, status: outcome.isSkipped ? .skipped : .confirmed)
                }
                if waiting.contains(item) {
                    return RefrainOccurrence(template: template, date: date, status: .pending)
                }
                guard !template.isPaused, date > Self.today else { return nil }
                return RefrainOccurrence(template: template, date: date, status: .upcoming)
            }
        }
        .sorted { $0.date < $1.date }
    }
}

struct RefrainRecurring: View {
    @Bindable var store: RCStore

    @State private var selectedDay = RCStore.today
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        RCScreen(store: store) { actions in
            let month = store.refrainMonth
            if !dynamicTypeSize.isAccessibilitySize {
                RefrainCalendar(occurrences: month, selection: $selectedDay)
                RefrainDay(store: store, day: selectedDay, occurrences: month.filter { $0.date == selectedDay }, actions: actions)
            }
            let pending = store.pending
            if pending.isEmpty {
                RCCaughtUp(store: store)
            } else {
                R2Tile(padding: 18) {
                    VStack(alignment: .leading, spacing: 14) {
                        R2TileHeader(title: "All pending", symbol: "clock.badge.exclamationmark.fill")
                        ForEach(pending) { item in
                            P5Row {
                                Button { actions.review(item) } label: {
                                    RCPendingInfo(store: store, item: item)
                                }
                                .buttonStyle(.plain)
                            } controls: {
                                RCQuickControls(store: store, item: item, actions: actions)
                            }
                            if item.id != pending.last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }
            RCTemplateList(store: store, title: "All recurring", templates: store.active)
            RCTemplateList(store: store, title: "Paused", symbol: "pause.fill", templates: store.paused)
        }
    }
}

/// The month grid, starting on the locale's first weekday.
private struct RefrainCalendar: View {
    let occurrences: [RefrainOccurrence]
    @Binding var selection: Date

    private let calendar = Calendar.current

    var body: some View {
        let month = calendar.dateInterval(of: .month, for: RCStore.today)
        let start = month?.start ?? RCStore.today
        let dayCount = calendar.range(of: .day, in: .month, for: start)?.count ?? 30
        let offset = (calendar.component(.weekday, from: start) - calendar.firstWeekday + 7) % 7
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let weekdays = Array(symbols[(calendar.firstWeekday - 1)...] + symbols[..<(calendar.firstWeekday - 1)])

        R2Tile(padding: 14) {
            VStack(spacing: 10) {
                Text(start, format: .dateTime.month(.wide).year())
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
                    .accessibilityAddTraits(.isHeader)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 6) {
                    ForEach(weekdays.indices, id: \.self) { index in
                        Text(weekdays[index])
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                    }
                    ForEach(0..<offset, id: \.self) { _ in
                        Color.clear.frame(height: 1)
                    }
                    ForEach(1...dayCount, id: \.self) { number in
                        let day = calendar.date(byAdding: .day, value: number - 1, to: start) ?? start
                        dayCell(day, number: number)
                    }
                }
            }
        }
    }

    private func dayCell(_ day: Date, number: Int) -> some View {
        let items = occurrences.filter { $0.date == day }
        let status = items.map(\.status).min()
        let isSelected = day == selection
        let isToday = day == RCStore.today

        return Button { selection = day } label: {
            VStack(spacing: 3) {
                Text(number, format: .number)
                    .font(.subheadline.weight(isToday ? .bold : .regular).monospacedDigit())
                    .foregroundStyle(isSelected ? Color.white : isToday ? Color.accentColor : Color.primary)
                    .frame(width: 32, height: 32)
                    .background {
                        if isSelected {
                            Circle().fill(Color.accentColor)
                        }
                    }
                Image(systemName: status?.symbol ?? "circle")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(status?.tint ?? .clear)
            }
            .frame(maxWidth: .infinity)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(day, format: .dateTime.day().month(.wide)))
        .accessibilityValue(items.isEmpty ? Text("Nothing due") : Text("^[\(items.count) item](inflect: true)"))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// What falls on the chosen day.
private struct RefrainDay: View {
    let store: RCStore
    let day: Date
    let occurrences: [RefrainOccurrence]
    let actions: RCActions

    var body: some View {
        R2Tile(padding: 18) {
            VStack(alignment: .leading, spacing: 12) {
                Text(day, format: .dateTime.weekday(.wide).day().month(.wide))
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                if occurrences.isEmpty {
                    Text("Nothing is due on this day.")
                        .foregroundStyle(.secondary)
                }
                ForEach(occurrences) { occurrence in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 12) {
                            P8CategoryIcon(category: occurrence.template.category)
                            P8InfoAndAmount {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(verbatim: occurrence.template.title)
                                        .font(.body.weight(.semibold))
                                    Label {
                                        Text(occurrence.status.title)
                                    } icon: {
                                        Image(systemName: occurrence.status.symbol)
                                            .foregroundStyle(occurrence.status.tint)
                                    }
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                }
                            } amount: {
                                RCFormat.amount(occurrence.template, code: store.code)
                                    .monospacedDigit()
                            }
                        }
                        .accessibilityElement(children: .combine)
                        if occurrence.status == .pending {
                            RCPendingButtons(store: store, item: occurrence.pending, actions: actions)
                        }
                    }
                }
            }
        }
    }
}

#Preview("Refrain") {
    RCHost { RefrainRecurring(store: $0) }
}

#Preview("Refrain · Caught up") {
    RCHost(store: .caughtUp) { RefrainRecurring(store: $0) }
}

#Preview("Refrain · Dark") {
    RCHost { RefrainRecurring(store: $0) }
        .preferredColorScheme(.dark)
}
#endif
