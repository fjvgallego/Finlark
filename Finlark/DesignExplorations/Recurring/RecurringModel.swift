//
//  RecurringModel.swift
//  Finlark
//
//  FIN-9 Recurring: the mock store behind every Recurring exploration (REC-001…005). It holds the
//  recurring templates and what happened to each occurrence, and works out the pending items the way
//  the requirements describe them: due today or earlier, not confirmed or skipped, missed ones
//  accumulating, none while paused. Throwaway design code, Debug only.
//

#if DEBUG
import SwiftUI

// MARK: - Template

enum RCFrequency: CaseIterable, Identifiable {
    case weekly
    case monthly
    case yearly

    var id: Self { self }

    var title: LocalizedStringKey {
        switch self {
        case .weekly: "Weekly"
        case .monthly: "Monthly"
        case .yearly: "Yearly"
        }
    }

    var component: Calendar.Component {
        switch self {
        case .weekly: .weekOfYear
        case .monthly: .month
        case .yearly: .year
        }
    }

    /// How many times a year, for the monthly estimate.
    var perYear: Decimal {
        switch self {
        case .weekly: 52
        case .monthly: 12
        case .yearly: 1
        }
    }
}

/// A recurring template (REC-001): what repeats, how often, from when and until when.
struct RCTemplate: Identifiable {
    let id: UUID
    var type: ExplorationTransactionType
    var amount: Decimal
    var category: ExplorationCategory
    var note: String
    var frequency: RCFrequency
    var startDate: Date
    var endDate: Date?
    var isPaused = false
    /// Paused templates generate nothing until resumed (REC-005), so occurrences before this don't count.
    var resumedOn: Date?

    init(
        id: UUID = UUID(),
        type: ExplorationTransactionType = .expense,
        amount: Decimal,
        category: ExplorationCategory,
        note: String,
        frequency: RCFrequency = .monthly,
        startDate: Date,
        endDate: Date? = nil,
        isPaused: Bool = false
    ) {
        self.id = id
        self.type = type
        self.amount = amount
        self.category = category
        self.note = note
        self.frequency = frequency
        self.startDate = startDate
        self.endDate = endDate
        self.isPaused = isPaused
    }

    var title: String { note.isEmpty ? String(localized: category.name) : note }
    var signedAmount: Decimal { type == .expense ? -amount : amount }

    /// What it comes to in an average month.
    var monthlyAmount: Decimal {
        AEMoney.rounded(amount * frequency.perYear / 12, fractionDigits: 2, mode: .plain)
    }

    /// The nth occurrence, counted from the start date so months don't drift. A monthly template on the
    /// 29th–31st falls on the last day of shorter months (REC-001), as `Calendar` clamps it.
    private func occurrence(_ index: Int) -> Date? {
        guard let date = Calendar.current.date(byAdding: frequency.component, value: index, to: startDate) else {
            return nil
        }
        if let endDate, date > endDate { return nil }
        return date
    }

    /// Occurrences from `start` through `end`, oldest first.
    func occurrences(from start: Date, through end: Date) -> [Date] {
        var dates: [Date] = []
        var index = 0
        while index < 2_000, let date = occurrence(index), date <= end {
            if date >= start { dates.append(date) }
            index += 1
        }
        return dates
    }

    /// The next `count` occurrences after `day`.
    func upcoming(after day: Date, count: Int) -> [Date] {
        var dates: [Date] = []
        var index = 0
        while dates.count < count, index < 2_000, let date = occurrence(index) {
            if date > day { dates.append(date) }
            index += 1
        }
        return dates
    }

    var hasEnded: Bool {
        endDate.map { $0 < RCStore.today } ?? false
    }
}

// MARK: - Occurrences

/// An occurrence that's due and waiting to be confirmed or skipped (REC-002).
struct RCPending: Identifiable, Hashable {
    let templateID: RCTemplate.ID
    let date: Date

    var id: String { "\(templateID.uuidString)|\(date.timeIntervalSinceReferenceDate)" }
    var isDueToday: Bool { date == RCStore.today }
}

/// What happened to an occurrence: confirmed into a transaction (REC-003) or skipped (REC-004).
struct RCOutcome: Identifiable {
    enum Kind {
        /// The transaction it created, as confirmed, maybe edited first.
        case confirmed(amount: Decimal, date: Date)
        case skipped
    }

    let id = UUID()
    let templateID: RCTemplate.ID
    let occurrence: Date
    let kind: Kind

    var isSkipped: Bool {
        if case .skipped = kind { return true }
        return false
    }
}

struct RCUndo: Equatable {
    let id = UUID()
    let message: String
    let outcomeIDs: [RCOutcome.ID]
}

// MARK: - Store

@Observable
final class RCStore {
    let code = "EUR"
    private(set) var templates: [RCTemplate]
    private(set) var outcomes: [RCOutcome]
    /// The mock starts here: older occurrences never become pending.
    private let trackingStart: Date

    init(templates: [RCTemplate], outcomes: [RCOutcome], trackingStart: Date) {
        self.templates = templates
        self.outcomes = outcomes
        self.trackingStart = trackingStart
    }

    static var today: Date { Calendar.current.startOfDay(for: .now) }

    func template(_ id: RCTemplate.ID) -> RCTemplate? {
        templates.first { $0.id == id }
    }

    // MARK: Lists

    /// Every pending item, oldest first. Paused templates have none (REC-005).
    var pending: [RCPending] {
        templates.flatMap(pending(for:)).sorted { $0.date < $1.date }
    }

    func pending(for template: RCTemplate) -> [RCPending] {
        guard !template.isPaused else { return [] }
        let start = max(trackingStart, template.resumedOn ?? .distantPast)
        return template.occurrences(from: start, through: Self.today)
            .filter { date in !outcomes.contains { $0.templateID == template.id && $0.occurrence == date } }
            .map { RCPending(templateID: template.id, date: $0) }
    }

    var pendingTotal: Decimal {
        pending.reduce(0) { total, item in total + (template(item.templateID)?.signedAmount ?? 0) }
    }

    /// Templates that aren't paused or over, soonest first.
    var active: [RCTemplate] {
        templates.filter { !$0.isPaused && !$0.hasEnded }
            .sorted { (nextDate(for: $0) ?? .distantFuture) < (nextDate(for: $1) ?? .distantFuture) }
    }

    var paused: [RCTemplate] {
        templates.filter(\.isPaused).sorted { $0.title < $1.title }
    }

    func nextDate(for template: RCTemplate) -> Date? {
        template.isPaused ? nil : template.upcoming(after: Self.today, count: 1).first
    }

    /// What each occurrence came to, newest first.
    func history(for template: RCTemplate) -> [RCOutcome] {
        outcomes.filter { $0.templateID == template.id }.sorted { $0.occurrence > $1.occurrence }
    }

    /// Active templates of a type, per average month.
    func monthlyTotal(_ type: ExplorationTransactionType) -> Decimal {
        active.filter { $0.type == type }.reduce(0) { $0 + $1.monthlyAmount }
    }

    /// Occurrences of active templates in the next `days` days, soonest first.
    func upcoming(days: Int) -> [RCPending] {
        let end = Calendar.current.date(byAdding: .day, value: days, to: Self.today) ?? Self.today
        return active.flatMap { template in
            template.upcoming(after: Self.today, count: 60)
                .filter { $0 <= end }
                .map { RCPending(templateID: template.id, date: $0) }
        }
        .sorted { $0.date < $1.date }
    }

    // MARK: Pending items (REC-003, REC-004)

    /// Creates the transaction, as is or edited first.
    @discardableResult
    func confirm(_ item: RCPending, amount: Decimal? = nil, date: Date? = nil) -> RCUndo? {
        guard let template = template(item.templateID) else { return nil }
        let outcome = RCOutcome(
            templateID: item.templateID,
            occurrence: item.date,
            kind: .confirmed(amount: amount ?? template.amount, date: date ?? item.date)
        )
        outcomes.append(outcome)
        let value = (amount ?? template.amount).formatted(.currency(code: code))
        return RCUndo(message: String(localized: "\(template.title) confirmed, \(value)"), outcomeIDs: [outcome.id])
    }

    @discardableResult
    func skip(_ item: RCPending) -> RCUndo? {
        guard let template = template(item.templateID) else { return nil }
        let outcome = RCOutcome(templateID: item.templateID, occurrence: item.date, kind: .skipped)
        outcomes.append(outcome)
        let day = item.date.formatted(.dateTime.day().month())
        return RCUndo(message: String(localized: "\(template.title) on \(day) skipped"), outcomeIDs: [outcome.id])
    }

    /// Confirms every pending item as it is. Not in the requirements: a variant proposes it.
    func confirmAll() -> RCUndo? {
        let items = pending
        guard !items.isEmpty else { return nil }
        let ids = items.compactMap { confirm($0)?.outcomeIDs.first }
        return RCUndo(message: String(localized: "^[\(items.count) item](inflect: true) confirmed"), outcomeIDs: ids)
    }

    func undo(_ undo: RCUndo) {
        outcomes.removeAll { undo.outcomeIDs.contains($0.id) }
    }

    // MARK: Templates (REC-001, REC-005)

    /// Adds a new template or saves changes to one. Changes apply to future occurrences; transactions
    /// already created keep what they were.
    func save(_ template: RCTemplate) {
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index] = template
        } else {
            templates.append(template)
        }
    }

    /// Resuming starts from today, so the time it was paused leaves no pending items behind.
    func setPaused(_ isPaused: Bool, for id: RCTemplate.ID) {
        guard let index = templates.firstIndex(where: { $0.id == id }) else { return }
        templates[index].isPaused = isPaused
        if !isPaused { templates[index].resumedOn = Self.today }
    }

    /// The transactions it created stay in History.
    func delete(_ id: RCTemplate.ID) {
        templates.removeAll { $0.id == id }
    }
}

// MARK: - Samples

extension RCStore {
    /// Ten templates, one paused and one with an end date. Four items are pending: the rent from two
    /// days ago, Netflix (due today, unless the month's length moves it a day or so earlier), and two gym
    /// fees, one of them missed last month (REC-002).
    static var sample: RCStore { make(leavingPending: true) }

    /// The same templates with nothing left to confirm.
    static var caughtUp: RCStore { make(leavingPending: false) }

    /// No templates yet.
    static var empty: RCStore { RCStore(templates: [], outcomes: [], trackingStart: today) }

    private static func make(leavingPending: Bool) -> RCStore {
        let rent = RCTemplate(amount: amount("750"), category: .housing, note: "Rent", startDate: date(months: -14, days: -2))
        let salary = RCTemplate(
            type: .income, amount: amount("2150"), category: .salary, note: "Salary", startDate: date(months: -24, days: -6)
        )
        let gym = RCTemplate(amount: amount("39.90"), category: .health, note: "Gym", startDate: date(months: -8, days: -5))
        let netflix = RCTemplate(
            amount: amount("12.99"), category: .subscriptions, note: "Netflix", startDate: date(months: -20)
        )
        let electricity = RCTemplate(
            amount: amount("45"), category: .bills, note: "Electricity", startDate: date(months: -12, days: 9)
        )
        let spotify = RCTemplate(
            amount: amount("10.99"), category: .subscriptions, note: "Spotify", startDate: date(months: -30, days: 12)
        )
        let veggieBox = RCTemplate(
            amount: amount("25"), category: .groceries, note: "Veggie box", frequency: .weekly, startDate: date(days: -53)
        )
        let insurance = RCTemplate(
            amount: amount("420"), category: .transport, note: "Car insurance", frequency: .yearly,
            startDate: date(months: -20)
        )
        let phone = RCTemplate(
            amount: amount("20"), category: .bills, note: "Phone plan", startDate: date(months: -19, days: 15),
            endDate: date(months: 5, days: 15)
        )
        let metro = RCTemplate(
            amount: amount("38"), category: .transport, note: "Metro pass", startDate: date(months: -10, days: 4),
            isPaused: true
        )
        let templates = [rent, salary, gym, netflix, electricity, spotify, veggieBox, insurance, phone, metro]

        let start = date(months: -4)
        // Electricity varies, so its confirmed amounts were edited.
        let electricityBills = [amount("52.30"), amount("41.80"), amount("47.15"), amount("44.60")]
        var outcomes: [RCOutcome] = []
        for template in templates {
            let dates = template.occurrences(from: start, through: today)
            var waiting = 0
            if leavingPending {
                waiting = switch template.id {
                case rent.id, netflix.id: 1
                case gym.id: 2
                default: 0
                }
            }
            for (index, day) in dates.dropLast(waiting).enumerated() {
                if template.id == gym.id, index == 0 {
                    outcomes.append(RCOutcome(templateID: template.id, occurrence: day, kind: .skipped))
                } else {
                    let value = template.id == electricity.id
                        ? electricityBills[index % electricityBills.count]
                        : template.amount
                    outcomes.append(RCOutcome(templateID: template.id, occurrence: day, kind: .confirmed(amount: value, date: day)))
                }
            }
        }
        return RCStore(templates: templates, outcomes: outcomes, trackingStart: start)
    }

    /// Today moved by some days, then by some months, at the start of the day.
    private static func date(months: Int = 0, days: Int = 0) -> Date {
        let calendar = Calendar.current
        let shifted = calendar.date(byAdding: .day, value: days, to: today) ?? today
        return calendar.startOfDay(for: calendar.date(byAdding: .month, value: months, to: shifted) ?? shifted)
    }

    /// Parses from a string so mock amounts never pass through floating point (NFR-005).
    private static func amount(_ value: String) -> Decimal {
        Decimal(string: value, locale: Locale(identifier: "en_US_POSIX")) ?? 0
    }
}
#endif
