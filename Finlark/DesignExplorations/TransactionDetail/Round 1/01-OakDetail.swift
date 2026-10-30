//
//  01-OakDetail.swift
//  Finlark
//
//  FIN-9 Transaction detail, Round 1 "Oak": Dunlin's tiles, read-only, in the same order. The split
//  tile lists each friend with their status and a thin bar, and a "…" menu per person holds Mark as
//  paid and Record a repayment. Repayments sit under their person; tap one to edit or delete it.
//  Edit turns the tiles into Dunlin's fields in place.
//

#if DEBUG
import SwiftUI

struct OakDetail: View {
    let record: TDRecord

    @State private var editing: AEDraft?
    @State private var action: TDRepaymentAction?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Lines up with the name, past the avatar. Nothing to clear at accessibility sizes.
    private var barInset: CGFloat { dynamicTypeSize.isAccessibilitySize ? 0 : 40 }

    var body: some View {
        TDScreen(record: record, editing: $editing) {
            TDAmountTile(record: record)
            TDDetailsTile(record: record)
            if record.isSplit {
                splitTile
            }
            TDDeleteButton(record: record)
                .padding(.top, 12)
        }
        .sheet(item: $action) { TDRepaymentSheet(record: record, action: $0) }
    }

    private var splitTile: some View {
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
                ForEach(record.debts) { debt in
                    Divider()
                    row(debt)
                }
            }
        }
    }

    private func row(_ debt: TDDebt) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            TDPersonLine(debt: debt, code: record.code) {
                HStack(spacing: 4) {
                    Text(debt.share, format: .currency(code: record.code))
                        .fontWeight(.medium)
                        .monospacedDigit()
                    Menu {
                        if debt.remaining > 0 {
                            Button("Mark as paid", systemImage: "checkmark.circle") {
                                action = .markPaid(debt.person)
                            }
                            Button("Record a repayment", systemImage: "plus.circle") {
                                action = .record(debt.person)
                            }
                        }
                        if !debt.repayments.isEmpty {
                            Section("Repayments") {
                                ForEach(debt.repayments) { repayment in
                                    Button {
                                        action = .edit(repayment)
                                    } label: {
                                        Text("Edit \(repayment.amount, format: .currency(code: record.code)) · \(repayment.date, format: .dateTime.day().month())")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(.rect)
                    }
                    .accessibilityLabel(Text("Repayments for \(debt.person.name)"))
                }
            }

            TDProgressBar(debt: debt)
                .padding(.leading, barInset)

            ForEach(debt.repayments) { repayment in
                Button {
                    action = .edit(repayment)
                } label: {
                    TDRepaymentLine(repayment: repayment, record: record)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .padding(.leading, barInset)
                .accessibilityHint(Text("Edit or delete this repayment"))
            }
        }
    }
}

#Preview("Oak · Split") {
    TDHost { OakDetail(record: $0) }
}

#Preview("Oak · By item") {
    TDHost(opening: 1) { OakDetail(record: $0) }
}

#Preview("Oak · No split") {
    TDHost(opening: 2) { OakDetail(record: $0) }
}
#endif
