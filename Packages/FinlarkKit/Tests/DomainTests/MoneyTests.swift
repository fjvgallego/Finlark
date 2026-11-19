import Foundation
import Testing

@testable import Domain

struct MoneyTests {
    // MARK: - Creating

    @Test func notANumberIsNotMoney() throws {
        #expect(Money(.nan, currency: try currency("EUR")) == nil)
    }

    @Test func zeroIsZeroInItsCurrency() throws {
        let eur = try currency("EUR")
        #expect(Money.zero(in: eur) == (try money("0", "EUR")))
    }

    // MARK: - Minor units

    @Test(
        "ADR-0005: stored minor units round-trip through Decimal",
        arguments: [
            (Int64(1234), "EUR", "12.34"),
            (1234, "JPY", "1234"),
            (1234, "KWD", "1.234"),
            (-50, "EUR", "-0.5"),
            (0, "EUR", "0"),
        ]
    )
    func minorUnitsRoundTrip(minorUnits: Int64, code: String, amount: String) throws {
        let money = Money(minorUnits: minorUnits, currency: try currency(code))
        #expect(money.amount == (try decimal(amount)))
        #expect(try money.minorUnits() == minorUnits)
    }

    @Test("ADR-0005: a negative amount, such as a starting balance (ONB-002), converts to negative minor units")
    func negativeAmountConvertsToNegativeMinorUnits() throws {
        #expect(try money("-250.75", "EUR").minorUnits() == -25_075)
    }

    @Test("ADR-0005: trailing zeros don't count as decimal places")
    func trailingZerosDontCountAsDecimalPlaces() throws {
        #expect(try money("12.340", "EUR").minorUnits() == 1234)
    }

    @Test(
        "ADR-0005: more decimal places than the currency allows is rejected",
        arguments: [("1.234", "EUR"), ("1.5", "JPY"), ("0.0001", "KWD")]
    )
    func tooManyDecimalPlacesIsRejected(amount: String, code: String) throws {
        let money = try money(amount, code)
        #expect(throws: MoneyError.tooManyDecimalPlaces) { try money.minorUnits() }
    }

    @Test("ADR-0005: the Int64 limits round-trip", arguments: [Int64.max, Int64.min])
    func int64LimitsRoundTrip(minorUnits: Int64) throws {
        let money = Money(minorUnits: minorUnits, currency: try currency("JPY"))
        #expect(try money.minorUnits() == minorUnits)
    }

    @Test(
        "ADR-0005: amounts beyond Int64 are out of range",
        arguments: [
            (Decimal(Int64.max) + 1, "JPY"), (Decimal(Int64.min) - 1, "JPY"), (Decimal.greatestFiniteMagnitude, "EUR"),
        ]
    )
    func amountBeyondInt64IsOutOfRange(amount: Decimal, code: String) throws {
        let money = try #require(Money(amount, currency: try currency(code)))
        #expect(throws: MoneyError.outOfRange) { try money.minorUnits() }
    }

    // MARK: - Arithmetic

    @Test func addingSumsTheAmounts() throws {
        #expect(try money("10.50", "EUR").adding(money("0.75", "EUR")) == (try money("11.25", "EUR")))
    }

    @Test func subtractingTakesAwayTheAmount() throws {
        #expect(try money("10.50", "EUR").subtracting(money("0.75", "EUR")) == (try money("9.75", "EUR")))
    }

    @Test(arguments: [("10.50", "-10.50"), ("-3", "3"), ("0", "0")])
    func negatedFlipsTheSign(amount: String, expected: String) throws {
        #expect(try money(amount, "EUR").negated() == (try money(expected, "EUR")))
    }

    @Test func addingBeyondDecimalIsOutOfRange() throws {
        let largest = try #require(Money(.greatestFiniteMagnitude, currency: try currency("EUR")))
        #expect(throws: MoneyError.outOfRange) { try largest.adding(largest) }
    }

    @Test func subtractingBeyondDecimalIsOutOfRange() throws {
        let largest = try #require(Money(.greatestFiniteMagnitude, currency: try currency("EUR")))
        #expect(throws: MoneyError.outOfRange) { try largest.negated().subtracting(largest) }
    }

    @Test func sumBeyondDecimalIsOutOfRange() throws {
        let eur = try currency("EUR")
        let largest = try #require(Money(.greatestFiniteMagnitude, currency: eur))
        #expect(throws: MoneyError.outOfRange) { try Money.sum([largest, largest], in: eur) }
    }

    @Test func addingAnotherCurrencyIsAMismatch() throws {
        #expect(throws: MoneyError.currencyMismatch) { try money("10", "EUR").adding(money("10", "USD")) }
    }

    @Test func subtractingAnotherCurrencyIsAMismatch() throws {
        #expect(throws: MoneyError.currencyMismatch) { try money("10", "EUR").subtracting(money("10", "USD")) }
    }

    @Test func orderingAcrossCurrenciesIsAMismatch() throws {
        #expect(throws: MoneyError.currencyMismatch) { try money("10", "EUR").isLess(than: money("10", "USD")) }
    }

    @Test func sumOfMixedCurrenciesIsAMismatch() throws {
        let amounts = [try money("10", "EUR"), try money("10", "USD")]
        #expect(throws: MoneyError.currencyMismatch) { try Money.sum(amounts, in: try currency("EUR")) }
    }

    @Test func sameAmountInAnotherCurrencyIsNotEqual() throws {
        #expect(try money("10", "EUR") != money("10", "USD"))
    }

    @Test func sumAddsEveryAmount() throws {
        let amounts = try ["0.10", "0.20", "0.30"].map { try money($0, "EUR") }
        #expect(try Money.sum(amounts, in: try currency("EUR")) == (try money("0.60", "EUR")))
    }

    @Test func sumOfNothingIsZeroInTheCurrency() throws {
        let eur = try currency("EUR")
        #expect(try Money.sum([Money](), in: eur) == .zero(in: eur))
    }

    @Test func sumInAnotherCurrencyIsAMismatch() throws {
        let amounts = [try money("10", "EUR")]
        #expect(throws: MoneyError.currencyMismatch) { try Money.sum(amounts, in: try currency("USD")) }
    }

    @Test(arguments: [("-5", "3", true), ("3", "-5", false), ("3", "3", false)])
    func isLessComparesAmounts(amount: String, other: String, isLess: Bool) throws {
        #expect(try money(amount, "EUR").isLess(than: money(other, "EUR")) == isLess)
    }

    @Test func equalAmountsWrittenDifferentlyAreEqual() throws {
        #expect(try money("12.3", "EUR") == money("12.30", "EUR"))
    }

    @Test(arguments: [("-0.01", true), ("0", false), ("0.01", false)])
    func isNegativeOnlyBelowZero(amount: String, isNegative: Bool) throws {
        #expect(try money(amount, "EUR").isNegative == isNegative)
    }

    @Test(arguments: [("0", true), ("0.00", true), ("0.01", false), ("-0.01", false)])
    func isZeroOnlyForZero(amount: String, isZero: Bool) throws {
        #expect(try money(amount, "EUR").isZero == isZero)
    }

    // MARK: - Rounding

    @Test(
        "ADR-0012: rounding to the nearest minor unit takes halves away from zero",
        arguments: [
            ("10.555", "EUR", "10.56"),
            ("-10.555", "EUR", "-10.56"),
            ("10.554", "EUR", "10.55"),
            ("1.2345", "KWD", "1.235"),
            ("2.5", "JPY", "3"),
        ]
    )
    func roundsToNearestWithHalvesAwayFromZero(amount: String, code: String, expected: String) throws {
        let rounded = try money(amount, code).rounded(.toNearestOrAwayFromZero)
        #expect(rounded.amount == (try decimal(expected)))
    }

    @Test(
        "SPL-002: rounding toward zero drops what's past the minor unit",
        arguments: [
            ("33.3333", "EUR", "33.33"),
            ("66.6666", "EUR", "66.66"),
            ("33.339", "EUR", "33.33"),
            ("-1.239", "EUR", "-1.23"),
            ("12.34", "EUR", "12.34"),
        ]
    )
    func roundsTowardZero(amount: String, code: String, expected: String) throws {
        #expect(try money(amount, code).rounded(.towardZero).amount == (try decimal(expected)))
    }

    @Test(
        "ADR-0012: a changed home currency rounds to its minor unit, halves away from zero",
        arguments: [("10.55", "11"), ("10.00", "10"), ("12.34", "12")]
    )
    func changedCurrencyRoundsHalvesAwayFromZero(euros: String, yen: String) throws {
        let rewritten = try money(euros, "JPY").rounded(.toNearestOrAwayFromZero)
        #expect(try rewritten.minorUnits() == Int64(yen))
    }

    // MARK: - Helpers

    private func money(_ amount: String, _ code: String) throws -> Money {
        try #require(Money(try decimal(amount), currency: try currency(code)))
    }

    private func currency(_ code: String) throws -> Currency {
        try #require(Currency(code: code))
    }

    private func decimal(_ text: String) throws -> Decimal {
        try #require(Decimal(string: text))
    }
}
