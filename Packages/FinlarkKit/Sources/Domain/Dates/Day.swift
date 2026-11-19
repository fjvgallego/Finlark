import Foundation

// ADR-0013: always Gregorian, whatever the user's calendar.
public struct Day {
    // ADR-0003: internal, so code outside Domain groups days by month through Period.
    let year: Int
    let month: Int
    let day: Int

    public init?(year: Int, month: Int, day: Int) {
        guard Gregorian.years.contains(year), Gregorian.months.contains(month),
            (1...Gregorian.numberOfDays(inMonth: month, year: year)).contains(day)
        else {
            return nil
        }
        self.year = year
        self.month = month
        self.day = day
    }

    public init?(yyyymmdd: Int) {
        self.init(year: yyyymmdd / 10_000, month: yyyymmdd / 100 % 100, day: yyyymmdd % 100)
    }

    public init?(containing date: Date, in timeZone: TimeZone) {
        let components = Calendar(identifier: .gregorian).dateComponents(in: timeZone, from: date)
        // In era 0, before year 1, years count backwards.
        guard components.era == 1, let year = components.year, let month = components.month,
            let day = components.day
        else {
            return nil
        }
        self.init(year: year, month: month, day: day)
    }

    public var yyyymmdd: Int {
        year * 10_000 + month * 100 + day
    }
}

extension Day: Hashable, Sendable {}

extension Day: Comparable {
    public static func < (lhs: Day, rhs: Day) -> Bool {
        lhs.yyyymmdd < rhs.yyyymmdd
    }
}
