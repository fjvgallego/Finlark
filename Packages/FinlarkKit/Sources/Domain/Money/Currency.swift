public struct Currency {
    public let code: String
    public let minorUnitDigits: Int

    public init?(code: String) {
        guard let digits = Self.iso4217MinorUnitDigits[code] else {
            return nil
        }
        self.code = code
        self.minorUnitDigits = digits
    }

    // ONB-001, ADR-0014: a withdrawn currency stays readable, but the user can't pick it.
    public static let selectable: [Currency] = selectable(excluding: iso4217WithdrawnCodes)

    static func selectable(excluding withdrawnCodes: Set<String>) -> [Currency] {
        iso4217MinorUnitDigits.keys.filter { !withdrawnCodes.contains($0) }.sorted().compactMap { Currency(code: $0) }
    }
}

extension Currency: Hashable, Sendable {}
