public enum MoneyError {
    case currencyMismatch
    case tooManyDecimalPlaces
    case outOfRange
}

extension MoneyError: Error, Equatable {}
