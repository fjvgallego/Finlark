//
//  05-ChinookPlan.swift
//  Finlark
//
//  FIN-9 Plan, Round 1 "Chinook": the plan as a ledger. One glass tile holds a table with a row per
//  category and columns for Spent, Projected and Planned, unplanned spending as its own row and the
//  totals at the bottom (PLN-002). Dense and exact, for people who like numbers. At accessibility
//  sizes each row becomes a short stack.
//

#if DEBUG
import SwiftUI

struct ChinookPlan: View {
    @Bindable var store: PLStore

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var code: String { store.code }

    var body: some View {
        let report = store.report

        ScrollView {
            VStack(alignment: .leading, spacing: r2TileSpacing) {
                if report.hasPlan {
                    R2Tile(padding: 18) {
                        VStack(alignment: .leading, spacing: 8) {
                            PLPaceSentence(report: report, code: code)
                                .font(.title3.weight(.semibold))
                            if let status = report.status {
                                PLStatusLabel(status: status)
                                    .font(.subheadline.weight(.semibold))
                            }
                        }
                        .monospacedDigit()
                        .accessibilityElement(children: .combine)
                    }
                    R2Tile(padding: 16) {
                        if dynamicTypeSize.isAccessibilitySize {
                            stacked(report)
                        } else {
                            VStack(alignment: .leading, spacing: 12) {
                                table(report)
                                Text("Amounts in \(currencyName)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    PLFootnote(report: report, code: code)
                        .padding(.horizontal, 4)
                } else {
                    PLInvite(store: store)
                    PLUnplannedTile(report: report, code: code)
                }
            }
            .padding()
        }
        .background { R2Backdrop() }
        .plChrome(store: store)
    }

    // MARK: Table

    private func table(_ report: PLReport) -> some View {
        Grid(alignment: .trailing, horizontalSpacing: 10, verticalSpacing: 12) {
            GridRow {
                Text("Category")
                    .gridColumnAlignment(.leading)
                Text("Spent")
                if report.isCurrent {
                    Text("Projected")
                }
                Text("Planned")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .accessibilityHidden(true)

            Divider()

            ForEach(report.entries) { entry in
                GridRow {
                    HStack(spacing: 6) {
                        if let status = entry.status {
                            PLStatusBadge(status: status)
                                .font(.caption)
                        }
                        Text(entry.category.name)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    amount(entry.spent, emphasized: entry.status == .over)
                    if let projected = entry.projected {
                        amount(projected, emphasized: entry.status == .atRisk)
                    }
                    amount(entry.planned ?? 0)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
            }

            if !report.unplanned.isEmpty {
                GridRow {
                    Text("Unplanned")
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    amount(report.unplannedSpent)
                    if report.isCurrent {
                        amount(report.unplannedProjected)
                    }
                    Text(verbatim: "—")
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                }
                .accessibilityElement(children: .combine)
            }

            Divider()

            GridRow {
                Text("Total")
                amount(report.spent)
                if let projected = report.projected {
                    amount(projected)
                }
                amount(report.planned)
            }
            .font(.headline)
            .accessibilityElement(children: .combine)
        }
        .font(.subheadline)
        .monospacedDigit()
    }

    /// The table drops the symbol from every cell to fit, and names the currency once instead.
    private var currencyName: String {
        Locale.current.localizedString(forCurrencyCode: code) ?? code
    }

    private func amount(_ value: Decimal, emphasized: Bool = false) -> some View {
        Text(value, format: .number.precision(.fractionLength(AEMoney.fractionDigits(for: code))))
            .fontWeight(emphasized ? .semibold : nil)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }

    // MARK: Accessibility sizes

    private func stacked(_ report: PLReport) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(report.entries) { entry in
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.category.name)
                        .font(.headline)
                    if let status = entry.status {
                        PLStatusLabel(status: status)
                    }
                    Text("Spent \(entry.spent, format: .currency(code: code))")
                    if let projected = entry.projected {
                        Text("Projected \(projected, format: .currency(code: code))")
                    }
                    Text("Planned \(entry.planned ?? 0, format: .currency(code: code))")
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                Divider()
            }
            if !report.unplanned.isEmpty {
                Text("Unplanned \(report.unplannedSpent, format: .currency(code: code))")
                Divider()
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Total")
                    .font(.headline)
                PLFigures(report: report, code: code)
            }
        }
    }
}

#Preview("Chinook") {
    PLHost { ChinookPlan(store: $0) }
}

#Preview("Chinook · Last month") {
    PLHost(store: .lastMonth) { ChinookPlan(store: $0) }
}

#Preview("Chinook · No plan") {
    PLHost(store: .noPlan) { ChinookPlan(store: $0) }
}
#endif
