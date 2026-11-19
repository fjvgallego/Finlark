enum Gregorian {
    // ADR-0013: Foundation's .gregorian calendar is Julian before 15 October 1582, and yyyymmdd ends at 9999.
    static let years = 1583...9999

    static let months = 1...12

    static func isLeapYear(_ year: Int) -> Bool {
        year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
    }

    static func numberOfDays(inMonth month: Int, year: Int) -> Int {
        switch month {
        case 2:
            isLeapYear(year) ? 29 : 28
        case 4, 6, 9, 11:
            30
        default:
            31
        }
    }
}
