//
//  HistoryModel.swift
//  Finlark
//
//  FIN-9 History: the mock store behind every History exploration (TRX-005). Transactions are the
//  detail's `TDRecord`s, so a row opens Birch as it is, and edits or deletes there show up here.
//  Filters are by month, type and category; search looks in notes. Throwaway design code, Debug only.
//

#if DEBUG
import SwiftUI

/// The type filter (TRX-005).
enum HYTypeFilter: CaseIterable, Identifiable, Hashable {
    case all
    case expense
    case income

    var id: Self { self }

    var title: LocalizedStringKey {
        switch self {
        case .all: "All"
        case .expense: "Expenses"
        case .income: "Income"
        }
    }

    var type: ExplorationTransactionType? {
        switch self {
        case .all: nil
        case .expense: .expense
        case .income: .income
        }
    }
}

extension TDRecord {
    /// What this transaction adds to spending: the user's share of a split, the full amount otherwise,
    /// and nothing for an income.
    var spending: Decimal {
        guard saved.type == .expense else { return 0 }
        return isSplit ? myShare : saved.total
    }

    var income: Decimal {
        saved.type == .income ? saved.total : 0
    }
}

/// Income and spending for a set of transactions (TRX-005). Repayments are neither.
struct HYTotals {
    var income: Decimal = 0
    var spending: Decimal = 0

    init(_ records: some Sequence<TDRecord>) {
        for record in records {
            income += record.income
            spending += record.spending
        }
    }
}

struct HYDay: Identifiable {
    let date: Date
    let records: [TDRecord]

    var id: Date { date }
    var totals: HYTotals { HYTotals(records) }
}

struct HYMonth: Identifiable {
    let month: Date
    let days: [HYDay]

    var id: Date { month }
    var records: [TDRecord] { days.flatMap(\.records) }
    var totals: HYTotals { HYTotals(records) }
}

@Observable
final class HYStore {
    /// Newest first. A transaction added later on the same day comes first, since there's no time.
    private(set) var all: [TDRecord]

    /// The month shown, or every month when nil.
    var month: Date?
    var type: HYTypeFilter = .all {
        didSet {
            let allowed = Set(categoryOptions.map(\.id))
            categoryIDs = categoryIDs.intersection(allowed)
        }
    }
    /// Empty means every category.
    var categoryIDs: Set<String> = []
    var searchText = ""
    /// A single day, for the variants that pick one from a calendar or chart.
    var day: Date?
    /// Whether search ignores the month. Off when the month is itself part of the search.
    var searchesEveryMonth = true

    init(_ records: [TDRecord], month: Date? = .now) {
        all = records
        if let month {
            self.month = Self.startOfMonth(month)
        }
    }

    private static var calendar: Calendar { .current }

    static func startOfMonth(_ date: Date) -> Date {
        calendar.dateInterval(of: .month, for: date)?.start ?? date
    }

    var code: String { all.first?.code ?? "EUR" }

    var records: [TDRecord] { all.filter { !$0.isDeleted } }

    /// Months that have transactions, plus the current one, newest first.
    var months: [Date] {
        Set(records.map { Self.startOfMonth($0.saved.date) } + [Self.startOfMonth(.now)]).sorted(by: >)
    }

    // MARK: Filters

    private var query: String { searchText.trimmingCharacters(in: .whitespacesAndNewlines) }

    var isSearching: Bool { !query.isEmpty }
    var hasFilters: Bool { type != .all || !categoryIDs.isEmpty }
    var filterCount: Int { (type == .all ? 0 : 1) + categoryIDs.count }
    /// Whether the list shows less than the whole month.
    var isNarrowed: Bool { hasFilters || isSearching || day != nil }

    /// The categories the category filter offers, by the type filter.
    var categoryOptions: [ExplorationCategory] {
        switch type {
        case .all: ExplorationCategory.all
        case .expense: ExplorationCategory.expenseCategories
        case .income: ExplorationCategory.incomeCategories
        }
    }

    var selectedCategories: [ExplorationCategory] {
        categoryOptions.filter { categoryIDs.contains($0.id) }
    }

    func isSelected(_ category: ExplorationCategory) -> Binding<Bool> {
        Binding {
            self.categoryIDs.contains(category.id)
        } set: { isOn in
            if isOn { self.categoryIDs.insert(category.id) } else { self.categoryIDs.remove(category.id) }
        }
    }

    func toggle(_ category: ExplorationCategory) {
        isSelected(category).wrappedValue.toggle()
    }

    func clearFilters() {
        type = .all
        categoryIDs = []
    }

    /// Type, category and search in notes (TRX-005).
    func matches(_ record: TDRecord) -> Bool {
        if let type = type.type, record.saved.type != type { return false }
        if !categoryIDs.isEmpty, !categoryIDs.contains(record.saved.categoryID ?? "") { return false }
        if isSearching, !record.saved.note.localizedStandardContains(query) { return false }
        return true
    }

    /// Matching transactions in a month (every month when nil), newest first.
    func results(in month: Date?, day: Date? = nil) -> [TDRecord] {
        let calendar = Self.calendar
        let matching = records.enumerated().filter { _, record in
            let date = record.saved.date
            if let month, !calendar.isDate(date, equalTo: month, toGranularity: .month) { return false }
            if let day, !calendar.isDate(date, inSameDayAs: day) { return false }
            return matches(record)
        }
        return matching.sorted { lhs, rhs in
            let left = calendar.startOfDay(for: lhs.element.saved.date)
            let right = calendar.startOfDay(for: rhs.element.saved.date)
            return left == right ? lhs.offset < rhs.offset : left > right
        }
        .map(\.element)
    }

    /// What the list shows. Search looks through every month, so a note is found wherever it is.
    var results: [TDRecord] {
        isSearching && searchesEveryMonth ? results(in: nil) : results(in: month, day: day)
    }

    var days: [HYDay] { Self.days(results) }
    var monthGroups: [HYMonth] { Self.monthGroups(results) }
    /// Totals for what's shown: the month, or the filtered part of it.
    var totals: HYTotals { HYTotals(results) }

    /// Groups transactions that are already newest first by day (TRX-005).
    static func days(_ records: [TDRecord]) -> [HYDay] {
        var days: [HYDay] = []
        for record in records {
            let day = calendar.startOfDay(for: record.saved.date)
            if let last = days.last, last.date == day {
                days[days.count - 1] = HYDay(date: day, records: last.records + [record])
            } else {
                days.append(HYDay(date: day, records: [record]))
            }
        }
        return days
    }

    static func monthGroups(_ records: [TDRecord]) -> [HYMonth] {
        var groups: [(month: Date, records: [TDRecord])] = []
        for record in records {
            let month = startOfMonth(record.saved.date)
            if let last = groups.last, last.month == month {
                groups[groups.count - 1].records.append(record)
            } else {
                groups.append((month, [record]))
            }
        }
        return groups.map { HYMonth(month: $0.month, days: days($0.records)) }
    }

    // MARK: Month stepping

    var canGoBack: Bool {
        guard let month, let oldest = months.last else { return false }
        return month > oldest
    }

    var canGoForward: Bool {
        guard let month else { return false }
        return month < Self.startOfMonth(.now)
    }

    func step(by months: Int) {
        guard let month, let next = Self.calendar.date(byAdding: .month, value: months, to: month) else { return }
        self.month = next
        day = nil
    }

    // MARK: Adding (TRX-001 from History)

    func add(_ draft: AEDraft) {
        all.insert(TDRecord(draft), at: 0)
    }
}

// MARK: - Samples

extension HYStore {
    /// Three months of transactions with splits in every status, incomes, and rows without a note.
    static var sample: HYStore { HYStore(sampleRecords) }

    /// Every month in one list, for the variants that don't page by month.
    static var allMonths: HYStore { HYStore(sampleRecords, month: nil) }

    /// First launch: nothing yet.
    static var empty: HYStore { HYStore([]) }

    /// Searching notes for "rent", which finds one per month.
    static var searching: HYStore {
        let store = HYStore(sampleRecords)
        store.searchText = "rent"
        return store
    }

    private static func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .now
    }

    private static func make(
        _ days: Int, _ type: ExplorationTransactionType, _ amount: String, _ category: ExplorationCategory,
        _ note: String = "", splitWith people: [AEPerson] = [], repaid: [(AEPerson, String, Int)] = []
    ) -> TDRecord {
        TDRecord(
            AEDraft(
                purpose: .edit, type: type, amount: Decimal(string: amount) ?? 0, date: daysAgo(days),
                categoryID: category.id, note: note, isSplit: !people.isEmpty, participants: people
            ),
            repayments: repaid.map { person, amount, days in
                TDRepayment(personID: person.id, amount: Decimal(string: amount) ?? 0, date: daysAgo(days))
            }
        )
    }

    static var sampleRecords: [TDRecord] {
        [
            make(0, .expense, "23.80", .groceries, "Mercadona"),
            make(0, .expense, "12.40", .transport),
            .groceries,
            make(2, .expense, "12.99", .subscriptions, "Spotify"),
            make(3, .expense, "18.50", .dining, "Lunch with Luis", splitWith: [.luis], repaid: [(.luis, "9.25", 2)]),
            .salary,
            .pizzeria,
            make(6, .expense, "62", .fuel, "Repsol"),
            make(7, .expense, "36", .leisure, "Cinema", splitWith: [.ana, .pablo]),
            make(9, .expense, "24.95", .health, "Pharmacy"),
            make(11, .income, "29.99", .refunds, "Jacket return"),
            .dinner,
            make(14, .expense, "850", .housing, "Rent"),
            make(15, .expense, "64.20", .bills, "Electricity"),
            make(18, .expense, "45", .shopping),
            make(20, .expense, "38.75", .groceries, "Lidl"),
            make(23, .expense, "240", .travel, "Train to Madrid", splitWith: [.marta], repaid: [(.marta, "120", 21)]),
            make(26, .income, "50", .gifts, "Birthday from Grandma"),
            make(31, .income, "2150", .salary, "Acme payroll"),
            make(32, .expense, "850", .housing, "Rent"),
            make(33, .expense, "61.20", .groceries, "Weekly shop"),
            make(36, .expense, "84", .dining, "Tapas", splitWith: [.marta, .luis], repaid: [(.marta, "28", 35), (.luis, "28", 30)]),
            make(40, .expense, "58.10", .bills, "Electricity"),
            make(42, .expense, "40", .transport, "Metro pass"),
            make(47, .expense, "22", .leisure, "Concert tickets"),
            make(50, .expense, "47.30", .groceries, "Mercadona"),
            make(55, .expense, "120", .shopping, "Running shoes"),
            make(61, .income, "2150", .salary, "Acme payroll"),
            make(62, .expense, "850", .housing, "Rent"),
            make(66, .expense, "380", .travel, "Hotel in Lisbon", splitWith: [.ana], repaid: [(.ana, "100", 50)]),
            make(70, .expense, "32", .dining, "Beach bar"),
            make(75, .expense, "55.10", .groceries, "Weekly shop"),
        ]
    }
}
#endif
