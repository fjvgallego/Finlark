// Regenerates Domain's ISO 4217 minor-unit table (ADR-0005) from SIX's List One, which ISO amends a few times a year.
// The table is append-only (ADR-0014), so this also reads the current one: codes List One drops stay as withdrawn,
// and a changed minor unit fails.
// Download list-one.xml from
// https://www.six-group.com/dam/download/financial-information/data-center/iso-currrency/lists/list-one.xml
// Usage: swift scripts/generate-currency-table.swift path/to/list-one.xml
import Foundation

struct ListOneEntry {
    let code: String
    let minorUnits: String
    let isFund: Bool
}

struct ListOneCurrency: Hashable {
    let code: String
    let digits: Int
    let isFund: Bool
}

// XMLParser reports elements through delegate callbacks, so the state lives here.
final class ListOneParser: NSObject, XMLParserDelegate {
    private(set) var publishedDate = ""
    private(set) var entries: [ListOneEntry] = []
    private var code = ""
    private var minorUnits = ""
    private var isFund = false
    private var text = ""

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?,
        attributes: [String: String] = [:]
    ) {
        text = ""
        switch elementName {
        case "ISO_4217":
            publishedDate = attributes["Pblshd"] ?? ""
        case "CcyNtry":
            code = ""
            minorUnits = ""
            isFund = false
        case "CcyNm":
            isFund = attributes["IsFund"] == "true"
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        text += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName: String?) {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        switch elementName {
        case "Ccy":
            code = value
        case "CcyMnrUnts":
            minorUnits = value
        case "CcyNtry" where !code.isEmpty:
            entries.append(ListOneEntry(code: code, minorUnits: minorUnits, isFund: isFund))
        default:
            break
        }
    }
}

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(1)
}

func wrapped(_ items: [String], indent: String, width: Int) -> [String] {
    items.reduce([String]()) { lines, item in
        guard let last = lines.last, last.count + 1 + item.count <= width else {
            return lines + [indent + item]
        }
        return lines.dropLast() + [last + " " + item]
    }
}

guard CommandLine.arguments.count == 2 else {
    fail("Usage: swift scripts/generate-currency-table.swift path/to/list-one.xml")
}
guard let xmlParser = XMLParser(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1])) else {
    fail("Can't open \(CommandLine.arguments[1])")
}
let listOne = ListOneParser()
xmlParser.delegate = listOne
guard xmlParser.parse(), !listOne.entries.isEmpty else {
    fail("Can't read ISO 4217 List One: \(xmlParser.parserError?.localizedDescription ?? "no currencies found")")
}
guard !listOne.publishedDate.isEmpty else {
    fail("List One has no publication date (Pblshd)")
}

// A code listed both with and without a minor unit would otherwise keep only the numeric entry.
let codesWithMinorUnit = Set(listOne.entries.filter { Int($0.minorUnits) != nil }.map(\.code))
let codesWithoutMinorUnit = Set(listOne.entries.filter { Int($0.minorUnits) == nil }.map(\.code))
let partlyNumericCodes = codesWithMinorUnit.intersection(codesWithoutMinorUnit).sorted()
guard partlyNumericCodes.isEmpty else {
    fail("Codes listed both with and without a minor unit: \(partlyNumericCodes.joined(separator: ", "))")
}
// "N.A." isn't a number, so codes without a minor unit drop out here.
let currencies = listOne.entries.compactMap { entry -> ListOneCurrency? in
    guard let digits = Int(entry.minorUnits) else {
        return nil
    }
    return ListOneCurrency(code: entry.code, digits: digits, isFund: entry.isFund)
}
// Many countries share a currency, so a code appears once per country.
let currencyByCode = Dictionary(grouping: currencies, by: \.code).mapValues(Set.init)
let conflictingCodes = currencyByCode.filter { $0.value.count > 1 }.keys.sorted()
guard conflictingCodes.isEmpty else {
    fail("Codes listed with different minor units or fund flags: \(conflictingCodes.joined(separator: ", "))")
}
let listedDigits = Dictionary(
    uniqueKeysWithValues: currencyByCode.values.compactMap(\.first).filter { !$0.isFund }.map { ($0.code, $0.digits) }
)

let output = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .appendingPathComponent("../Packages/FinlarkKit/Sources/Domain/Money/Currency+ISO4217.swift")
    .standardizedFileURL
guard let currentSource = try? String(contentsOf: output, encoding: .utf8) else {
    fail("Can't read the current table at \(output.path)")
}
guard let digitsBody = currentSource.firstMatch(of: #/iso4217MinorUnitDigits: \[String: Int\] = \[(?<body>[^\]]*)\]/#)?.body,
    let withdrawnBody = currentSource.firstMatch(of: #/iso4217WithdrawnCodes: Set<String> = \[(?<body>[^\]]*)\]/#)?.body
else {
    fail("Can't find iso4217MinorUnitDigits and iso4217WithdrawnCodes in \(output.path)")
}
let currentEntries = digitsBody.matches(of: #/"(?<code>[A-Z]{3})": (?<digits>\d+)/#).compactMap {
    match -> (code: String, digits: Int)? in
    guard let digits = Int(match.digits) else {
        return nil
    }
    return (String(match.code), digits)
}
// Each entry has one colon, so a count that differs means an entry the pattern missed, which would drop it silently.
guard !currentEntries.isEmpty, currentEntries.count == digitsBody.filter({ $0 == ":" }).count else {
    fail("Can't read every entry of the current table at \(output.path)")
}
guard Set(currentEntries.map(\.code)).count == currentEntries.count else {
    fail("The current table at \(output.path) lists a code twice")
}
let currentDigits = Dictionary(uniqueKeysWithValues: currentEntries.map { ($0.code, $0.digits) })
let previouslyWithdrawnCodes = Set(withdrawnBody.matches(of: #/"(?<code>[A-Z]{3})"/#).map { String($0.code) })
let changedCodes = listedDigits.filter { code, digits in currentDigits[code, default: digits] != digits }.keys.sorted()
guard changedCodes.isEmpty else {
    fail("ADR-0014: minor units never change, but List One changes them for \(changedCodes.joined(separator: ", "))")
}

let digits = currentDigits.merging(listedDigits) { current, _ in current }
let addedCodes = Set(listedDigits.keys).subtracting(currentDigits.keys).sorted()
let withdrawnCodes = Set(currentDigits.keys).subtracting(listedDigits.keys).sorted()
let newlyWithdrawnCodes = withdrawnCodes.filter { !previouslyWithdrawnCodes.contains($0) }
let relistedCodes = previouslyWithdrawnCodes.intersection(listedDigits.keys).sorted()
let digitItems = digits.sorted { $0.key < $1.key }.map { "\"\($0.key)\": \($0.value)," }
let withdrawnLiteral =
    withdrawnCodes.isEmpty
    ? "[]"
    : (["["] + wrapped(withdrawnCodes.map { "\"\($0)\"," }, indent: "        ", width: 120) + ["    ]"])
        .joined(separator: "\n")

let source = """
    extension Currency {
        // Generated by scripts/generate-currency-table.swift from ISO 4217 List One, published \(listOne.publishedDate).
        // Don't edit by hand. Fund codes and codes without a minor unit ("N.A.") are left out.
        // ADR-0014: codes are never removed and their minor units never change.
        static let iso4217MinorUnitDigits: [String: Int] = [
    \(wrapped(digitItems, indent: "        ", width: 120).joined(separator: "\n"))
        ]

        static let iso4217WithdrawnCodes: Set<String> = \(withdrawnLiteral)
    }

    """

do {
    try source.write(to: output, atomically: true, encoding: .utf8)
} catch {
    fail("Can't write \(output.path): \(error.localizedDescription)")
}
func listed(_ codes: [String]) -> String {
    codes.isEmpty ? "none" : codes.joined(separator: ", ")
}
let summary = [
    "Wrote \(digits.count) currencies to \(output.path)",
    "Added: \(listed(addedCodes))",
    "Newly withdrawn: \(listed(newlyWithdrawnCodes))",
    "Listed again: \(listed(relistedCodes))",
    "Withdrawn in all: \(listed(withdrawnCodes))",
]
FileHandle.standardOutput.write(Data((summary.joined(separator: "\n") + "\n").utf8))
