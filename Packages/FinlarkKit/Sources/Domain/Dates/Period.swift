// ADR-0003: every monthly calculation goes through Period, so a custom month start (roadmap 1.3) changes only this
// type.
public struct Period {
    public let year: Int
    public let month: Int

    public init?(year: Int, month: Int) {
        guard Gregorian.years.contains(year), Gregorian.months.contains(month) else {
            return nil
        }
        self.year = year
        self.month = month
    }

    public init?(yyyymm: Int) {
        self.init(year: yyyymm / 100, month: yyyymm % 100)
    }

    public init(containing day: Day) {
        self.year = day.year
        self.month = day.month
    }

    public var yyyymm: Int {
        year * 100 + month
    }

    public var firstDay: Day {
        Day(firstDayOf: self)
    }

    public var lastDay: Day {
        Day(lastDayOf: self)
    }

    public var numberOfDays: Int {
        Gregorian.numberOfDays(inMonth: month, year: year)
    }

    public func contains(_ day: Day) -> Bool {
        firstDay <= day && day <= lastDay
    }

    public var next: Period? {
        month == 12 ? Period(year: year + 1, month: 1) : Period(year: year, month: month + 1)
    }

    public var previous: Period? {
        month == 1 ? Period(year: year - 1, month: 12) : Period(year: year, month: month - 1)
    }
}

extension Period: Hashable, Sendable {}

// Here rather than in Day.swift, so that the days a period covers are decided in this file only.
extension Day {
    init(firstDayOf period: Period) {
        self.year = period.year
        self.month = period.month
        self.day = 1
    }

    init(lastDayOf period: Period) {
        self.year = period.year
        self.month = period.month
        self.day = period.numberOfDays
    }
}

extension Period: Comparable {
    public static func < (lhs: Period, rhs: Period) -> Bool {
        lhs.yyyymm < rhs.yyyymm
    }
}
