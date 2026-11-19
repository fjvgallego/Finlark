import Foundation

public struct Money {
    public let amount: Decimal
    public let currency: Currency

    public init?(_ amount: Decimal, currency: Currency) {
        guard !amount.isNaN else {
            return nil
        }
        self.amount = amount
        self.currency = currency
    }

    public init(minorUnits: Int64, currency: Currency) {
        self.amount = Decimal(minorUnits) / Self.minorUnitsPerUnit(of: currency)
        self.currency = currency
    }

    private init(negating money: Money) {
        self.amount = -money.amount
        self.currency = money.currency
    }

    private init(rounding money: Money, mode: NSDecimalNumber.RoundingMode) {
        self.amount = Self.round(money.amount, toScale: money.currency.minorUnitDigits, mode: mode)
        self.currency = money.currency
    }

    public static func zero(in currency: Currency) -> Money {
        Money(minorUnits: 0, currency: currency)
    }

    public var isZero: Bool {
        amount.isZero
    }

    public var isNegative: Bool {
        amount < .zero
    }

    // MARK: - Minor units

    public func minorUnits() throws(MoneyError) -> Int64 {
        let scaled = amount * Self.minorUnitsPerUnit(of: currency)
        guard !scaled.isNaN else {
            throw .outOfRange
        }
        guard Self.round(scaled, toScale: 0, mode: .plain) == scaled else {
            throw .tooManyDecimalPlaces
        }
        guard scaled >= Decimal(Int64.min), scaled <= Decimal(Int64.max) else {
            throw .outOfRange
        }
        // NSDecimalNumber.int64Value can be wrong for some Decimals. A whole Decimal's description is exact.
        guard let minorUnits = Int64(scaled.description) else {
            throw .outOfRange
        }
        return minorUnits
    }

    // MARK: - Arithmetic

    public func adding(_ other: Money) throws(MoneyError) -> Money {
        try requireSameCurrency(as: other)
        return try Self.result(amount + other.amount, in: currency)
    }

    public func subtracting(_ other: Money) throws(MoneyError) -> Money {
        try requireSameCurrency(as: other)
        return try Self.result(amount - other.amount, in: currency)
    }

    public func negated() -> Money {
        Money(negating: self)
    }

    public static func sum(_ amounts: some Collection<Money>, in currency: Currency) throws(MoneyError) -> Money {
        guard amounts.allSatisfy({ $0.currency == currency }) else {
            throw .currencyMismatch
        }
        return try result(amounts.reduce(Decimal.zero) { $0 + $1.amount }, in: currency)
    }

    // Not Comparable: amounts in different currencies have no order.
    public func isLess(than other: Money) throws(MoneyError) -> Bool {
        try requireSameCurrency(as: other)
        return amount < other.amount
    }

    // MARK: - Rounding

    public enum Rounding {
        case toNearestOrAwayFromZero
        case towardZero
    }

    public func rounded(_ rule: Rounding) -> Money {
        let mode: NSDecimalNumber.RoundingMode =
            switch rule {
            case .toNearestOrAwayFromZero: .plain
            case .towardZero: isNegative ? .up : .down
            }
        return Money(rounding: self, mode: mode)
    }

    // MARK: - Helpers

    private func requireSameCurrency(as other: Money) throws(MoneyError) {
        guard currency == other.currency else {
            throw .currencyMismatch
        }
    }

    // Decimal arithmetic returns NaN when it overflows.
    private static func result(_ amount: Decimal, in currency: Currency) throws(MoneyError) -> Money {
        guard let money = Money(amount, currency: currency) else {
            throw .outOfRange
        }
        return money
    }

    private static func minorUnitsPerUnit(of currency: Currency) -> Decimal {
        pow(10, currency.minorUnitDigits)
    }

    private static func round(_ value: Decimal, toScale scale: Int, mode: NSDecimalNumber.RoundingMode) -> Decimal {
        var value = value
        var result = Decimal()
        NSDecimalRound(&result, &value, scale, mode)
        return result
    }
}

extension Money: Hashable, Sendable {}

extension Money.Rounding: Sendable {}
