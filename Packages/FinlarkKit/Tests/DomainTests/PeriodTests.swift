import Testing

@testable import Domain

struct PeriodTests {
    @Test("ADR-0016: periods round-trip through yyyymm", arguments: [202_611, 202_601, 158_301, 999_912])
    func yyyymmRoundTrip(yyyymm: Int) throws {
        let period = try #require(Period(yyyymm: yyyymm))
        #expect(period.yyyymm == yyyymm)
    }

    @Test("ADR-0013: an invalid stored month isn't a Period", arguments: [202_600, 202_613, 0, -202_611])
    func invalidYyyymmHasNoPeriod(yyyymm: Int) {
        #expect(Period(yyyymm: yyyymm) == nil)
    }

    @Test("ADR-0013: months outside 1583–9999 have no period", arguments: [158_212, 1_000_001])
    func monthOutsideTheValidYearsHasNoPeriod(yyyymm: Int) {
        #expect(Period(yyyymm: yyyymm) == nil)
    }

    @Test(
        "ADR-0013: a period has as many days as its Gregorian month",
        arguments: [(202_602, 28), (202_402, 29), (202_611, 30), (202_612, 31)]
    )
    func periodHasTheMonthsNumberOfDays(yyyymm: Int, numberOfDays: Int) throws {
        #expect(try #require(Period(yyyymm: yyyymm)).numberOfDays == numberOfDays)
    }

    @Test(arguments: [202_602, 202_611])
    func periodStartsOnTheFirst(yyyymm: Int) throws {
        #expect(try #require(Period(yyyymm: yyyymm)).firstDay.yyyymmdd == yyyymm * 100 + 1)
    }

    @Test(
        "ADR-0013: a period ends on its Gregorian month's last day",
        arguments: [(202_602, 28), (202_402, 29), (202_611, 30), (202_612, 31)]
    )
    func periodEndsOnTheMonthsLastDay(yyyymm: Int, lastDay: Int) throws {
        #expect(try #require(Period(yyyymm: yyyymm)).lastDay.yyyymmdd == yyyymm * 100 + lastDay)
    }

    @Test(
        arguments: [
            (20_261_101, true), (20_261_130, true), (20_261_031, false), (20_261_201, false), (20_251_115, false),
        ]
    )
    func containsOnlyItsOwnDays(yyyymmdd: Int, isContained: Bool) throws {
        let period = try #require(Period(yyyymm: 202_611))
        #expect(period.contains(try #require(Day(yyyymmdd: yyyymmdd))) == isContained)
    }

    @Test func periodContainingADayIsItsMonth() throws {
        let day = try #require(Day(yyyymmdd: 20_240_229))
        #expect(Period(containing: day).yyyymm == 202_402)
    }

    @Test(arguments: [(202_611, 202_612), (202_612, 202_701), (202_701, 202_702)])
    func nextCrossesYears(yyyymm: Int, nextYyyymm: Int) throws {
        #expect(try #require(Period(yyyymm: yyyymm)).next == Period(yyyymm: nextYyyymm))
    }

    @Test(arguments: [(202_612, 202_611), (202_701, 202_612), (202_702, 202_701)])
    func previousCrossesYears(yyyymm: Int, previousYyyymm: Int) throws {
        #expect(try #require(Period(yyyymm: yyyymm)).previous == Period(yyyymm: previousYyyymm))
    }

    @Test("ADR-0013: no period after December 9999")
    func noPeriodAfterTheLastValidMonth() throws {
        #expect(try #require(Period(yyyymm: 999_912)).next == nil)
    }

    @Test("ADR-0013: no period before January 1583")
    func noPeriodBeforeTheFirstValidMonth() throws {
        #expect(try #require(Period(yyyymm: 158_301)).previous == nil)
    }

    @Test func periodsAreOrderedByMonth() throws {
        let december = try #require(Period(yyyymm: 202_612))
        let january = try #require(Period(yyyymm: 202_701))
        #expect(december < january)
    }
}
