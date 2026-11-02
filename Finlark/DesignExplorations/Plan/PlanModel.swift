//
//  PlanModel.swift
//  Finlark
//
//  FIN-9 Plan: the mock store behind every Plan exploration (PLN-001…003). It holds the planned amounts,
//  this month's spending per category and a few past months, and works out projections and statuses
//  the way the requirements describe them. Throwaway design code, Debug only.
//

#if DEBUG
import SwiftUI

/// A category's or the whole plan's status (PLN-002). A finished month has no projection, so it only
/// says whether spending stayed within the plan. Always shown with its symbol and title (NFR-003).
enum PLStatus {
    case onTrack
    case atRisk
    case over
    case withinPlan

    init(planned: Decimal, spent: Decimal, projected: Decimal?) {
        if spent > planned {
            self = .over
        } else if let projected {
            self = projected > planned ? .atRisk : .onTrack
        } else {
            self = .withinPlan
        }
    }

    var title: LocalizedStringResource {
        switch self {
        case .onTrack: "On track"
        case .atRisk: "At risk"
        case .over: "Over"
        case .withinPlan: "Within plan"
        }
    }

    var symbol: String {
        switch self {
        case .onTrack, .withinPlan: "checkmark.circle.fill"
        case .atRisk: "exclamationmark.triangle.fill"
        case .over: "xmark.octagon.fill"
        }
    }

    var tint: Color {
        switch self {
        case .onTrack, .withinPlan: .green
        case .atRisk: .orange
        case .over: .red
        }
    }

    /// Sorts the categories that need attention first.
    var urgency: Int {
        switch self {
        case .over: 0
        case .atRisk: 1
        case .onTrack, .withinPlan: 2
        }
    }
}

/// One month's spending in one category, as the store keeps it.
struct PLActivity {
    var spent: Decimal = 0
    /// The part of `spent` that didn't come from recurring templates (PLN-003).
    var variable: Decimal = 0
    /// Pending and upcoming recurring expenses still due this month.
    var recurringDue: Decimal = 0
}

/// A category as the Plan shows it for one month.
struct PLEntry: Identifiable {
    let category: ExplorationCategory
    /// Nil for a category without a plan ("Unplanned").
    let planned: Decimal?
    let spent: Decimal
    /// The pace part of the projection. Nil in a finished month and during the first 3 days (A-09).
    let pace: Decimal?
    let recurringDue: Decimal
    let isFinished: Bool

    var id: String { category.id }

    /// PLN-003: spent + pace + recurring still due. Current month only.
    var projected: Decimal? {
        isFinished ? nil : spent + (pace ?? 0) + recurringDue
    }

    var remaining: Decimal? { planned.map { $0 - spent } }

    var status: PLStatus? {
        planned.map { PLStatus(planned: $0, spent: spent, projected: projected) }
    }

    /// For bars: the projection, or what was spent once the month is over.
    var projectedOrSpent: Decimal { projected ?? spent }
}

/// Everything the Plan shows for one month (PLN-002).
struct PLReport {
    let month: Date
    let isCurrent: Bool
    /// Planned categories, the ones that need attention first.
    let entries: [PLEntry]
    /// Categories with spending but no plan, largest first.
    let unplanned: [PLEntry]
    let dayOfMonth: Int
    let daysInMonth: Int

    var hasPlan: Bool { !entries.isEmpty }
    /// A-09: no pace estimate during the first 3 days.
    var showsPace: Bool { isCurrent && dayOfMonth > 3 }
    var daysLeft: Int { daysInMonth - dayOfMonth }

    var planned: Decimal { entries.reduce(0) { $0 + ($1.planned ?? 0) } }
    var unplannedSpent: Decimal { unplanned.reduce(0) { $0 + $1.spent } }
    /// Spending in every category, unplanned included, as Home's plan card counts it.
    var spent: Decimal { (entries + unplanned).reduce(0) { $0 + $1.spent } }
    var projected: Decimal? {
        isCurrent ? (entries + unplanned).reduce(0) { $0 + $1.projectedOrSpent } : nil
    }
    var unplannedProjected: Decimal { unplanned.reduce(0) { $0 + $1.projectedOrSpent } }
    var recurringDue: Decimal { (entries + unplanned).reduce(0) { $0 + $1.recurringDue } }
    var remaining: Decimal { planned - spent }
    var status: PLStatus? { hasPlan ? PLStatus(planned: planned, spent: spent, projected: projected) : nil }

    /// How many planned categories have each status.
    func count(_ status: PLStatus) -> Int {
        entries.filter { $0.status == status }.count
    }
}

/// A month that has ended, with the plan it had then (A-08) and what was spent.
struct PLPastMonth {
    let month: Date
    let planned: [String: Decimal]
    let spent: [String: Decimal]
}

@Observable
final class PLStore {
    let code = "EUR"
    /// The planned amounts from this month onward, by category ID (PLN-001).
    private(set) var plan: [String: Decimal]
    /// This month's spending by category ID.
    private let activity: [String: PLActivity]
    /// Newest first.
    private let past: [PLPastMonth]
    /// Fixed so the sample reads the same on any day.
    let dayOfMonth: Int
    /// The month on screen.
    var month: Date

    init(plan: [String: Decimal], activity: [String: PLActivity], past: [PLPastMonth], dayOfMonth: Int) {
        self.plan = plan
        self.activity = activity
        self.past = past
        self.dayOfMonth = dayOfMonth
        month = Self.currentMonth
    }

    private static var calendar: Calendar { .current }

    static var currentMonth: Date {
        calendar.dateInterval(of: .month, for: .now)?.start ?? .now
    }

    /// Newest first: this month, then past months back to the first one with spending.
    var months: [Date] { [Self.currentMonth] + past.map(\.month) }

    var isCurrentMonth: Bool { month == Self.currentMonth }
    var canGoBack: Bool { month != months.last }
    var canGoForward: Bool { !isCurrentMonth }

    func step(by offset: Int) {
        guard let index = months.firstIndex(of: month) else { return }
        let target = index - offset
        guard months.indices.contains(target) else { return }
        month = months[target]
    }

    /// Expense categories the plan can use (PLN-001). Archived ones would be left out.
    var activeCategories: [ExplorationCategory] { ExplorationCategory.expenseCategories }

    var hasPlan: Bool { !plan.isEmpty }

    func planned(for category: ExplorationCategory) -> Decimal? {
        plan[category.id]
    }

    /// Sets or clears (nil or zero) a planned amount from this month onward. Past months keep theirs (A-08).
    func setPlanned(_ amount: Decimal?, for category: ExplorationCategory) {
        if let amount, amount > 0 {
            plan[category.id] = amount
        } else {
            plan[category.id] = nil
        }
    }

    func replacePlan(with amounts: [String: Decimal]) {
        plan = amounts.filter { $0.value > 0 }
    }

    var report: PLReport { report(for: month) }

    func report(for month: Date) -> PLReport {
        let days = Self.calendar.range(of: .day, in: .month, for: month)?.count ?? 30
        if month == Self.currentMonth {
            return makeReport(month: month, day: dayOfMonth, days: days, planned: plan, isCurrent: true) {
                activity[$0] ?? PLActivity()
            }
        }
        let record = past.first { $0.month == month }
        return makeReport(month: month, day: days, days: days, planned: record?.planned ?? [:], isCurrent: false) {
            PLActivity(spent: record?.spent[$0] ?? 0)
        }
    }

    private func makeReport(
        month: Date,
        day: Int,
        days: Int,
        planned: [String: Decimal],
        isCurrent: Bool,
        activity: (String) -> PLActivity
    ) -> PLReport {
        var entries: [PLEntry] = []
        var unplanned: [PLEntry] = []
        for category in ExplorationCategory.expenseCategories {
            let figures = activity(category.id)
            let pace: Decimal? = isCurrent && day > 3
                ? AEMoney.rounded(figures.variable / Decimal(day) * Decimal(days - day), fractionDigits: 2, mode: .plain)
                : nil
            let entry = PLEntry(
                category: category,
                planned: planned[category.id],
                spent: figures.spent,
                pace: pace,
                recurringDue: figures.recurringDue,
                isFinished: !isCurrent
            )
            if entry.planned != nil {
                entries.append(entry)
            } else if entry.spent > 0 {
                unplanned.append(entry)
            }
        }
        entries.sort { ($0.status?.urgency ?? 3, $1.planned ?? 0) < ($1.status?.urgency ?? 3, $0.planned ?? 0) }
        unplanned.sort { $0.spent > $1.spent }
        return PLReport(
            month: month,
            isCurrent: isCurrent,
            entries: entries,
            unplanned: unplanned,
            dayOfMonth: day,
            daysInMonth: days
        )
    }
}

// MARK: - Samples

extension PLStore {
    /// Mid-month (day 18) with every status and some unplanned spending.
    static var sample: PLStore {
        PLStore(plan: samplePlan, activity: sampleActivity, past: samplePast, dayOfMonth: 18)
    }

    /// The same plan on day 2, before the pace estimate starts (A-09).
    static var earlyMonth: PLStore {
        PLStore(
            plan: samplePlan,
            activity: [
                "housing": PLActivity(spent: amount("750.00"), recurringDue: 0),
                "groceries": PLActivity(spent: amount("41.80"), variable: amount("41.80")),
                "subscriptions": PLActivity(spent: amount("15.99"), recurringDue: amount("29.98")),
                "bills": PLActivity(recurringDue: amount("131.40")),
                "health": PLActivity(recurringDue: amount("39.90")),
                "transport": PLActivity(spent: amount("38.00")),
            ],
            past: samplePast,
            dayOfMonth: 2
        )
    }

    /// No plan yet, and none in the past: Plan invites the user to set one up.
    static var noPlan: PLStore {
        PLStore(
            plan: [:],
            activity: sampleActivity,
            past: samplePast.map { PLPastMonth(month: $0.month, planned: [:], spent: $0.spent) },
            dayOfMonth: 18
        )
    }

    /// Showing last month, read-only.
    static var lastMonth: PLStore {
        let store = sample
        store.step(by: -1)
        return store
    }

    private static var samplePlan: [String: Decimal] {
        [
            "housing": amount("750"),
            "groceries": amount("300"),
            "dining": amount("80"),
            "fuel": amount("100"),
            "bills": amount("120"),
            "leisure": amount("200"),
            "subscriptions": amount("45"),
            "health": amount("40"),
        ]
    }

    /// Day 18 of the month. Recurring: rent, bills, subscriptions, the gym and the metro pass.
    private static var sampleActivity: [String: PLActivity] {
        [
            "housing": PLActivity(spent: amount("750.00")),
            "groceries": PLActivity(spent: amount("172.40"), variable: amount("172.40")),
            "dining": PLActivity(spent: amount("96.50"), variable: amount("96.50")),
            "fuel": PLActivity(spent: amount("64.20"), variable: amount("64.20")),
            "bills": PLActivity(spent: amount("86.40"), recurringDue: amount("45.00")),
            "leisure": PLActivity(spent: amount("45.00"), variable: amount("45.00")),
            "subscriptions": PLActivity(spent: amount("27.98"), recurringDue: amount("12.99")),
            "health": PLActivity(recurringDue: amount("39.90")),
            "transport": PLActivity(spent: amount("38.00")),
            "shopping": PLActivity(spent: amount("54.90"), variable: amount("54.90")),
        ]
    }

    /// The plan started two months ago, and Dining and Leisure were changed last month (A-08).
    private static var samplePast: [PLPastMonth] {
        let calendar = Calendar.current
        func monthsAgo(_ count: Int) -> Date {
            calendar.date(byAdding: .month, value: -count, to: currentMonth) ?? currentMonth
        }
        let spentLastMonth: [String: Decimal] = [
            "housing": amount("750.00"), "groceries": amount("284.10"), "dining": amount("112.40"),
            "fuel": amount("91.30"), "bills": amount("131.40"), "leisure": amount("138.00"),
            "subscriptions": amount("40.97"), "health": amount("39.90"), "transport": amount("38.00"),
            "travel": amount("212.00"),
        ]
        let spentTwoMonthsAgo: [String: Decimal] = [
            "housing": amount("750.00"), "groceries": amount("318.75"), "dining": amount("64.20"),
            "fuel": amount("102.10"), "bills": amount("118.20"), "leisure": amount("96.00"),
            "subscriptions": amount("40.97"), "health": amount("39.90"), "transport": amount("38.00"),
        ]
        let spentThreeMonthsAgo: [String: Decimal] = [
            "housing": amount("750.00"), "groceries": amount("296.40"), "dining": amount("138.90"),
            "fuel": amount("84.00"), "bills": amount("124.60"), "leisure": amount("210.00"),
            "subscriptions": amount("40.97"), "transport": amount("38.00"), "shopping": amount("89.99"),
        ]
        var lastMonthPlan = samplePlan
        lastMonthPlan["dining"] = amount("100")
        lastMonthPlan["leisure"] = amount("150")
        var olderPlan = lastMonthPlan
        olderPlan["health"] = nil
        return [
            PLPastMonth(month: monthsAgo(1), planned: lastMonthPlan, spent: spentLastMonth),
            PLPastMonth(month: monthsAgo(2), planned: olderPlan, spent: spentTwoMonthsAgo),
            PLPastMonth(month: monthsAgo(3), planned: [:], spent: spentThreeMonthsAgo),
        ]
    }

    /// Parses from a string so mock amounts never pass through floating point (NFR-005).
    private static func amount(_ value: String) -> Decimal {
        Decimal(string: value, locale: Locale(identifier: "en_US_POSIX")) ?? 0
    }
}
#endif
