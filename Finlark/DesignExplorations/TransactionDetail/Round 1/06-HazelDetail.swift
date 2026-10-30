//
//  06-HazelDetail.swift
//  Finlark
//
//  FIN-9 Transaction detail, Round 1 "Hazel": the split as a ledger, one line per person with Share,
//  Paid and Left in columns and a totals line, so the numbers line up like a receipt. Each line pushes
//  that person's page on this split, with their repayments and the actions. At accessibility sizes the
//  columns stack. Edit opens Dunlin as a sheet.
//

#if DEBUG
import SwiftUI

struct HazelDetail: View {
    let record: TDRecord

    @State private var editing: AEDraft?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric private var column: CGFloat = 72

    var body: some View {
        TDScreen(record: record, editing: $editing, editStyle: .sheet) {
            TDAmountTile(record: record)
            TDDetailsTile(record: record)
            if record.isSplit {
                R2Tile {
                    VStack(alignment: .leading, spacing: 12) {
                        R2TileHeader(title: "Split", symbol: "person.2.fill") {
                            Label {
                                record.saved.splitSummary
                            } icon: {
                                Image(systemName: record.saved.splitMode.symbol)
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        if record.saved.splitMode == .byItem {
                            TDItemsList(draft: record.saved)
                            Divider()
                        }
                        ledger
                    }
                }
            }
            TDDeleteButton(record: record)
                .padding(.top, 12)
        }
    }

    @ViewBuilder
    private var ledger: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 12) {
                TDMyShareRow(record: record)
                ForEach(record.debts) { debt in
                    Divider()
                    NavigationLink {
                        HazelPersonScreen(record: record, person: debt.person)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            debt.person.displayName
                                .fontWeight(.semibold)
                            TDStatusLabel(debt: debt, code: record.code)
                            Text("Left \(debt.remaining, format: .currency(code: record.code))")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                }
            }
        } else {
            VStack(spacing: 0) {
                HStack(spacing: 4) {
                    Text("Person")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    columnText("Share")
                    columnText("Paid")
                    columnText("Left")
                    Color.clear.frame(width: 12)
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.bottom, 6)
                .accessibilityHidden(true)

                line(name: Text("You"), symbol: nil, showsIcon: true, share: record.myShare, paid: nil, left: nil)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text("Your share, \(record.myShare.formatted(.currency(code: record.code))). Counts as your spending."))
                ForEach(record.debts) { debt in
                    Divider()
                    NavigationLink {
                        HazelPersonScreen(record: record, person: debt.person)
                    } label: {
                        line(name: debt.person.displayName, symbol: debt.status, showsIcon: true, share: debt.share, paid: debt.paid, left: debt.remaining)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(debt.person.displayName)
                    .accessibilityValue(Text("\(debt.statusText(code: record.code)). Share \(debt.share.formatted(.currency(code: record.code))), left \(debt.remaining.formatted(.currency(code: record.code)))"))
                    .accessibilityAddTraits(.isButton)
                }
                Divider()
                    .overlay(.primary.opacity(0.4))
                line(
                    name: Text("Total"), symbol: nil, showsIcon: false, share: record.saved.total,
                    paid: record.totalRepaid, left: record.owedToYou
                )
                .fontWeight(.semibold)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("Total \(record.saved.total.formatted(.currency(code: record.code))), repaid \(record.totalRepaid.formatted(.currency(code: record.code))), owed to you \(record.owedToYou.formatted(.currency(code: record.code)))"))
            }
            .font(.subheadline)
        }
    }

    private func columnText(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .frame(width: column, alignment: .trailing)
    }

    private func line(
        name: Text, symbol: TDStatus?, showsIcon: Bool, share: Decimal, paid: Decimal?, left: Decimal?
    ) -> some View {
        HStack(spacing: 4) {
            HStack(spacing: 6) {
                if let symbol {
                    Image(systemName: symbol.symbol)
                        .foregroundStyle(symbol.tint)
                } else if showsIcon {
                    Image(systemName: "person.fill")
                        .foregroundStyle(.tint)
                }
                name
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            amount(share)
            amount(paid)
            amount(left)
            Group {
                if symbol != nil {
                    R2Chevron()
                } else {
                    Color.clear
                }
            }
            .frame(width: 12)
        }
        .padding(.vertical, 10)
    }

    private func amount(_ value: Decimal?) -> some View {
        Group {
            if let value {
                Text(value, format: .currency(code: record.code))
            } else {
                Text(verbatim: "–")
                    .foregroundStyle(.tertiary)
            }
        }
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .frame(width: column, alignment: .trailing)
    }
}

/// One person on this split, pushed from the ledger: status, figures, repayments, actions.
private struct HazelPersonScreen: View {
    let record: TDRecord
    let person: AEPerson

    @State private var action: TDRepaymentAction?

    var body: some View {
        Form {
            if let debt = record.debt(for: person) {
                Section {
                    TDStatusLabel(debt: debt, code: record.code)
                        .font(.headline)
                    LabeledContent("Share") { Text(debt.share, format: .currency(code: record.code)) }
                    LabeledContent("Paid") { Text(debt.paid, format: .currency(code: record.code)) }
                    LabeledContent("Left") { Text(debt.remaining, format: .currency(code: record.code)) }
                }
                .monospacedDigit()

                Section("Repayments") {
                    if debt.repayments.isEmpty {
                        Text("No repayments yet.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(debt.repayments) { repayment in
                        Button {
                            action = .edit(repayment)
                        } label: {
                            TDRepaymentLine(repayment: repayment, record: record)
                                .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .swipeActions {
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                record.undo(repayment.id)
                            }
                        }
                    }
                }

                if debt.remaining > 0 {
                    Section {
                        Button("Mark as paid", systemImage: "checkmark.circle.fill") { action = .markPaid(person) }
                        Button("Record a repayment", systemImage: "plus.circle") { action = .record(person) }
                    } footer: {
                        Text("Mark as paid records what's left, \(debt.remaining, format: .currency(code: record.code)).")
                    }
                }
            }
        }
        .navigationTitle(Text(verbatim: person.name))
        .navigationSubtitle(record.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $action) { TDRepaymentSheet(record: record, action: $0) }
    }
}

#Preview("Hazel · Split") {
    TDHost { HazelDetail(record: $0) }
}

#Preview("Hazel · By item") {
    TDHost(opening: 1) { HazelDetail(record: $0) }
}
#endif
