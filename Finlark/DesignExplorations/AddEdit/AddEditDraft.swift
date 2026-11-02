//
//  AddEditDraft.swift
//  Finlark
//
//  FIN-9 Add & edit: the mock draft behind every add and edit transaction exploration (TRX-001–003,
//  SPL-001–004, SPL-010). The split math follows the requirements so every variant shows real numbers:
//  equal shares round down to the currency's minor unit and the remainder goes to the user (A-03), and
//  By item divides each item among its assignees (SPL-004). Throwaway design code, Debug only.
//

#if DEBUG
import SwiftUI

// MARK: - Categories (Appendix A)

extension ExplorationCategory {
    // Icons and colors are proposals (Appendix A leaves them to UI design).
    static let bills = ExplorationCategory(id: "bills", name: "Bills & Utilities", symbol: "bolt.fill", color: .teal)
    static let shopping = ExplorationCategory(id: "shopping", name: "Shopping", symbol: "bag.fill", color: .mint)
    static let travel = ExplorationCategory(id: "travel", name: "Travel", symbol: "airplane", color: .cyan)
    static let otherExpense = ExplorationCategory(
        id: "other", name: "Other", symbol: "square.grid.2x2.fill", color: .gray
    )
    static let refunds = ExplorationCategory(
        id: "refunds", name: "Refunds", symbol: "arrow.uturn.backward", color: .blue
    )
    static let gifts = ExplorationCategory(id: "gifts", name: "Gifts", symbol: "gift.fill", color: .pink)
    static let otherIncome = ExplorationCategory(
        id: "other-income", name: "Other income", symbol: "plus.square.fill", color: .gray
    )

    static let expenseCategories: [ExplorationCategory] = [
        .groceries, .dining, .transport, .fuel, .housing, .bills,
        .health, .shopping, .leisure, .subscriptions, .travel, .otherExpense,
    ]
    static let incomeCategories: [ExplorationCategory] = [.salary, .refunds, .gifts, .otherIncome]
    static let all = expenseCategories + incomeCategories
}

extension ExplorationTransactionType {
    var categories: [ExplorationCategory] {
        switch self {
        case .expense: ExplorationCategory.expenseCategories
        case .income: ExplorationCategory.incomeCategories
        }
    }

    /// The categories used most often first, for quick picks. Mocked order.
    var frequentCategories: [ExplorationCategory] {
        switch self {
        case .expense:
            [.groceries, .dining, .fuel, .transport, .leisure, .subscriptions, .shopping, .health,
             .housing, .bills, .travel, .otherExpense]
        case .income:
            ExplorationCategory.incomeCategories
        }
    }

    var editTitle: LocalizedStringResource {
        switch self {
        case .expense: "Edit expense"
        case .income: "Edit income"
        }
    }

    var symbol: String {
        switch self {
        case .expense: "arrow.up.right"
        case .income: "arrow.down.left"
        }
    }
}

// MARK: - People

/// The user or a friend they split with (PPL-001). The user is always a participant (SPL-001).
struct AEPerson: Identifiable, Hashable {
    let id: String
    let name: String

    static let me = AEPerson(id: "me", name: "")
    static let marta = AEPerson(id: "marta", name: "Marta")
    static let luis = AEPerson(id: "luis", name: "Luis")
    static let ana = AEPerson(id: "ana", name: "Ana")
    static let pablo = AEPerson(id: "pablo", name: "Pablo")
    static let known: [AEPerson] = [marta, luis, ana, pablo]

    var isMe: Bool { id == Self.me.id }
    var initial: String { String(name.prefix(1)) }

    var displayName: Text {
        isMe ? Text("You") : Text(verbatim: name)
    }

    /// A stable color per person, the same palette as Home's owed bar.
    var color: Color {
        guard !isMe else { return .accentColor }
        let palette: [Color] = [.orange, .pink, .teal, .purple, .indigo, .mint, .cyan]
        let seed = name.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return palette[seed % palette.count]
    }
}

// MARK: - Split

enum AESplitMode: CaseIterable, Identifiable {
    case equal
    case exact
    case byItem

    var id: Self { self }

    var title: LocalizedStringKey {
        switch self {
        case .equal: "Equal"
        case .exact: "Exact amounts"
        case .byItem: "By item"
        }
    }

    var symbol: String {
        switch self {
        case .equal: "equal"
        case .exact: "number"
        case .byItem: "list.bullet.rectangle"
        }
    }

    var explanation: LocalizedStringKey {
        switch self {
        case .equal: "Everyone pays the same. Any leftover cent goes to you."
        case .exact: "Type what each person pays. The shares must add up to the total."
        case .byItem: "Add the lines of the ticket and say who had each one."
        }
    }
}

/// A line of a ticket in By item mode (SPL-004). No assignees means it counts as the user's.
struct AESplitItem: Identifiable {
    let id = UUID()
    var name = ""
    var amountText = ""
    var assignees: Set<AEPerson.ID> = []
}

struct AEShare: Identifiable {
    let person: AEPerson
    let amount: Decimal
    /// Already repaid on this split, when editing (SPL-010).
    let repaid: Decimal

    var id: AEPerson.ID { person.id }
}

struct AEIssue: Identifiable {
    let id: String
    let message: Text
}

// MARK: - Money text

/// Amounts are typed as text and parsed to `Decimal`, so they never pass through floating point (NFR-005).
enum AEMoney {
    static var locale: Locale { .autoupdatingCurrent }
    static var separator: String { locale.decimalSeparator ?? "." }

    static func fractionDigits(for code: String) -> Int {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        return formatter.maximumFractionDigits
    }

    /// The currency symbol and whether the locale writes it before the number (€12 vs 12 €).
    static func affix(for code: String) -> (symbol: String, isLeading: Bool) {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        let format = formatter.positiveFormat ?? "¤#"
        return (formatter.currencySymbol ?? code, format.hasPrefix("¤"))
    }

    static func parse(_ text: String) -> Decimal? {
        guard !text.isEmpty else { return nil }
        let normalized = text.replacingOccurrences(of: separator, with: ".")
        return Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX"))
    }

    static func text(for value: Decimal, fractionDigits: Int) -> String {
        guard value != 0 else { return "" }
        return value.formatted(
            .number.precision(.fractionLength(0...fractionDigits)).grouping(.never).locale(locale)
        )
    }

    /// Keeps digits and one decimal separator (either "." or "," is accepted), limits the fraction to the
    /// currency's minor unit and the whole part to 9 digits, and drops leading zeros.
    static func sanitize(_ text: String, fractionDigits: Int) -> String {
        var result = ""
        var hasSeparator = false
        var wholeDigits = 0
        var fraction = 0
        for character in text {
            if character.isASCII, character.isWholeNumber {
                if hasSeparator {
                    guard fraction < fractionDigits else { continue }
                    fraction += 1
                } else {
                    if result == "0" {
                        result = ""
                        wholeDigits = 0
                    }
                    guard wholeDigits < 9 else { continue }
                    wholeDigits += 1
                }
                result.append(character)
            } else if character == "." || character == ",", !hasSeparator, fractionDigits > 0 {
                hasSeparator = true
                if result.isEmpty { result = "0" }
                result += separator
            }
        }
        return result
    }

    static func rounded(_ value: Decimal, fractionDigits: Int, mode: NSDecimalNumber.RoundingMode = .down) -> Decimal {
        var input = value
        var result = Decimal()
        NSDecimalRound(&result, &input, fractionDigits, mode)
        return result
    }
}

// MARK: - Draft

@Observable
final class AEDraft {
    enum Purpose {
        case add
        case edit
    }

    let purpose: Purpose
    let currencyCode: String
    let fractionDigits: Int
    /// What each person has already repaid on this split, when editing (SPL-010).
    let repaid: [AEPerson.ID: Decimal]

    var amountText: String
    var date: Date
    var categoryID: String?
    var note: String
    /// Typed shares in Exact amounts mode, the user's included.
    var exactTexts: [AEPerson.ID: String]
    var items: [AESplitItem]
    private(set) var participants: [AEPerson]
    private(set) var people: [AEPerson]

    private var storedType: ExplorationTransactionType
    private var storedIsSplit: Bool
    private var storedSplitMode: AESplitMode

    init(
        purpose: Purpose,
        type: ExplorationTransactionType,
        amount: Decimal = 0,
        date: Date = .now,
        categoryID: String? = nil,
        note: String = "",
        isSplit: Bool = false,
        splitMode: AESplitMode = .equal,
        participants: [AEPerson] = [],
        items: [AESplitItem] = [],
        repaid: [AEPerson.ID: Decimal] = [:],
        currencyCode: String = "EUR"
    ) {
        let fractionDigits = AEMoney.fractionDigits(for: currencyCode)
        self.purpose = purpose
        self.currencyCode = currencyCode
        self.fractionDigits = fractionDigits
        self.repaid = repaid
        amountText = AEMoney.text(for: amount, fractionDigits: fractionDigits)
        self.date = date
        self.categoryID = categoryID
        self.note = note
        exactTexts = [:]
        self.items = items
        self.participants = participants
        people = AEPerson.known
        storedType = type
        storedIsSplit = isSplit
        storedSplitMode = splitMode
    }

    static func new(_ type: ExplorationTransactionType) -> AEDraft {
        AEDraft(purpose: .add, type: type)
    }

    /// SPL-001's example as an edit: €120 Dining split equally among the user, Marta, Luis and Ana.
    /// Ana already paid her €30 back, so she can't be removed or go below €30 (SPL-010).
    static var editSplitSample: AEDraft {
        AEDraft(
            purpose: .edit, type: .expense, amount: 120, categoryID: ExplorationCategory.dining.id,
            note: "Dinner at Casa Pepe", isSplit: true, participants: [.marta, .luis, .ana],
            repaid: [AEPerson.ana.id: 30]
        )
    }

    /// SPL-004's example: Ana's pizza €12, the user's pasta €10, and wine €18 shared by both.
    static var editByItemSample: AEDraft {
        AEDraft(
            purpose: .edit, type: .expense, categoryID: ExplorationCategory.dining.id, note: "Pizzeria Da Mario",
            isSplit: true, splitMode: .byItem, participants: [.ana],
            items: [
                AESplitItem(name: "Pizza", amountText: "12", assignees: [AEPerson.ana.id]),
                AESplitItem(name: "Pasta", amountText: "10", assignees: [AEPerson.me.id]),
                AESplitItem(name: "Wine", amountText: "18", assignees: [AEPerson.me.id, AEPerson.ana.id]),
            ]
        )
    }

    /// A copy to edit, with what each person has repaid so far (SPL-010). The transaction detail edits
    /// a copy so Cancel leaves the saved transaction as it was.
    func copy(repaid: [AEPerson.ID: Decimal]) -> AEDraft {
        let copy = AEDraft(
            purpose: .edit, type: type, date: date, categoryID: categoryID, note: note, isSplit: isSplit,
            splitMode: splitMode, participants: participants, items: items, repaid: repaid,
            currencyCode: currencyCode
        )
        copy.amountText = amountText
        copy.exactTexts = exactTexts
        copy.people = people
        return copy
    }

    var title: LocalizedStringResource {
        purpose == .add ? type.addTitle : type.editTitle
    }

    // MARK: Type (TRX-003)

    /// Switching type clears a category of the other type, so a new one must be chosen. A split
    /// expense can't become income.
    var type: ExplorationTransactionType {
        get { storedType }
        set {
            guard newValue != storedType, canChangeType else { return }
            storedType = newValue
            if let categoryID, !newValue.categories.contains(where: { $0.id == categoryID }) {
                self.categoryID = nil
            }
        }
    }

    var canChangeType: Bool { !isSplit }

    var category: ExplorationCategory? {
        ExplorationCategory.all.first { $0.id == categoryID }
    }

    // MARK: Amount

    var amount: Decimal? { AEMoney.parse(amountText) }

    /// In By item mode the amount paid is the sum of the items (SPL-004).
    var isAmountFromItems: Bool { isSplit && splitMode == .byItem }

    /// The full amount paid.
    var total: Decimal { isAmountFromItems ? itemsTotal : (amount ?? 0) }

    var itemsTotal: Decimal {
        items.reduce(0) { $0 + (AEMoney.parse($1.amountText) ?? 0) }
    }

    /// What the amount shows: the typed text, or the sum of the items in By item mode.
    var amountDisplayText: String {
        isAmountFromItems ? AEMoney.text(for: itemsTotal, fractionDigits: fractionDigits) : amountText
    }

    // MARK: Split (SPL-001)

    var isSplit: Bool {
        get { storedIsSplit }
        set {
            guard newValue != storedIsSplit, type == .expense else { return }
            if !newValue, storedSplitMode == .byItem {
                amountText = AEMoney.text(for: itemsTotal, fractionDigits: fractionDigits)
            }
            storedIsSplit = newValue
        }
    }

    /// Switching mode carries the numbers over: Exact amounts starts from the current shares, and
    /// By item starts with one line for the whole amount, shared by everyone.
    var splitMode: AESplitMode {
        get { storedSplitMode }
        set {
            guard newValue != storedSplitMode else { return }
            let current = shares
            if storedSplitMode == .byItem {
                amountText = AEMoney.text(for: itemsTotal, fractionDigits: fractionDigits)
            }
            switch newValue {
            case .equal:
                break
            case .exact:
                exactTexts = Dictionary(uniqueKeysWithValues: current.map {
                    ($0.person.id, AEMoney.text(for: $0.amount, fractionDigits: fractionDigits))
                })
            case .byItem:
                if items.isEmpty {
                    items = [AESplitItem(amountText: amountText, assignees: Set(everyone.map(\.id)))]
                }
            }
            storedSplitMode = newValue
        }
    }

    /// The user first, then the friends in the order they were added.
    var everyone: [AEPerson] { [.me] + participants }

    var shares: [AEShare] {
        guard isSplit else { return [AEShare(person: .me, amount: total, repaid: 0)] }
        let amounts: [AEPerson.ID: Decimal]
        switch splitMode {
        case .equal:
            amounts = divideEqually(total, among: everyone.map(\.id))
        case .exact:
            amounts = exactTexts.compactMapValues { AEMoney.parse($0) }
        case .byItem:
            amounts = itemAmounts
        }
        return everyone.map { AEShare(person: $0, amount: amounts[$0.id] ?? 0, repaid: repaid[$0.id] ?? 0) }
    }

    /// The user's share counts as spending in the category (SPL-001).
    var myShare: Decimal { shares.first { $0.person.isMe }?.amount ?? 0 }

    /// What friends still owe on this split.
    var owedToYou: Decimal {
        shares.filter { !$0.person.isMe }.reduce(0) { $0 + max($1.amount - $1.repaid, 0) }
    }

    /// Exact amounts only: positive when part of the total isn't assigned yet, negative when over (SPL-003).
    var unassigned: Decimal {
        total - shares.reduce(0) { $0 + $1.amount }
    }

    private var itemAmounts: [AEPerson.ID: Decimal] {
        let order = everyone.map(\.id)
        var result: [AEPerson.ID: Decimal] = [:]
        for item in items {
            let amount = AEMoney.parse(item.amountText) ?? 0
            let assignees = order.filter { item.assignees.contains($0) }
            if assignees.isEmpty {
                result[AEPerson.me.id, default: 0] += amount
            } else {
                for (id, share) in divideEqually(amount, among: assignees) {
                    result[id, default: 0] += share
                }
            }
        }
        return result
    }

    /// Equal parts rounded down to the minor unit. The remainder goes to the user if they're among
    /// the people, otherwise to the first one (SPL-002, SPL-004, A-03).
    private func divideEqually(_ amount: Decimal, among ids: [AEPerson.ID]) -> [AEPerson.ID: Decimal] {
        guard !ids.isEmpty else { return [:] }
        let each = AEMoney.rounded(amount / Decimal(ids.count), fractionDigits: fractionDigits)
        var result = Dictionary(uniqueKeysWithValues: ids.map { ($0, each) })
        let receiver = ids.contains(AEPerson.me.id) ? AEPerson.me.id : ids[0]
        result[receiver, default: 0] += amount - each * Decimal(ids.count)
        return result
    }

    // MARK: Validation

    var splitIssues: [AEIssue] {
        guard isSplit else { return [] }
        var issues: [AEIssue] = []
        if participants.isEmpty {
            issues.append(AEIssue(id: "people", message: Text("Choose at least one person to split with.")))
        }
        if splitMode == .byItem, items.contains(where: { (AEMoney.parse($0.amountText) ?? 0) <= 0 }) {
            issues.append(AEIssue(id: "items", message: Text("Every item needs an amount.")))
        }
        for share in shares where share.amount < share.repaid {
            issues.append(AEIssue(
                id: "repaid-\(share.id)",
                message: Text("\(share.person.name) has already repaid \(share.repaid, format: .currency(code: currencyCode)), so their share can't be less.")
            ))
        }
        return issues
    }

    var canSave: Bool {
        guard total > 0, categoryID != nil, splitIssues.isEmpty else { return false }
        if isSplit, splitMode == .exact { return unassigned == 0 }
        return true
    }

    // MARK: Participants and items

    func isIncluded(_ person: AEPerson) -> Bool {
        person.isMe || participants.contains { $0.id == person.id }
    }

    /// A participant who has repaid something can't be removed (SPL-010, A-05).
    func canRemove(_ person: AEPerson) -> Bool {
        !person.isMe && (repaid[person.id] ?? 0) == 0
    }

    func toggle(_ person: AEPerson) {
        guard !person.isMe else { return }
        if isIncluded(person) {
            guard canRemove(person) else { return }
            participants.removeAll { $0.id == person.id }
            exactTexts[person.id] = nil
            for index in items.indices {
                items[index].assignees.remove(person.id)
            }
        } else {
            participants.append(person)
        }
    }

    /// People can be created while splitting (PPL-001).
    func addPerson(named name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let person = AEPerson(id: UUID().uuidString, name: trimmed)
        people.append(person)
        participants.append(person)
    }

    func exactText(for person: AEPerson) -> Binding<String> {
        Binding(
            get: { self.exactTexts[person.id] ?? "" },
            set: { self.exactTexts[person.id] = $0 }
        )
    }

    func addItem() {
        items.append(AESplitItem())
    }

    func removeItem(_ id: AESplitItem.ID) {
        items.removeAll { $0.id == id }
    }

    func toggle(_ person: AEPerson, on itemID: AESplitItem.ID) {
        guard let index = items.firstIndex(where: { $0.id == itemID }) else { return }
        if items[index].assignees.contains(person.id) {
            items[index].assignees.remove(person.id)
        } else {
            items[index].assignees.insert(person.id)
        }
    }

    /// One line describing the split, e.g. "Equal · 4 people".
    var splitSummary: Text {
        Text("\(Text(splitMode.title)) · \(everyone.count) people")
    }
}
#endif
