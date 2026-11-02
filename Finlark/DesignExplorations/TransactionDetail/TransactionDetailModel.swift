//
//  TransactionDetailModel.swift
//  Finlark
//
//  FIN-9 Transaction detail: the mock transaction behind every detail exploration (TRX-004, TRX-006,
//  SPL-005–009, SPL-011). The saved fields are an `AEDraft`, so Edit reuses Dunlin as it is, and
//  repayments sit next to it. A repayment can't exceed what's left on its share (A-04). Throwaway
//  design code, Debug only.
//

#if DEBUG
import SwiftUI

/// Money a friend gave back for their share (SPL-006, SPL-007). It raises the balance, but it isn't
/// income and doesn't change spending.
struct TDRepayment: Identifiable {
    let id = UUID()
    let personID: AEPerson.ID
    var amount: Decimal
    var date: Date
}

/// A debtor's status on one split (SPL-005). Always shown with its icon and words, never color alone.
enum TDStatus {
    case pending
    case partiallyPaid
    case paid

    var symbol: String {
        switch self {
        case .pending: "clock.fill"
        case .partiallyPaid: "circle.lefthalf.filled"
        case .paid: "checkmark.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .pending: .orange
        case .partiallyPaid: .blue
        case .paid: .green
        }
    }
}

/// One friend's part of a split: share, paid so far, remaining and status (SPL-005).
struct TDDebt: Identifiable {
    let person: AEPerson
    let share: Decimal
    /// Oldest first.
    let repayments: [TDRepayment]

    var id: AEPerson.ID { person.id }
    var paid: Decimal { repayments.reduce(0) { $0 + $1.amount } }
    var remaining: Decimal { max(share - paid, 0) }

    var status: TDStatus {
        if remaining == 0 { return .paid }
        return paid > 0 ? .partiallyPaid : .pending
    }

    /// For drawing only.
    var progress: Double {
        share > 0 ? min(paid.plotValue / share.plotValue, 1) : 1
    }
}

@Observable
final class TDRecord: Identifiable, Hashable {
    let id = UUID()
    /// The saved fields. Editing works on a copy (`editingDraft()`), so Cancel leaves this alone.
    private(set) var saved: AEDraft
    private(set) var repayments: [TDRepayment]
    /// Stands in for removing it from the store, so the History stand-in drops it.
    private(set) var isDeleted = false

    init(_ saved: AEDraft, repayments: [TDRepayment] = []) {
        self.saved = saved
        self.repayments = repayments
    }

    static func == (lhs: TDRecord, rhs: TDRecord) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    var code: String { saved.currencyCode }
    var isSplit: Bool { saved.isSplit }

    /// The full amount paid, with its sign for the balance.
    var signedAmount: Decimal { saved.type == .expense ? -saved.total : saved.total }

    /// The note, or the category name when there's no note.
    var title: Text {
        if !saved.note.isEmpty { return Text(verbatim: saved.note) }
        return saved.category.map { Text($0.name) } ?? Text(saved.type.title)
    }

    // MARK: Split detail (SPL-005)

    /// Each friend's share, in the order they were added.
    var debts: [TDDebt] {
        guard saved.isSplit else { return [] }
        return saved.shares.filter { !$0.person.isMe }.map { share in
            TDDebt(
                person: share.person,
                share: share.amount,
                repayments: repayments.filter { $0.personID == share.person.id }.sorted { $0.date < $1.date }
            )
        }
    }

    func debt(for person: AEPerson) -> TDDebt? {
        debts.first { $0.id == person.id }
    }

    var myShare: Decimal { saved.myShare }
    var totalRepaid: Decimal { repayments.reduce(0) { $0 + $1.amount } }
    var owedToYou: Decimal { debts.reduce(0) { $0 + $1.remaining } }
    var openDebts: [TDDebt] { debts.filter { $0.status != .paid } }

    /// Newest first, across everyone.
    var history: [TDRepayment] { repayments.sorted { $0.date > $1.date } }

    func person(_ id: AEPerson.ID) -> AEPerson? {
        saved.everyone.first { $0.id == id }
    }

    // MARK: Repayments (SPL-006, SPL-007, SPL-009)

    /// The most a repayment can be: what's left on the share, plus the repayment itself when it's the
    /// one being edited (A-04).
    func maximum(for personID: AEPerson.ID, editing repaymentID: TDRepayment.ID? = nil) -> Decimal {
        let remaining = debts.first { $0.id == personID }?.remaining ?? 0
        let current = repayments.first { $0.id == repaymentID }?.amount ?? 0
        return remaining + current
    }

    /// Records a repayment for everything that's left (SPL-006).
    func markPaid(_ person: AEPerson, on date: Date = .now) {
        record(maximum(for: person.id), from: person, on: date)
    }

    /// Records part of a share (SPL-007). Amounts over what's left are refused (A-04).
    func record(_ amount: Decimal, from person: AEPerson, on date: Date) {
        guard amount > 0, amount <= maximum(for: person.id) else { return }
        repayments.append(TDRepayment(personID: person.id, amount: amount, date: date))
    }

    func update(_ id: TDRepayment.ID, amount: Decimal, date: Date) {
        guard let index = repayments.firstIndex(where: { $0.id == id }),
              amount > 0, amount <= maximum(for: repayments[index].personID, editing: id) else { return }
        repayments[index].amount = amount
        repayments[index].date = date
    }

    func undo(_ id: TDRepayment.ID) {
        repayments.removeAll { $0.id == id }
    }

    // MARK: Edit and delete (TRX-003, TRX-004, SPL-010, SPL-011)

    /// A copy for Dunlin, which knows what each person repaid so it keeps SPL-010's limits.
    func editingDraft() -> AEDraft {
        saved.copy(repaid: Dictionary(grouping: repayments, by: \.personID).mapValues {
            $0.reduce(0) { $0 + $1.amount }
        })
    }

    func save(_ draft: AEDraft) {
        saved = draft
    }

    /// Removes the transaction with its shares and repayments (A-06).
    func delete() {
        repayments.removeAll()
        isDeleted = true
    }
}

// MARK: - Samples

extension TDRecord {
    private static func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .now
    }

    /// SPL-001's dinner, €120 equal among four: Ana paid her €30, Luis paid €20 of €30 (SPL-007), and
    /// Marta is still pending (SPL-006).
    static var dinner: TDRecord {
        TDRecord(
            AEDraft(
                purpose: .edit, type: .expense, amount: 120, date: daysAgo(12),
                categoryID: ExplorationCategory.dining.id, note: "Dinner at Casa Pepe", isSplit: true,
                participants: [.marta, .luis, .ana]
            ),
            repayments: [
                TDRepayment(personID: AEPerson.ana.id, amount: 30, date: daysAgo(10)),
                TDRepayment(personID: AEPerson.luis.id, amount: 20, date: daysAgo(3)),
            ]
        )
    }

    /// SPL-004's pizzeria: Ana owes €21 and has paid €10 back.
    static var pizzeria: TDRecord {
        let draft = AEDraft.editByItemSample
        draft.date = daysAgo(5)
        return TDRecord(draft, repayments: [
            TDRepayment(personID: AEPerson.ana.id, amount: 10, date: daysAgo(2)),
        ])
    }

    static var groceries: TDRecord {
        TDRecord(AEDraft(
            purpose: .edit, type: .expense, amount: Decimal(string: "54.30") ?? 0, date: daysAgo(1),
            categoryID: ExplorationCategory.groceries.id, note: "Weekly shop"
        ))
    }

    static var salary: TDRecord {
        TDRecord(AEDraft(
            purpose: .edit, type: .income, amount: 2150, date: daysAgo(4),
            categoryID: ExplorationCategory.salary.id, note: "October salary"
        ))
    }

    static var samples: [TDRecord] { [dinner, pizzeria, groceries, salary] }
}
#endif
