import Testing

@testable import Domain

struct CurrencyTests {
    @Test(
        "ADR-0005: minor-unit digits come from ISO 4217",
        arguments: [
            ("JPY", 0), ("CLP", 0), ("ISK", 0), ("EUR", 2), ("USD", 2), ("KWD", 3), ("BHD", 3), ("TND", 3),
        ]
    )
    func knownCodeHasISOMinorUnitDigits(code: String, digits: Int) throws {
        let currency = try #require(Currency(code: code))
        #expect(currency.code == code)
        #expect(currency.minorUnitDigits == digits)
    }

    @Test("ADR-0005: codes outside ISO 4217 aren't currencies", arguments: ["ABC", "", "eur"])
    func codeOutsideISO4217HasNoCurrency(code: String) {
        #expect(Currency(code: code) == nil)
    }

    @Test("ADR-0005: codes without a minor unit aren't currencies", arguments: ["XAU", "XDR", "XXX"])
    func codeWithoutMinorUnitHasNoCurrency(code: String) {
        #expect(Currency(code: code) == nil)
    }

    @Test("ADR-0014: fund codes aren't currencies", arguments: ["CLF", "USN", "BOV", "UYW"])
    func fundCodeHasNoCurrency(code: String) {
        #expect(Currency(code: code) == nil)
    }

    @Test("ADR-0014: every withdrawn code is still in the table")
    func withdrawnCodesStayInTheTable() {
        #expect(Currency.iso4217WithdrawnCodes.isSubset(of: Currency.iso4217MinorUnitDigits.keys))
    }

    @Test("ONB-001: the user can pick a currency that isn't withdrawn", arguments: ["EUR", "JPY", "KWD", "XCG"])
    func currentCurrencyIsSelectable(code: String) throws {
        let currency = try #require(Currency(code: code))
        #expect(Currency.selectable.contains(currency))
    }

    @Test("ONB-001: the picker offers every currency except the withdrawn ones")
    func selectableLeavesOutOnlyWithdrawnCodes() {
        let withdrawn: Set = ["EUR", "JPY"]
        let offered = Set(Currency.selectable(excluding: withdrawn).map(\.code))
        #expect(offered == Set(Currency.iso4217MinorUnitDigits.keys).subtracting(withdrawn))
    }

    @Test func selectableIsInStrictlyIncreasingCodeOrder() {
        let codes = Currency.selectable.map(\.code)
        #expect(zip(codes, codes.dropFirst()).allSatisfy { $0 < $1 })
    }
}
