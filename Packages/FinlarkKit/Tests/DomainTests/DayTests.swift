import Foundation
import Testing

@testable import Domain

struct DayTests {
    @Test("ADR-0016: days round-trip through yyyymmdd", arguments: [20_261_117, 20_240_229, 15_830_101, 99_991_231])
    func yyyymmddRoundTrip(yyyymmdd: Int) throws {
        let day = try #require(Day(yyyymmdd: yyyymmdd))
        #expect(day.yyyymmdd == yyyymmdd)
    }

    @Test func componentsComeFromYyyymmdd() throws {
        let day = try #require(Day(yyyymmdd: 20_261_117))
        #expect(day.year == 2026)
        #expect(day.month == 11)
        #expect(day.day == 17)
    }

    @Test(
        "ADR-0013: an invalid stored day isn't a Day",
        arguments: [20_260_230, 20_261_301, 20_260_100, 20_260_001, 20_260_431, 0, -20_261_117]
    )
    func invalidYyyymmddHasNoDay(yyyymmdd: Int) {
        #expect(Day(yyyymmdd: yyyymmdd) == nil)
    }

    @Test("ADR-0013: days outside 1583–9999 don't exist", arguments: [15_821_231, 100_001_231])
    func dayOutsideTheValidYearsHasNoDay(yyyymmdd: Int) {
        #expect(Day(yyyymmdd: yyyymmdd) == nil)
    }

    @Test(
        "ADR-0013: February 29 exists only in Gregorian leap years",
        arguments: [(2024, true), (2000, true), (2023, false), (1900, false)]
    )
    func february29ExistsOnlyInLeapYears(year: Int, isLeap: Bool) {
        #expect((Day(year: year, month: 2, day: 29) != nil) == isLeap)
    }

    @Test(
        "ADR-0013: the same instant is a different day in different time zones",
        arguments: [
            ("UTC", 20_261_116),
            ("America/Los_Angeles", 20_261_116),
            ("Europe/Madrid", 20_261_117),
            ("Pacific/Auckland", 20_261_117),
        ]
    )
    func dayDependsOnTheTimeZone(identifier: String, yyyymmdd: Int) throws {
        let instant = try Date("2026-11-16T23:30:00Z", strategy: .iso8601)
        let timeZone = try #require(TimeZone(identifier: identifier))
        #expect(Day(containing: instant, in: timeZone)?.yyyymmdd == yyyymmdd)
    }

    @Test(
        "ADR-0013: days follow Madrid's daylight saving changes",
        arguments: [
            ("2026-03-28T23:30:00Z", 20_260_329),  // 00:30 CET, the night clocks go forward
            ("2026-03-29T21:59:00Z", 20_260_329),  // 23:59 CEST
            ("2026-03-29T22:00:00Z", 20_260_330),  // 00:00 CEST
            ("2026-10-24T22:30:00Z", 20_261_025),  // 00:30 CEST, the night clocks go back
            ("2026-10-25T22:59:00Z", 20_261_025),  // 23:59 CET
            ("2026-10-25T23:00:00Z", 20_261_026),  // 00:00 CET
        ]
    )
    func dayFollowsDaylightSavingChanges(instant: String, yyyymmdd: Int) throws {
        let date = try Date(instant, strategy: .iso8601)
        let madrid = try #require(TimeZone(identifier: "Europe/Madrid"))
        #expect(Day(containing: date, in: madrid)?.yyyymmdd == yyyymmdd)
    }

    @Test("ADR-0013: a date before 1583 has no day")
    func dateBefore1583HasNoDay() throws {
        let date = try Date("1500-06-01T12:00:00Z", strategy: .iso8601)
        let utc = try #require(TimeZone(identifier: "UTC"))
        #expect(Day(containing: date, in: utc) == nil)
    }

    @Test("ADR-0013: a date before year 1 has no day")
    func dateBeforeYearOneHasNoDay() throws {
        let aroundTwoThousandBC = Date(timeIntervalSinceReferenceDate: -126_000_000_000)
        let utc = try #require(TimeZone(identifier: "UTC"))
        #expect(Day(containing: aroundTwoThousandBC, in: utc) == nil)
    }

    @Test func daysAreOrderedByDate() throws {
        let earlier = try #require(Day(yyyymmdd: 20_261_231))
        let later = try #require(Day(yyyymmdd: 20_270_101))
        #expect(earlier < later)
        #expect(!(later < earlier))
    }
}
