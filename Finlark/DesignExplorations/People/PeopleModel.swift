//
//  PeopleModel.swift
//  Finlark
//
//  FIN-9 People: the mock store behind every People exploration (PPL-001…004, SPL-008, NTF-003). It
//  holds the people the user splits with, their share of each split and the repayments on it, and
//  works out what each one owes the way the requirements describe it. Throwaway design code, Debug only.
//

#if DEBUG
import SwiftUI

/// Money a friend gave back for one share. Raises the balance; not income, no change to spending.
struct PPRepayment: Identifiable {
    let id = UUID()
    let amount: Decimal
    let date: Date
}

/// A person's part of one split the user paid (PPL-003): the ticket, its date, the share, what's been
/// paid back and what's left.
struct PPShare: Identifiable {
    let id = UUID()
    let ticket: String
    let date: Date
    let category: ExplorationCategory
    /// The full amount the user paid for the ticket.
    let total: Decimal
    let share: Decimal
    /// Oldest first.
    var repayments: [PPRepayment] = []

    var paid: Decimal { repayments.reduce(0) { $0 + $1.amount } }
    var remaining: Decimal { max(share - paid, 0) }
    var isOpen: Bool { remaining > 0 }

    var status: TDStatus {
        if remaining == 0 { return .paid }
        return paid > 0 ? .partiallyPaid : .pending
    }

    /// When the last repayment came in, for settled history.
    var settledOn: Date? { isOpen ? nil : repayments.last?.date }

    /// For drawing only.
    var progress: Double {
        share > 0 ? min(paid.plotValue / share.plotValue, 1) : 1
    }

    /// Whole days since the ticket.
    var age: Int {
        Calendar.current.dateComponents([.day], from: date, to: .now).day ?? 0
    }

    /// *Pending*, *Partially paid X of Y* or *Paid* (SPL-005).
    func statusText(code: String) -> Text {
        switch status {
        case .pending:
            Text("Pending")
        case .partiallyPaid:
            Text("Partially paid \(paid, format: .currency(code: code)) of \(share, format: .currency(code: code))")
        case .paid:
            Text("Paid")
        }
    }
}

/// A friend the user splits expenses with (PPL-001). A local record: friends don't need Finlark.
struct PPPerson: Identifiable {
    let id: String
    var name: String
    var isArchived = false
    /// Newest first.
    var shares: [PPShare] = []

    /// The same avatar and color as in Add & edit and the split detail.
    var avatar: AEPerson { AEPerson(id: id, name: name) }
    var color: Color { avatar.color }

    var openShares: [PPShare] { shares.filter(\.isOpen) }
    /// Fully paid shares, most recently settled first.
    var settledShares: [PPShare] {
        shares.filter { !$0.isOpen }.sorted { ($0.settledOn ?? $0.date) > ($1.settledOn ?? $1.date) }
    }

    var owed: Decimal { openShares.reduce(0) { $0 + $1.remaining } }
    var owes: Bool { owed > 0 }
    var oldestOpen: PPShare? { openShares.min { $0.date < $1.date } }

    /// Everything they've ever paid back, for the settled history.
    var totalRepaid: Decimal { shares.reduce(0) { $0 + $1.paid } }

    /// A person with open shares can't be archived or deleted (PPL-004).
    var canArchive: Bool { !owes }
}

@Observable
final class PPStore {
    let code = "EUR"
    private(set) var people: [PPPerson]

    init(people: [PPPerson]) {
        self.people = people
    }

    // MARK: List (PPL-002)

    /// People who aren't archived: those who owe first (most owed first), then the rest by name.
    var active: [PPPerson] {
        people.filter { !$0.isArchived }.sorted { lhs, rhs in
            if lhs.owes != rhs.owes { return lhs.owes }
            if lhs.owes { return lhs.owed > rhs.owed }
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }

    var owing: [PPPerson] { active.filter(\.owes) }
    var settled: [PPPerson] { active.filter { !$0.owes } }
    var archived: [PPPerson] { people.filter(\.isArchived).sorted { $0.name < $1.name } }

    /// The overall "Owed to you" total (PPL-002).
    var owedToYou: Decimal { owing.reduce(0) { $0 + $1.owed } }
    var openShareCount: Int { owing.reduce(0) { $0 + $1.openShares.count } }

    func person(_ id: PPPerson.ID) -> PPPerson? {
        people.first { $0.id == id }
    }

    // MARK: Changes (PPL-001, PPL-004)

    static func isValidName(_ name: String) -> Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Adds a person and returns them, or nil when the name is empty (PPL-001).
    @discardableResult
    func add(named name: String) -> PPPerson? {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return nil }
        let person = PPPerson(id: UUID().uuidString, name: clean)
        people.append(person)
        return person
    }

    func rename(_ id: PPPerson.ID, to name: String) {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty, let index = index(id) else { return }
        people[index].name = clean
    }

    /// Hides a person from pickers and keeps their history. Refused while they owe anything (PPL-004).
    func setArchived(_ isArchived: Bool, _ id: PPPerson.ID) {
        guard let index = index(id), !isArchived || people[index].canArchive else { return }
        people[index].isArchived = isArchived
    }

    // MARK: Repayments (SPL-006, SPL-008)

    /// Settle all: a repayment for what's left on every open share, all on the same date (SPL-008).
    /// Returns the repayments so they can be undone.
    @discardableResult
    func settleAll(_ id: PPPerson.ID, on date: Date = .now) -> [PPRepayment] {
        guard let index = index(id) else { return [] }
        var recorded: [PPRepayment] = []
        for shareIndex in people[index].shares.indices where people[index].shares[shareIndex].isOpen {
            let repayment = PPRepayment(amount: people[index].shares[shareIndex].remaining, date: date)
            people[index].shares[shareIndex].repayments.append(repayment)
            recorded.append(repayment)
        }
        return recorded
    }

    /// Marks one share paid, for variants that offer it next to the share (SPL-006). Returns the
    /// repayment so it can be undone.
    @discardableResult
    func markPaid(_ shareID: PPShare.ID, of id: PPPerson.ID, on date: Date = .now) -> PPRepayment? {
        guard let share = person(id)?.shares.first(where: { $0.id == shareID }) else { return nil }
        return record(share.remaining, on: shareID, of: id, on: date)
    }

    /// Records part or all of what's left on one share (SPL-006, SPL-007). Amounts over what's left
    /// are refused (A-04).
    @discardableResult
    func record(_ amount: Decimal, on shareID: PPShare.ID, of id: PPPerson.ID, on date: Date = .now) -> PPRepayment? {
        guard let index = index(id),
              let shareIndex = people[index].shares.firstIndex(where: { $0.id == shareID }),
              amount > 0, amount <= people[index].shares[shareIndex].remaining else { return nil }
        let repayment = PPRepayment(amount: amount, date: date)
        people[index].shares[shareIndex].repayments.append(repayment)
        people[index].shares[shareIndex].repayments.sort { $0.date < $1.date }
        return repayment
    }

    /// Deletes a repayment, for Undo right after recording it (SPL-009).
    func undo(_ repaymentID: PPRepayment.ID, of id: PPPerson.ID) {
        guard let index = index(id) else { return }
        for shareIndex in people[index].shares.indices {
            people[index].shares[shareIndex].repayments.removeAll { $0.id == repaymentID }
        }
    }

    func share(_ shareID: PPShare.ID, of id: PPPerson.ID) -> PPShare? {
        person(id)?.shares.first { $0.id == shareID }
    }

    // MARK: Reminder (NTF-003)

    /// "Hi Marta! Friendly reminder: Dinner at Casa Pepe €30.00, Cinema €25.00, total €55.00."
    func reminder(for person: PPPerson) -> String {
        let format = Decimal.FormatStyle.Currency(code: code)
        let lines = person.openShares.sorted { $0.date < $1.date }
            .map { "\($0.ticket) \($0.remaining.formatted(format))" }
            .formatted(.list(type: .and, width: .narrow))
        return String(localized: "Hi \(person.name)! Friendly reminder: \(lines), total \(person.owed.formatted(format)).")
    }

    private func index(_ id: PPPerson.ID) -> Int? {
        people.firstIndex { $0.id == id }
    }
}

// MARK: - Samples

extension PPStore {
    private static func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .now
    }

    private static func paid(_ amount: Decimal, _ days: Int) -> PPRepayment {
        PPRepayment(amount: amount, date: daysAgo(days))
    }

    /// €94.00 owed by three people: Marta has two pending shares (SPL-008's €30 and €25), Luis paid part
    /// of one (SPL-007) and Ana part of the pizzeria (SPL-004). Pablo is settled up, Lucía was just added
    /// and Jorge is archived.
    static var sample: PPStore {
        PPStore(people: [
            PPPerson(id: "marta", name: "Marta", shares: [
                PPShare(ticket: "Cinema", date: daysAgo(6), category: .leisure, total: 50, share: 25),
                PPShare(ticket: "Dinner at Casa Pepe", date: daysAgo(12), category: .dining, total: 120, share: 30),
                PPShare(ticket: "Concert tickets", date: daysAgo(41), category: .leisure, total: 80, share: 40,
                        repayments: [paid(40, 35)]),
            ]),
            PPPerson(id: "luis", name: "Luis", shares: [
                PPShare(ticket: "Taxi to the airport", date: daysAgo(2), category: .transport, total: 36, share: 18),
                PPShare(ticket: "Dinner at Casa Pepe", date: daysAgo(12), category: .dining, total: 120, share: 30,
                        repayments: [paid(20, 3)]),
            ]),
            PPPerson(id: "ana", name: "Ana", shares: [
                PPShare(ticket: "Pizzeria", date: daysAgo(5), category: .dining, total: 40, share: 21,
                        repayments: [paid(10, 2)]),
                PPShare(ticket: "Dinner at Casa Pepe", date: daysAgo(12), category: .dining, total: 120, share: 30,
                        repayments: [paid(30, 10)]),
            ]),
            PPPerson(id: "pablo", name: "Pablo", shares: [
                PPShare(ticket: "Weekly shop", date: daysAgo(20), category: .groceries,
                        total: Decimal(string: "54.30") ?? 0, share: Decimal(string: "27.15") ?? 0,
                        repayments: [paid(Decimal(string: "27.15") ?? 0, 18)]),
            ]),
            PPPerson(id: "lucia", name: "Lucía"),
            PPPerson(id: "jorge", name: "Jorge", isArchived: true, shares: [
                PPShare(ticket: "Weekend in Valencia", date: daysAgo(160), category: .leisure, total: 240, share: 120,
                        repayments: [paid(60, 150), paid(60, 130)]),
            ]),
        ])
    }

    /// Everyone has paid back, so nothing is owed.
    static var settledUp: PPStore {
        let store = sample
        for person in store.owing { store.settleAll(person.id, on: daysAgo(1)) }
        return store
    }

    /// No people yet (PPL-001's first run).
    static var empty: PPStore { PPStore(people: []) }
}
#endif
