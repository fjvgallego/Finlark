//
//  02-WillowDetail.swift
//  Finlark
//
//  FIN-9 Transaction detail, Round 1 "Willow": each friend is a bar that expands in place, like
//  Dunlin's More categories and Home's Owed to you. Collapsed, it says their status and what's left;
//  expanded, it shows their repayments and two buttons. Mark as paid records it at once, dated today
//  (tap the repayment to change the date). Edit opens Dunlin as a sheet.
//

#if DEBUG
import SwiftUI

struct WillowDetail: View {
    let record: TDRecord

    @State private var editing: AEDraft?
    @State private var action: TDRepaymentAction?
    @State private var expanded: Set<AEPerson.ID> = []
    @State private var paidCount = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TDScreen(record: record, editing: $editing, editStyle: .sheet) {
            TDAmountTile(record: record)
            TDDetailsTile(record: record)
            if record.isSplit {
                R2Tile {
                    VStack(alignment: .leading, spacing: 14) {
                        R2TileHeader(title: "Split", symbol: "person.2.fill")
                        TDSplitFigures(record: record)
                        if record.saved.splitMode == .byItem {
                            Divider()
                            TDItemsList(draft: record.saved)
                        }
                        Divider()
                        TDMyShareRow(record: record)
                        VStack(spacing: 8) {
                            ForEach(record.debts) { debt in
                                bar(debt)
                            }
                        }
                    }
                }
            }
            TDDeleteButton(record: record)
                .padding(.top, 12)
        }
        .sheet(item: $action) { TDRepaymentSheet(record: record, action: $0) }
        .sensoryFeedback(.success, trigger: paidCount)
    }

    private func bar(_ debt: TDDebt) -> some View {
        let isExpanded = expanded.contains(debt.id)

        return VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(reduceMotion ? nil : .snappy) {
                    if isExpanded { expanded.remove(debt.id) } else { expanded.insert(debt.id) }
                }
            } label: {
                HStack(spacing: 10) {
                    TDPersonLine(debt: debt, code: record.code) {
                        if debt.remaining > 0 {
                            Text("\(debt.remaining, format: .currency(code: record.code)) left")
                                .fontWeight(.semibold)
                                .monospacedDigit()
                        }
                    }
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .accessibilityHidden(true)
                }
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityValue(isExpanded ? Text("Expanded") : Text("Collapsed"))

            if isExpanded {
                Divider()
                    .padding(.horizontal, 12)
                expandedContent(debt)
                    .padding(12)
            }
        }
        .background(.fill.quaternary, in: .rect(cornerRadius: 16, style: .continuous))
    }

    private func expandedContent(_ debt: TDDebt) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            TDDebtFigures(debt: debt, code: record.code, spacing: 16)
            TDProgressBar(debt: debt)

            if debt.repayments.isEmpty {
                Text("No repayments yet.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(debt.repayments) { repayment in
                    Button {
                        action = .edit(repayment)
                    } label: {
                        HStack {
                            TDRepaymentLine(repayment: repayment, record: record)
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                                .accessibilityHidden(true)
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(Text("Edit or delete this repayment"))
                }
            }

            if debt.remaining > 0 {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) { buttons(debt) }
                    VStack(alignment: .leading, spacing: 8) { buttons(debt) }
                }
            }
        }
    }

    @ViewBuilder
    private func buttons(_ debt: TDDebt) -> some View {
        Button {
            withAnimation(reduceMotion ? nil : .snappy) {
                record.markPaid(debt.person)
            }
            paidCount += 1
        } label: {
            Label("Mark as paid", systemImage: "checkmark.circle.fill")
                .fontWeight(.semibold)
        }
        .buttonStyle(.glassProminent)
        .accessibilityHint(Text("Records \(debt.remaining.formatted(.currency(code: record.code))), dated today"))

        Button {
            action = .record(debt.person)
        } label: {
            Label("Record part", systemImage: "plus.circle")
        }
        .buttonStyle(.glass)
    }
}

#Preview("Willow · Split") {
    TDHost { WillowDetail(record: $0) }
}

#Preview("Willow · By item") {
    TDHost(opening: 1) { WillowDetail(record: $0) }
}
#endif
